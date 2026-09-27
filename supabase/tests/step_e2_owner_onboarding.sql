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

insert into public.sellers(id,user_id,kind,status,shop_name,slug,city,country_code) values
 ('e2200000-0000-0000-0000-000000000003','e2100000-0000-0000-0000-000000000003','private','pending','E2 Private','e2-private','Berlin','DE'),
 ('e2200000-0000-0000-0000-000000000004','e2100000-0000-0000-0000-000000000004','business','pending','E2 Marketplace','e2-marketplace','Berlin','DE');

do $$ begin
  assert public.directory_required_document_kinds('doctor')
    = array['identity','medical_professional_registration']::public.seller_document_kind[];
  assert public.directory_required_document_kinds('fast_food')
    = array['identity','business_registration']::public.seller_document_kind[];
  assert not has_function_privilege('anon','public.get_my_directory_onboarding()','execute');
  assert not has_function_privilege('anon','public.owner_start_directory(public.directory_business_type,text,text)','execute');
end $$;

set local role authenticated;

-- A user without a seller starts a doctor entry: pending business seller, doctor documents.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000001');
select pg_temp.expect_error($$select public.owner_start_directory('doctor','X','Berlin')$$,'22023');
select pg_temp.expect_error($$select public.owner_start_directory('doctor','Praxis Dr. Test','Atlantis')$$,'22023');
select pg_temp.expect_error($$select public.owner_start_directory(null,'Praxis Dr. Test','Berlin')$$,'22023');
do $$
declare onboarding jsonb := public.owner_start_directory('doctor',' Praxis Dr. Test ','Berlin');
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
declare onboarding jsonb := public.get_my_directory_onboarding();
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
  select d into doc from jsonb_array_elements(public.get_my_directory_onboarding()->'documents') d
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
declare onboarding jsonb := public.get_my_directory_onboarding();
begin
  assert onboarding->'seller'->>'status'='approved', format('approved by documents: %s',onboarding);
  assert not (onboarding->>'is_verified')::boolean,
    'a doctor is only verified once the doctor profile (draft) exists';
end $$;

-- A doctor draft completes verification; the profile type then owns the directory type.
select public.owner_upsert_directory_profile(
  p_type=>'doctor',p_description=>'Allgemeinmedizinische Praxis mit kurdisch- und arabischsprachigem Team.',
  p_phone=>'030 1234567',p_website=>null,p_cover_image_path=>null,
  p_languages=>array['german','kurdish']::public.directory_spoken_language[],
  p_specialty=>'general_medicine',p_insurance=>'both');
do $$
declare onboarding jsonb := public.get_my_directory_onboarding();
begin
  assert (onboarding->>'is_verified')::boolean, format('doctor draft + approved proof verifies: %s',onboarding);
  assert onboarding->'profile'->>'type'='doctor' and not (onboarding->'profile'->>'is_published')::boolean;
end $$;
select pg_temp.expect_error($$select public.owner_start_directory('restaurant')$$,'22023');

-- A restaurant owner stays pending until BOTH required documents are approved.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000002');
do $$
declare onboarding jsonb := public.owner_start_directory('restaurant','Restaurant Zagros','Berlin');
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
  assert (select status='approved' from public.sellers where id=current_setting('e2.restaurant_seller')::uuid);
  assert public.is_verified_seller(current_setting('e2.restaurant_seller')::uuid);
end $$;

-- Marketplace-only business sellers keep the old path (no directory_type, no auto-approval).
insert into public.seller_documents(seller_id,kind,storage_path,mime_type,status) values
 ('e2200000-0000-0000-0000-000000000004','identity','e2200000-0000-0000-0000-000000000004/identity/a.pdf','application/pdf','pending'),
 ('e2200000-0000-0000-0000-000000000004','business_registration','e2200000-0000-0000-0000-000000000004/business_registration/b.pdf','application/pdf','pending');
select public.moderate_seller_document(id,'approve') from public.seller_documents
where seller_id='e2200000-0000-0000-0000-000000000004';
do $$ begin
  assert (select status='pending' and directory_type is null from public.sellers
    where id='e2200000-0000-0000-0000-000000000004'), 'marketplace seller status is unchanged';
end $$;

-- An existing marketplace business can join the directory; private sellers cannot.
select pg_temp.act_as('e2100000-0000-0000-0000-000000000004');
do $$ begin
  assert public.owner_start_directory('cafe')->'seller'->>'directory_type'='cafe';
end $$;
select pg_temp.act_as('e2100000-0000-0000-0000-000000000003');
select pg_temp.expect_error($$select public.owner_start_directory('cafe','E2 Private','Berlin')$$,'42501');

-- Owners only ever see their own onboarding data.
do $$ begin
  assert public.get_my_directory_onboarding()->'documents'='[]'::jsonb;
end $$;
reset role;

set local role anon;
select pg_temp.expect_error($$select public.get_my_directory_onboarding()$$,'42501');
reset role;

rollback;
