begin;

-- Bootstrap only on INSERT, in the same transaction as the chat. Existing chats
-- are deliberately not backfilled. The existing message triggers own activity
-- previews and notifications; the safety notice is not an unread message.
create function public.seed_chat_messages()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.messages (chat_id, kind, body, read_at, created_at)
  values (
    new.id, 'system',
    U&'Bitte halte die Kommunikation und Zahlung innerhalb der App, um dich zu sch\00FCtzen.',
    new.created_at, new.created_at - interval '1 microsecond'
  );

  if new.product_id is not null then
    insert into public.messages (chat_id, sender_id, kind, product_id, created_at)
    values (
      new.id, coalesce(auth.uid(), new.buyer_id), 'product', new.product_id,
      new.created_at
    );
  end if;
  return new;
end;
$$;

revoke all on function public.seed_chat_messages() from public, anon, authenticated;
create trigger seed_chat_messages
  after insert on public.chats
  for each row execute function public.seed_chat_messages();

create or replace function public.get_or_create_chat(
  p_seller_id uuid,
  p_product_id uuid default null,
  p_buyer_id uuid default null
)
returns public.chats
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_buyer_id uuid := coalesce(p_buyer_id, auth.uid());
  seller_user_id uuid;
  chat_row public.chats%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.user_id into seller_user_id
  from public.sellers as seller
  where seller.id = p_seller_id and seller.status = 'approved';
  if not found or seller_user_id is null then
    raise exception 'Seller is not available' using errcode = 'P0002';
  end if;
  if resolved_buyer_id = seller_user_id then
    raise exception 'A chat needs two distinct participants' using errcode = '22023';
  end if;
  if auth.uid() is distinct from resolved_buyer_id
    and auth.uid() is distinct from seller_user_id then
    raise exception 'Chat participant mismatch' using errcode = '42501';
  end if;
  if p_product_id is not null and not exists (
    select 1 from public.products as product
    where product.id = p_product_id
      and product.seller_id = p_seller_id and product.status = 'active'
  ) then
    raise exception 'Product is not available for chat' using errcode = 'P0002';
  end if;

  -- The existing partial unique indexes arbitrate concurrent creation. A fresh
  -- statement sees the committed winner; retry if it was closed/deleted meanwhile.
  loop
    select chat.* into chat_row
    from public.chats as chat
    where chat.buyer_id = resolved_buyer_id and chat.seller_id = p_seller_id
      and chat.product_id is not distinct from p_product_id
      and chat.closed_at is null
    for update;
    if found then
      return chat_row;
    end if;

    insert into public.chats (buyer_id, seller_id, product_id)
    values (resolved_buyer_id, p_seller_id, p_product_id)
    on conflict do nothing
    returning * into chat_row;
    if found then
      -- AFTER INSERT seeding updates the stored chat, not INSERT RETURNING.
      select chat.* into chat_row from public.chats as chat where chat.id = chat_row.id;
      return chat_row;
    end if;
  end loop;
end;
$$;

-- All client creation goes through the validated RPC, never arbitrary chat fields.
drop policy chats_insert_buyer on public.chats;
drop policy chats_manage_admin on public.chats;
alter policy chats_select_participant on public.chats
  using (public.is_chat_participant(id));
revoke all on public.chats from public, anon, authenticated;
grant select on public.chats to authenticated;

alter policy messages_select_participant on public.messages
  using (public.is_chat_participant(chat_id));
alter policy messages_insert_participant on public.messages
  with check (
    sender_id = auth.uid() and kind <> 'system' and read_at is null
    and public.is_chat_participant(chat_id) and public.chat_is_open(chat_id)
  );
alter policy messages_mark_read_recipient on public.messages
  using (
    sender_id is distinct from auth.uid() and read_at is null
    and public.is_chat_participant(chat_id)
  )
  with check (
    sender_id is distinct from auth.uid() and read_at is not null
    and public.is_chat_participant(chat_id)
  );

-- Column privileges also prevent forged ordering timestamps/read receipts at send.
revoke all on public.messages from public, anon, authenticated;
grant select on public.messages to authenticated;
grant insert (chat_id, sender_id, kind, body, media_path, product_id)
  on public.messages to authenticated;
grant insert (id) on public.messages to authenticated;
grant update (read_at) on public.messages to authenticated;

create or replace function public.protect_message_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    if (to_jsonb(new) - 'read_at') is distinct from (to_jsonb(old) - 'read_at') then
      raise exception 'Messages are immutable except for their read timestamp'
        using errcode = '42501';
    end if;
    if not public.is_chat_participant(old.chat_id)
      or old.sender_id = auth.uid() or new.read_at is null then
      raise exception 'Only recipients can mark messages read' using errcode = '42501';
    end if;
    new.read_at := coalesce(old.read_at, statement_timestamp());
  end if;
  return new;
end;
$$;

create or replace function public.mark_chat_read(p_chat_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  marked_count integer;
  chat_row public.chats%rowtype;
begin
  select chat.* into chat_row
  from public.chats as chat
  where chat.id = p_chat_id and public.is_chat_participant(chat.id)
  for update;
  if not found then
    raise exception 'Chat access denied' using errcode = '42501';
  end if;

  update public.messages set read_at = statement_timestamp()
  where chat_id = p_chat_id and sender_id is distinct from auth.uid() and read_at is null;
  get diagnostics marked_count = row_count;

  update public.chats set
    buyer_last_read_at = case when chat_row.buyer_id = auth.uid()
      then statement_timestamp() else buyer_last_read_at end,
    seller_last_read_at = case when public.owns_seller(chat_row.seller_id)
      then statement_timestamp() else seller_last_read_at end
  where id = p_chat_id;
  return marked_count;
end;
$$;

create or replace function public.chat_is_open(target_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.chats as chat
    where chat.id = target_chat_id and chat.closed_at is null
      and public.is_chat_participant(chat.id)
  );
$$;

revoke all on function public.get_or_create_chat(uuid, uuid, uuid) from public, anon;
revoke all on function public.mark_chat_read(uuid) from public, anon;
revoke all on function public.get_unread_chat_count() from public, anon;
grant execute on function public.get_or_create_chat(uuid, uuid, uuid) to authenticated;
grant execute on function public.mark_chat_read(uuid) to authenticated;
grant execute on function public.get_unread_chat_count() to authenticated;

-- Chat attachments follow the same participant boundary as message rows.
alter policy chat_media_storage_select on storage.objects
  using (bucket_id = 'chat-media'
    and public.is_chat_participant_path((storage.foldername(name))[1]));
alter policy chat_media_storage_insert on storage.objects
  with check (bucket_id = 'chat-media'
    and public.is_chat_participant_path((storage.foldername(name))[1]));
alter policy chat_media_storage_update on storage.objects
  using (bucket_id = 'chat-media'
    and public.is_chat_participant_path((storage.foldername(name))[1]))
  with check (bucket_id = 'chat-media'
    and public.is_chat_participant_path((storage.foldername(name))[1]));
alter policy chat_media_storage_delete on storage.objects
  using (bucket_id = 'chat-media'
    and public.is_chat_participant_path((storage.foldername(name))[1]));

commit;
