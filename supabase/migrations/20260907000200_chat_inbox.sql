begin;

-- Scope before projecting otherwise RLS-hidden counterpart/catalog fields.
-- Separate buyer/seller branches reuse the existing participant activity indexes.
create function public.get_chat_inbox(p_chat_id uuid default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with caller as materialized (
    select auth.uid() as id
  ), participant_chats as materialized (
    select chat.*
    from public.chats as chat
    where chat.buyer_id = (select id from caller)
      and (p_chat_id is null or chat.id = p_chat_id)
    union all
    select chat.*
    from public.chats as chat
    join public.sellers as seller on seller.id = chat.seller_id
    where seller.user_id = (select id from caller)
      and chat.buyer_id is distinct from (select id from caller)
      and (p_chat_id is null or chat.id = p_chat_id)
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', chat.id,
      'buyer_id', chat.buyer_id,
      'seller_id', chat.seller_id,
      'seller_user_id', seller.user_id,
      'shop_name', seller.shop_name,
      'shop_slug', seller.slug,
      'shop_avatar_url', seller.avatar_url,
      'buyer_name', buyer.display_name,
      'buyer_avatar_url', buyer.avatar_path,
      'last_message_at', chat.last_message_at,
      'last_message_preview', chat.last_message_preview,
      'created_at', chat.created_at,
      'unread_count', (
        select count(*) from public.messages as unread
        where unread.chat_id = chat.id and unread.read_at is null
          and unread.kind <> 'system'
          and unread.sender_id is distinct from (select id from caller)
      ),
      'product', case when product.id is not null then jsonb_build_object(
        'id', product.id,
        'title', product.title,
        'price_cents', product.price_cents,
        'currency', product.currency,
        'image_url', image.image_url
      ) else null end
    ) order by chat.last_message_at desc nulls last, chat.created_at desc, chat.id
  ), '[]'::jsonb)
  from participant_chats as chat
  join public.sellers as seller on seller.id = chat.seller_id
  left join public.profiles as buyer on buyer.id = chat.buyer_id
  left join lateral (
    select message.product_id
    from public.messages as message
    where message.chat_id = chat.id and message.kind = 'product'
    order by message.created_at, message.id
    limit 1
  ) as pinned on true
  left join public.products as product on product.id = pinned.product_id
  left join lateral (
    select product_image.image_url
    from public.product_images as product_image
    where product_image.product_id = product.id
    order by product_image.sort_order, product_image.created_at, product_image.id
    limit 1
  ) as image on true;
$$;

revoke all on function public.get_chat_inbox(uuid) from public, anon, service_role;
grant execute on function public.get_chat_inbox(uuid) to authenticated;

commit;
