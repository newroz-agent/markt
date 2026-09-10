-- Run against a migrated local database: psql -v ON_ERROR_STOP=1 -f this_file.
-- All fixtures and test helpers are rolled back; no pgTAP dependency.
begin;

create function pg_temp.expect_error(command text, expected_state text)
returns void language plpgsql as $$
begin
  begin
    execute command;
  exception when others then
    if sqlstate = expected_state then return; end if;
    raise;
  end;
  raise exception 'Expected SQLSTATE % for %', expected_state, command;
end;
$$;

insert into auth.users (id, email) values
  ('f1000000-0000-0000-0000-000000000001', 'phase1-buyer@example.invalid'),
  ('f1000000-0000-0000-0000-000000000002', 'phase1-seller@example.invalid'),
  ('f1000000-0000-0000-0000-000000000003', 'phase1-outsider@example.invalid');
insert into public.sellers (id, user_id, kind, status, shop_name, slug) values
  ('f2000000-0000-0000-0000-000000000001', 'f1000000-0000-0000-0000-000000000002',
   'private', 'approved', 'Phase One', 'phase1-sql-test'),
  ('f2000000-0000-0000-0000-000000000002', null,
   'private', 'approved', 'No Owner', 'phase1-sql-ownerless');
insert into public.categories (id, slug, name_de, name_en, name_ar, name_tr, icon_key, image_url)
values ('f3000000-0000-0000-0000-000000000001', 'phase1-sql-test', 'Test', 'Test', 'Test', 'Test', 'test', 'test');
insert into public.products (id, seller_id, category_id, title, slug, description, condition, status, price_cents)
values ('f4000000-0000-0000-0000-000000000001', 'f2000000-0000-0000-0000-000000000001',
  'f3000000-0000-0000-0000-000000000001', 'Phase One Product', 'phase1-sql-test',
  'Phase one test description', 'used', 'active', 1200);

set local role authenticated;
set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}';
do $$
declare
  chat public.chats;
  again public.chats;
  notice public.messages;
  card public.messages;
begin
  chat := public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-000000000001');
  perform set_config('test.phase1_chat_id', chat.id::text, true);
  again := public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-000000000001');
  assert chat.id = again.id, 'Repeated creation returns the same chat';
  assert (select count(*) = 2 from public.messages where chat_id = chat.id), 'Exactly two bootstrap messages';
  select * into strict notice from public.messages where chat_id = chat.id and kind = 'system';
  select * into strict card from public.messages where chat_id = chat.id and kind = 'product';
  assert notice.body = U&'Bitte halte die Kommunikation und die Zahlungsabsprachen innerhalb der App, um dich zu sch\00FCtzen.', 'Exact German notice';
  assert notice.sender_id is null and notice.read_at is not null, 'Notice is server authored and already read';
  assert card.product_id = chat.product_id and card.sender_id = auth.uid() and card.read_at is null, 'Product card context';
  assert notice.created_at < card.created_at, 'Notice precedes product card';
  assert chat.last_message_preview = 'product' and chat.last_message_at = card.created_at, 'RPC returns trigger-updated activity';
  assert public.get_unread_chat_count() = 0, 'Sender has no unread bootstrap messages';
  assert public.mark_chat_read(chat.id) = 0, 'Sender cannot mark own card read';
  assert (select count(*) = 0 from public.messages where chat_id = chat.id and kind = 'product' and read_at is not null);
  perform pg_temp.expect_error(format('insert into public.chats (buyer_id, seller_id) values (%L,%L)', auth.uid(), chat.seller_id), '42501');
  perform pg_temp.expect_error(format('insert into public.messages (chat_id, sender_id, kind, body) values (%L,%L,''system'',''fake'')', chat.id, auth.uid()), '42501');
  perform pg_temp.expect_error(format('insert into public.messages (chat_id, sender_id, body, read_at) values (%L,%L,''fake'',now())', chat.id, auth.uid()), '42501');
  perform pg_temp.expect_error(format('insert into public.messages (chat_id, sender_id, body, created_at) values (%L,%L,''fake'',now())', chat.id, auth.uid()), '42501');
  perform pg_temp.expect_error(format('insert into public.messages (chat_id, sender_id, body) values (%L,%L,''fake'')', chat.id, 'f1000000-0000-0000-0000-000000000002'), '42501');
  perform pg_temp.expect_error(format('update public.chats set last_message_preview = ''fake'' where id = %L', chat.id), '42501');
  perform pg_temp.expect_error($q$select public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-000000000099')$q$, 'P0002');
  insert into storage.objects (bucket_id, name) values ('chat-media', chat.id::text || '/phase1-test.jpg');
end;
$$;

set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
do $$
#variable_conflict use_variable
declare chat_id uuid := current_setting('test.phase1_chat_id')::uuid;
begin
  assert (select count(*) = 0 from public.chats where id = chat_id), 'Nonparticipant admin cannot read chat';
  assert (select count(*) = 0 from public.messages where messages.chat_id = chat_id), 'Nonparticipant admin cannot read messages';
  assert not public.chat_is_open(chat_id), 'Open helper does not leak outsider context';
  assert public.get_unread_chat_count() = 0, 'Outsider unread count';
  assert not exists (select 1 from storage.objects where bucket_id = 'chat-media' and name = chat_id::text || '/phase1-test.jpg'), 'Nonparticipant admin cannot read attachment';
  perform pg_temp.expect_error(format('insert into storage.objects (bucket_id, name) values (''chat-media'', %L)', chat_id::text || '/intrusion.jpg'), '42501');
  perform pg_temp.expect_error(format('select public.mark_chat_read(%L)', chat_id), '42501');
  perform pg_temp.expect_error($q$select public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', null, 'f1000000-0000-0000-0000-000000000001')$q$, '42501');
  perform pg_temp.expect_error($q$select public.get_or_create_chat('f2000000-0000-0000-0000-000000000002', null, 'f1000000-0000-0000-0000-000000000001')$q$, 'P0002');
  perform pg_temp.expect_error(format('insert into public.messages (chat_id, sender_id, body) values (%L,%L,''intrusion'')', chat_id, auth.uid()), '42501');
end;
$$;

set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000002","role":"authenticated"}';
do $$
#variable_conflict use_variable
declare chat_id uuid := current_setting('test.phase1_chat_id')::uuid;
begin
  assert public.get_unread_chat_count() = 1, 'Recipient has one unread card, not the notice';
  assert exists (select 1 from storage.objects where bucket_id = 'chat-media' and name = chat_id::text || '/phase1-test.jpg'), 'Recipient can read attachment';
  assert (select count(*) = 1 from public.notifications where user_id = auth.uid() and data->>'chatId' = chat_id::text), 'Existing notification trigger fires once';
  perform pg_temp.expect_error(format('update public.messages set body = ''tampered'' where messages.chat_id = %L', chat_id), '42501');
  assert public.mark_chat_read(chat_id) = 1, 'Read RPC marks incoming card';
  assert public.mark_chat_read(chat_id) = 0, 'Read RPC is idempotent';
  assert public.get_unread_chat_count() = 0, 'Existing unread counter clears';
  assert (select seller_last_read_at is not null and buyer_last_read_at is not null from public.chats where id = chat_id), 'Read markers remain participant-specific';
  insert into public.messages (chat_id, sender_id, body) values (chat_id, auth.uid(), 'Seller reply');
  perform pg_temp.expect_error($q$select public.get_or_create_chat('f2000000-0000-0000-0000-000000000001')$q$, '22023');
end;
$$;

set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}';
do $$
#variable_conflict use_variable
declare
  chat_id uuid := current_setting('test.phase1_chat_id')::uuid;
  general public.chats;
begin
  assert public.get_unread_chat_count() = 1, 'Reply is unread for buyer';
  update public.messages set read_at = '2099-01-01' where messages.chat_id = chat_id and body = 'Seller reply';
  assert (select read_at = statement_timestamp() from public.messages where messages.chat_id = chat_id and body = 'Seller reply'), 'Direct read timestamp is server assigned';
  update public.messages set read_at = null where messages.chat_id = chat_id and body = 'Seller reply';
  assert public.get_unread_chat_count() = 0, 'Read messages cannot be reset to unread';
  general := public.get_or_create_chat('f2000000-0000-0000-0000-000000000001');
  assert (select count(*) = 1 from public.messages where messages.chat_id = general.id), 'Seller-only context has notice, no invented product';
end;
$$;

reset role;
set local request.jwt.claims = '{}';
create function pg_temp.reject_product_seed()
returns trigger language plpgsql as $$
begin
  if new.kind = 'product' then raise exception 'Simulated seed failure'; end if;
  return new;
end;
$$;
create trigger test_reject_product_seed before insert on public.messages
  for each row execute function pg_temp.reject_product_seed();
set local role authenticated;
set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000002","role":"authenticated"}';
do $$
begin
  perform pg_temp.expect_error($q$select public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-000000000001', 'f1000000-0000-0000-0000-000000000003')$q$, 'P0001');
  assert not exists (select 1 from public.chats where buyer_id = 'f1000000-0000-0000-0000-000000000003'), 'Seed failure rolls back the whole chat';
end;
$$;
reset role;
drop trigger test_reject_product_seed on public.messages;
set local role authenticated;
do $$
declare seller_chat public.chats;
begin
  seller_chat := public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-000000000001', 'f1000000-0000-0000-0000-000000000003');
  assert (select sender_id = auth.uid() from public.messages where chat_id = seller_chat.id and kind = 'product'), 'Seller-initiated card has the actual initiating sender';
end;
$$;
reset role;
set local request.jwt.claims = '{}';
do $$
declare
  old_id uuid := current_setting('test.phase1_chat_id')::uuid;
  new_chat public.chats;
begin
  update public.chats set closed_at = now() where id = old_id;
  perform set_config('request.jwt.claims', '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
  new_chat := public.get_or_create_chat('f2000000-0000-0000-0000-000000000001', 'f4000000-0000-0000-0000-000000000001');
  assert new_chat.id <> old_id, 'Closed context creates a new chat';
  assert (select count(*) = 2 from public.messages where chat_id = new_chat.id), 'New chat is seeded once';
  assert (select count(*) = 3 from public.messages where chat_id = old_id), 'Old chat is untouched';
  perform set_config('request.jwt.claims', '{}', true);
  perform pg_temp.expect_error($q$select public.get_or_create_chat('f2000000-0000-0000-0000-000000000001')$q$, '42501');
  assert not has_function_privilege('anon', 'public.get_or_create_chat(uuid,uuid,uuid)', 'execute'), 'Anonymous RPC denied';
  assert not has_table_privilege('authenticated', 'public.messages', 'truncate'), 'Clients cannot truncate messages';
  assert (select count(*) = 2 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename in ('chats', 'messages')), 'Existing realtime publication retained';
  assert (select bool_and(relreplident = 'f') from pg_class where oid in ('public.chats'::regclass, 'public.messages'::regclass)), 'Full replica identity retained';
end;
$$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}';
select pg_temp.expect_error(format(
  'insert into public.messages (chat_id, sender_id, body) values (%L,%L,''closed'')',
  current_setting('test.phase1_chat_id'), auth.uid()), '42501');

-- Inbox projection must retain private counterpart/catalog context without
-- broadening table RLS or returning any private profile fields.
reset role;
set local request.jwt.claims = '{}';
update public.profiles set display_name = 'Buyer Display',
  avatar_path = 'f1000000-0000-0000-0000-000000000001/avatar.jpg', phone = 'private-phone'
where id = 'f1000000-0000-0000-0000-000000000001';
update public.sellers set avatar_url = 'https://example.invalid/shop.jpg', status = 'suspended'
where id = 'f2000000-0000-0000-0000-000000000001';
update public.products set status = 'sold'
where id = 'f4000000-0000-0000-0000-000000000001';
insert into public.product_images (product_id, storage_path, image_url)
values ('f4000000-0000-0000-0000-000000000001', 'phase1-test/product.jpg', 'https://example.invalid/product.jpg');
insert into public.messages (chat_id, kind, body)
values (current_setting('test.phase1_chat_id')::uuid, 'system', 'Unread system excluded');
update public.chats set last_message_at = now() + interval '1 second'
where id = current_setting('test.phase1_chat_id')::uuid;

set local role authenticated;
set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000002","role":"authenticated"}';
do $$
declare
  inbox jsonb := public.get_chat_inbox(current_setting('test.phase1_chat_id')::uuid);
  item jsonb := inbox->0;
begin
  assert jsonb_array_length(inbox) = 1, 'Single-chat inbox returns an array';
  assert not exists (select 1 from public.profiles where id = 'f1000000-0000-0000-0000-000000000001'), 'Buyer profile table remains private';
  assert item->>'buyer_name' = 'Buyer Display', 'Seller sees buyer display name';
  assert item->>'buyer_avatar_url' = 'f1000000-0000-0000-0000-000000000001/avatar.jpg', 'Buyer avatar reference';
  assert item->>'seller_user_id' = auth.uid()::text;
  assert item->>'shop_name' = 'Phase One' and item->>'shop_slug' = 'phase1-sql-test';
  assert item->>'shop_avatar_url' = 'https://example.invalid/shop.jpg';
  assert item->'product' = jsonb_build_object('id', 'f4000000-0000-0000-0000-000000000001',
    'title', 'Phase One Product', 'price_cents', 1200, 'currency', 'EUR',
    'image_url', 'https://example.invalid/product.jpg'), 'Sold product and image retained';
  assert (item->>'unread_count')::integer = 0, 'Read card, own reply and unread system excluded';
  assert (public.get_chat_inbox()->0->>'id') = current_setting('test.phase1_chat_id'), 'Most recent activity first';
  assert (select array_agg(key order by key) from jsonb_object_keys(item) as key) = array[
    'buyer_avatar_url', 'buyer_id', 'buyer_name', 'created_at', 'id', 'last_message_at',
    'last_message_preview', 'product', 'seller_id', 'seller_user_id', 'shop_avatar_url',
    'shop_name', 'shop_slug', 'unread_count'], 'Only whitelisted fields returned';
  assert (select sum((entry->>'unread_count')::integer) = 1
    from jsonb_array_elements(public.get_chat_inbox()) as entry), 'Only new incoming card counts';
end;
$$;

set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}';
do $$
begin
  assert not exists (select 1 from public.sellers where id = 'f2000000-0000-0000-0000-000000000001'), 'Suspended seller hidden by table RLS';
  assert not exists (select 1 from public.products where id = 'f4000000-0000-0000-0000-000000000001'), 'Sold product hidden by table RLS';
  assert jsonb_array_length(public.get_chat_inbox()) = 3, 'Buyer retains all chats including closed chat';
  assert public.get_chat_inbox(current_setting('test.phase1_chat_id')::uuid)->0->'product'->>'title' = 'Phase One Product';
  assert public.get_chat_inbox('ffffffff-ffff-ffff-ffff-ffffffffffff') = '[]'::jsonb, 'Missing chat returns empty array';
end;
$$;

set local request.jwt.claims = '{"sub":"f1000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
do $$
begin
  assert public.get_chat_inbox(current_setting('test.phase1_chat_id')::uuid) = '[]'::jsonb, 'Outsider admin cannot project another chat';
  assert jsonb_array_length(public.get_chat_inbox()) = 1, 'Admin sees only own participant chat';
end;
$$;

reset role;
set local request.jwt.claims = '{}';
do $$
declare
  target_id uuid := current_setting('test.phase1_chat_id')::uuid;
  general_id uuid;
  inbox jsonb;
begin
  select id into strict general_id from public.chats
  where buyer_id = 'f1000000-0000-0000-0000-000000000001' and product_id is null;
  -- An earlier non-product message with a product reference must not pin a card.
  insert into public.messages (chat_id, kind, body, product_id, created_at)
  values (general_id, 'text', 'Not a product card', 'f4000000-0000-0000-0000-000000000001', now() - interval '2 days');
  update public.chats set last_message_at = null, created_at = now() - interval '1 day' where id = general_id;
  update public.chats set last_message_at = null, created_at = now() - interval '2 days' where id = target_id;
  perform set_config('request.jwt.claims', '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
  inbox := public.get_chat_inbox();
  assert inbox->1->>'id' = general_id::text and inbox->2->>'id' = target_id::text, 'Null activity last, creation descending';
  assert public.get_chat_inbox(general_id)->0->'product' = 'null'::jsonb, 'Non-product kind never pins header';
  perform set_config('request.jwt.claims', '{}', true);
  insert into public.messages (chat_id, kind, product_id, created_at)
  values (general_id, 'product', 'f4000000-0000-0000-0000-000000000001', now() - interval '1 day');
  perform set_config('request.jwt.claims', '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
  assert public.get_chat_inbox(general_id)->0->'product'->>'id' = 'f4000000-0000-0000-0000-000000000001', 'Product message pins even without chat product_id';
  perform set_config('request.jwt.claims', '{}', true);
  insert into public.products (id, seller_id, category_id, title, slug, description, condition, status, price_cents)
  values ('f4000000-0000-0000-0000-000000000002', 'f2000000-0000-0000-0000-000000000001',
    'f3000000-0000-0000-0000-000000000001', 'Later Product', 'phase1-later-product',
    'Later product test description', 'used', 'sold', 2200);
  insert into public.messages (chat_id, kind, product_id)
  values (general_id, 'product', 'f4000000-0000-0000-0000-000000000002');
  perform set_config('request.jwt.claims', '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
  assert public.get_chat_inbox(general_id)->0->'product'->>'id' = 'f4000000-0000-0000-0000-000000000001', 'Later product card does not replace earliest pinned product';
  perform set_config('request.jwt.claims', '{}', true);
  assert public.get_chat_inbox() = '[]'::jsonb, 'No JWT exposes no chats';
  assert not has_function_privilege('anon', 'public.get_chat_inbox(uuid)', 'execute');
  assert not has_function_privilege('service_role', 'public.get_chat_inbox(uuid)', 'execute');
  assert has_function_privilege('authenticated', 'public.get_chat_inbox(uuid)', 'execute');
end;
$$;

rollback;
