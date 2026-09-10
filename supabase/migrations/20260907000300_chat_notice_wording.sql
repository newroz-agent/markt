begin;

-- Final German production wording for the anti-circumvention safety notice
-- (master spec: "Kommunikation und die Zahlungsabsprachen"). Only the stored
-- procedure text changes; future chats seed the new wording. Existing chats
-- are deliberately not backfilled.
create or replace function public.seed_chat_messages()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.messages (chat_id, kind, body, read_at, created_at)
  values (
    new.id, 'system',
    U&'Bitte halte die Kommunikation und die Zahlungsabsprachen innerhalb der App, um dich zu sch\00FCtzen.',
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

commit;
