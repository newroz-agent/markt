-- Step E2 acceptance: directory owner onboarding. All fixtures roll back.
begin;

create function pg_temp.expect_error(command text, expected_state text)
returns void language plpgsql as $$
begin
  begin execute command;
  exception when others then
    assert sqlstate = expected_state,
      format('Expected SQLSTATE %s, got %s (%s)',expected_state,sqlstate,sqlerrm);
    return;
  end;
  raise exception 'Expected command to fail: %',command;
end; $$;

create function pg_temp.act_as(user_id text, admin boolean default false)
returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub',user_id,'role','authenticated',
    'app_metadata', case when admin then '{"role":"admin"}'::jsonb else '{}'::jsonb end)::text, true);
$$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('e2100000-0000-0000-0000-000000000001','e2-doctor@example.invalid','{"display_name":"E2 Doctor"}'),
 ('e2100000-0000-0000-0000-000000000002','e2-restaurant@example.invalid','{"display_name":"E2 Restaurant"}'),
 ('e2100000-0000-0000-0000-000000000003','e2-private@example.invalid','{"display_name":"E2 Private"}'),
 ('e2100000-0000-0000-0000-000000000004','e2-marketplace@example.invalid','{"display_name":"E2 Marketplace"}'),
 ('e2100000-0000-0000-0000-000000000005','e2-admin@example.invalid','{"display_name":"E2 Admin"}');

insert into auth.users(id,email,raw_user_meta_data) values
 ('e2100000-0000-0000-0000-000000000006','e2-rejected@example.invalid','{"display_name":"E2 Rejected"}'),
 ('e2100000-0000-0000-0000-000000000007','e2-suspended@example.invalid','{"display_name":"E2 Suspended"}');

insert into public.sellers(id,user_id,kind,status,shop_name,slug,city,country_code,rejection_reason) values
 ('e2200000-0000-0000-0000-000000000003','e2100000-0000-0000-0000-000000000003','private','pending','E2 Private','e2-private','Berlin','DE',null),
 ('e2200000-0000-0000-0000-000000000004','e2100000-0000-0000-0000-000000000004','business','pending','E2 Marketplace','e2-marketplace','Berlin','DE',null),
 ('e2200000-0000-0000-0000-000000000006','e2100000-0000-0000-0000-000000000006','business','rejected','E2 Rejected','e2-rejected','Berlin','DE','Fake business'),
 ('e2200000-0000-0000-0000-000000000007','e2100000-0000-0000-0000-000000000007','business','suspended','E2 Suspended','e2-suspended','Berlin','DE',null);

-- Full business document sets waiting for review for the private, rejected and suspended sellers.
insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
select seller_id::uuid,kind,seller_id||'/'||kind||'/set.pdf','application/pdf'
from unnest(array['e2200000-0000-0000-0000-000000000003','e2200000-0000-0000-0000-000000000006',
  'e2200000-0000-0000-0000-000000000007']) seller_id,
  unnest(array['identity','business_registration']::public.seller_document_kind[]) kind;

do $$ begin
  assert public.directory_required_document_kinds('doctor')
    = array['identity','medical_professional_registration']::public.seller_document_kind[];
  assert public.directory_required_document_kinds('fast_food')
    = array['identity','business_registration']::public.seller_document_kind[];
  assert public.directory_required_document_kinds(null)
    = array['identity','business_registration']::public.seller_document_kind[],
    'a marketplace business without directory type proves identity + business registration';
  assert not has_function_privilege('anon','public.get_my_directory_onboarding(uuid)','execute');
  assert not has_function_privilege('anon','public.owner_start_directory(uuid,public.directory_business_type,text,text)','execute');
end $$;

set local role authenticated;

-- A user without a seller starts a doctor entry: pending business seller, doctor documents.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000001');
select pg_temp.expect_error($$select public.owner_start_directory(null::uuid,'doctor','X','Berlin')$$,'22023');
select pg_temp.expect_error($$select public.owner_start_directory(null::uuid,'doctor','Praxis Dr. Test','Atlantis')$$,'22023');
select pg_temp.expect_error($$select public.owner_start_directory(null::uuid,null,'Praxis Dr. Test','Berlin')$$,'22023');
do $$
declare onboarding jsonb := public.owner_start_directory(null::uuid,'doctor',' Praxis Dr. Test ','Berlin');
begin
  assert onboarding->'seller'->>'kind'='business' and onboarding->'seller'->>'status'='pending'
    and onboarding->'seller'->>'directory_type'='doctor' and onboarding->'seller'->>'shop_name'='Praxis Dr. Test',
    format('doctor seller created: %s',onboarding);
  assert onboarding->'required_document_kinds'='["identity","medical_professional_registration"]'::jsonb;
  assert not (onboarding->>'is_verified')::boolean and onboarding->'profile'='null'::jsonb;
  perform set_config('e2.doctor_seller',onboarding->'seller'->>'id',true);
end $$;

-- Document rows must point into the owner's own folder; one pending document per kind.
select pg_temp.expect_error(format(
  $f$insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
     values(%L,'identity','e2200000-0000-0000-0000-000000000004/identity/stolen.pdf','application/pdf')$f$,
  current_setting('e2.doctor_seller')),'42501');
insert into public.seller_documents(seller_id,kind,storage_path,mime_type,status)
values(current_setting('e2.doctor_seller')::uuid,'identity',
  current_setting('e2.doctor_seller')||'/identity/e2-identity.pdf','application/pdf','approved');
insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
values(current_setting('e2.doctor_seller')::uuid,'medical_professional_registration',
  current_setting('e2.doctor_seller')||'/medical_professional_registration/e2-medical-1.jpg','image/jpeg');
select pg_temp.expect_error(format(
  $f$insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
     values(%L,'medical_professional_registration',%L,'image/jpeg')$f$,
  current_setting('e2.doctor_seller'),current_setting('e2.doctor_seller')||'/medical_professional_registration/dup.jpg'),'23505');
do $$
declare onboarding jsonb := public.get_my_directory_onboarding(
  current_setting('e2.doctor_seller')::uuid
);
begin
  assert jsonb_array_length(onboarding->'documents')=2, format('owner sees both documents: %s',onboarding);
  assert not exists(select 1 from jsonb_array_elements(onboarding->'documents') d where d->>'status'<>'pending'),
    'owner-supplied status is ignored; every new document starts pending';
end $$;

-- Admin rejects the medical proof with a note; the owner sees status and note.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000005',true);
select public.moderate_seller_document(
  (select id from public.seller_documents where seller_id=current_setting('e2.doctor_seller')::uuid
    and kind='medical_professional_registration'),'reject','Bitte die Approbationsurkunde vollständig scannen.');
select pg_temp.act_as('e2100000-0000-0000-0000-000000000001');
do $$
declare doc jsonb;
begin
  select d into doc from jsonb_array_elements(public.get_my_directory_onboarding(
    current_setting('e2.doctor_seller')::uuid
  )->'documents') d
  where d->>'kind'='medical_professional_registration';
  assert doc->>'status'='rejected' and doc->>'admin_note'='Bitte die Approbationsurkunde vollständig scannen.',
    format('rejection note reaches the owner: %s',doc);
end $$;

-- Re-upload after rejection, then approve both: the directory seller is approved automatically.
insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
values(current_setting('e2.doctor_seller')::uuid,'medical_professional_registration',
  current_setting('e2.doctor_seller')||'/medical_professional_registration/e2-medical-2.pdf','application/pdf');
select pg_temp.act_as('e2100000-0000-0000-0000-000000000005',true);
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id=current_setting('e2.doctor_seller')::uuid and status='pending';
reset role;
update public.seller_documents set status='pending' where seller_id=current_setting('e2.doctor_seller')::uuid and kind='identity';
set local role authenticated;
select pg_temp.act_as('e2100000-0000-0000-0000-000000000005',true);
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id=current_setting('e2.doctor_seller')::uuid and kind='identity' and status='pending';
select pg_temp.act_as('e2100000-0000-0000-0000-000000000001');
do $$
declare onboarding jsonb := public.get_my_directory_onboarding(
  current_setting('e2.doctor_seller')::uuid
);
begin
  assert onboarding->'seller'->>'status'='approved', format('approved by documents: %s',onboarding);
  assert exists(select 1 from public.seller_status_history history
    where history.seller_id=current_setting('e2.doctor_seller')::uuid
      and history.from_status='pending' and history.to_status='approved'
      and history.actor_user_id='e2100000-0000-0000-0000-000000000005'),
    'the automatic approval is recorded in seller_status_history with the approving admin';
  assert not (onboarding->>'is_verified')::boolean,
    'a doctor is only verified once the doctor profile (draft) exists';
end $$;

-- A doctor draft completes verification; the profile type then owns the directory type.
select public.owner_upsert_directory_profile(
  p_seller_id=>current_setting('e2.doctor_seller')::uuid,
  p_type=>'doctor',p_description=>'Allgemeinmedizinische Praxis mit kurdisch- und arabischsprachigem Team.',
  p_phone=>'030 1234567',p_website=>null,p_cover_image_path=>null,
  p_languages=>array['german','kurdish']::public.directory_spoken_language[],
  p_specialty=>'general_medicine',p_insurance=>'both');
do $$
declare onboarding jsonb := public.get_my_directory_onboarding(
  current_setting('e2.doctor_seller')::uuid
);
begin
  assert (onboarding->>'is_verified')::boolean, format('doctor draft + approved proof verifies: %s',onboarding);
  assert onboarding->'profile'->>'type'='doctor' and not (onboarding->'profile'->>'is_published')::boolean;
end $$;
select pg_temp.expect_error(format(
  $$select public.owner_set_directory_type(%L,'restaurant')$$,
  current_setting('e2.doctor_seller')
),'22023');
select pg_temp.expect_error($$select public.owner_start_directory(null::uuid,'restaurant','Zweites Geschäft','Berlin')$$,'22023');

-- A restaurant owner stays pending until BOTH required documents are approved.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000002');
do $$
declare onboarding jsonb := public.owner_start_directory(null::uuid,'restaurant','Restaurant Zagros','Berlin');
begin
  assert onboarding->'required_document_kinds'='["identity","business_registration"]'::jsonb;
  perform set_config('e2.restaurant_seller',onboarding->'seller'->>'id',true);
end $$;
insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
select current_setting('e2.restaurant_seller')::uuid,kind,
  current_setting('e2.restaurant_seller')||'/'||kind||'/e2.pdf','application/pdf'
from unnest(array['identity','business_registration']::public.seller_document_kind[]) kind;
select pg_temp.act_as('e2100000-0000-0000-0000-000000000005',true);
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id=current_setting('e2.restaurant_seller')::uuid and kind='identity';
do $$ begin
  assert (select status='pending' from public.sellers where id=current_setting('e2.restaurant_seller')::uuid),
    'identity alone does not approve a restaurant';
end $$;
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id=current_setting('e2.restaurant_seller')::uuid and kind='business_registration';
do $$ begin
  assert (select count(*)=1 from public.seller_status_history
    where seller_id=current_setting('e2.restaurant_seller')::uuid and to_status='approved');
end $$;
do $$ begin
  assert (select status='approved' from public.sellers where id=current_setting('e2.restaurant_seller')::uuid);
  assert public.is_verified_seller(current_setting('e2.restaurant_seller')::uuid);
end $$;

-- Rule 2 covers every PENDING BUSINESS seller, also a marketplace business without a
-- directory type (it proves identity + business registration).
insert into public.seller_documents(seller_id,kind,storage_path,mime_type,status) values
 ('e2200000-0000-0000-0000-000000000004','identity','e2200000-0000-0000-0000-000000000004/identity/a.pdf','application/pdf','pending'),
 ('e2200000-0000-0000-0000-000000000004','business_registration','e2200000-0000-0000-0000-000000000004/business_registration/b.pdf','application/pdf','pending');
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id='e2200000-0000-0000-0000-000000000004';
do $$ begin
  assert (select status='approved' and directory_type is null from public.sellers
    where id='e2200000-0000-0000-0000-000000000004'), 'pending marketplace business approved by its document set';
end $$;

-- Never auto-approve private sellers; never re-open rejected or suspended sellers.
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id in ('e2200000-0000-0000-0000-000000000003','e2200000-0000-0000-0000-000000000006',
  'e2200000-0000-0000-0000-000000000007');
do $$ begin
  assert (select status='pending' from public.sellers where id='e2200000-0000-0000-0000-000000000003'),
    'private seller stays pending';
  assert (select status='rejected' and rejection_reason='Fake business' from public.sellers
    where id='e2200000-0000-0000-0000-000000000006'), 'rejected seller is not re-opened';
  assert (select status='suspended' from public.sellers where id='e2200000-0000-0000-0000-000000000007'),
    'suspended seller is not re-opened';
  assert not exists(select 1 from public.seller_status_history where seller_id in
    ('e2200000-0000-0000-0000-000000000003','e2200000-0000-0000-0000-000000000006','e2200000-0000-0000-0000-000000000007')
    and to_status='approved'), 'no approval history for them';
end $$;

-- An existing business seller sets its type without any status change.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000006');
do $$ begin
  assert public.owner_set_directory_type(
    'e2200000-0000-0000-0000-000000000006','cafe'
  )->'seller'->>'directory_type'='cafe';
  assert (select status='rejected' from public.sellers where id='e2200000-0000-0000-0000-000000000006'),
    'setting a type never changes status';
end $$;

-- A private seller can add one separate business through the explicit source ID.
-- The original private row and its documents remain attached to that private identity.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000003');
do $$
declare onboarding jsonb; business_id uuid;
begin
  onboarding := public.owner_start_directory(
    'e2200000-0000-0000-0000-000000000003','cafe','E2 Private Business','Berlin'
  );
  business_id := (onboarding->'seller'->>'id')::uuid;
  perform set_config('e2.private_business',business_id::text,true);
  assert onboarding->'seller'->>'kind'='business'
    and onboarding->'seller'->>'directory_type'='cafe';
  assert (select kind='private' and status='pending' from public.sellers
    where id='e2200000-0000-0000-0000-000000000003'),
    'starting a business never converts the private seller';
  assert (select count(*)=2 from public.sellers where user_id=auth.uid()),
    'private and business identities coexist';
end $$;
select pg_temp.expect_error(
  $$select public.owner_set_directory_type(
    'e2200000-0000-0000-0000-000000000003','restaurant')$$,
  '42501'
);
select pg_temp.expect_error(
  $$select public.owner_start_directory(
    'e2200000-0000-0000-0000-000000000003','restaurant','Second Business','Berlin')$$,
  '22023'
);
do $$
declare onboarding jsonb := public.get_my_directory_onboarding(
  current_setting('e2.private_business')::uuid
);
begin
  assert onboarding->'seller'->>'id'=current_setting('e2.private_business');
  assert onboarding->'documents'='[]'::jsonb,
    'explicit business onboarding never leaks the private seller documents';
end $$;

-- An explicit unknown business UUID fails closed instead of revealing whether the
-- account has another seller.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000005');
select pg_temp.expect_error(
  $$select public.owner_set_directory_type(
    'ffffffff-ffff-4fff-8fff-ffffffffffff','cafe')$$,
  '42501'
);
reset role;

set local role anon;
select pg_temp.expect_error(format(
  $$select public.get_my_directory_onboarding(%L)$$,
  current_setting('e2.private_business')
),'42501');
reset role;

rollback;
