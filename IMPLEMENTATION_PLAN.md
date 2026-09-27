# Zêrîn — Implementation Plan

Updated: 2026-09-14
Canonical scope: `docs/SCOPE.md`
Deferred Profile/Map detail: `zerin-addendum-profile-and-map.md`

Legend: ✅ complete · 🟡 partial · 🔴 missing · ⛔ out of scope

## 0. Product contract

Zêrîn is a Germany-only unified private/business listing marketplace. Every
listing uses one Sell flow, enters `pending_review`, and becomes public only
after moderation. Buyer–seller contact is in-app chat only.

The following are out of scope: cart, checkout, orders, product payments,
Stripe, commissions/payouts, a separate partner-store flow, and a Stores tab.
Historical SQL objects are not an instruction to rebuild those features.

Shell: **Home · Categories · Sell · Chat · Account**.

## 1. Stabilization and scope cleanup

- ✅ Replace the superseded scope contract.
- ✅ Remove dead Flutter cart/checkout/order code.
- ✅ Remove `flutter_stripe`; retain image and connectivity dependencies needed by upcoming work.
- ✅ Replace Cart with an auth-gated Chat tab and unread badge.
- ✅ Re-run tests/analyzer and record current evidence in `docs/STATUS.md`.
- 🟡 Inspect linked Supabase migration parity; review before any push (the latest read-only
  attempt timed out before returning the remote ledger).
- ✅ Confirm the obsolete `enchanted-apricot` worktree contains nothing unique to merge.
- ✅ Retire `enchanted-apricot` without merging it after explicit destructive-action confirmation.

## 2. Unified Sell and moderation vertical slice

Build Sell and moderation together so submitted listings have an operational
path to publication.

### Sell

1. Catalog/template search, with a free-form fallback.
2. Required title, price, German city, category, condition, description, and photos.
3. Pick and compress images with the existing dependencies.
4. Upload through existing Supabase storage policies.
5. Create/reuse the current seller identity and insert the listing through the existing moderated write path.
6. Server-authoritative result is `pending_review`; never auto-approve.
7. Show draft, submitting, pending, rejected-with-reason, and approved states.

### Moderation

1. Add a minimal role-restricted review queue.
2. Show listing content, photos, category, city, price, and seller kind.
3. Approve/reject through server-authorized functions or policies.
4. Require a rejection reason.
5. Notify the seller and expose the resulting listing state.
6. Verify that approval makes a listing publicly queryable in realtime or on refresh.

## 3. Username and own-profile foundation

Start only after the Sell/moderation slice is operational.

1. Extend `public.profiles`; do not create a second user table.
2. Add username, German city, and optional bio while retaining existing display name.
3. Enforce case-insensitive uniqueness, syntax/length rules, reserved names, and
   anti-impersonation rules in PostgreSQL; treat client availability checks as advisory.
4. Reuse the `avatars` bucket, but first replace/review its auth-UUID-based public path
   contract so public avatar delivery does not expose an auth identifier.
5. Make `public.profiles` the public identity source of truth while keeping email, phone,
   preferences, consent, auth metadata, and sensitive verification data private.
6. Expand Account into My Profile, my listings, favorites, messages, recent views,
   settings, and edit profile using existing components and destinations.
7. Test profile editing, normalized conflicts, avatar replace/delete, privacy boundaries,
   loading/error/offline states, all five locales, RTL, and route-independent state.

## 4. Public user profiles

1. Add the typed `/profile/:username` route while preserving `/sellers/:sellerId` for
   the distinct linked seller/store identity.
2. Add a public-safe view or RPC that omits auth UUIDs and returns only avatar delivery
   data, display name, username, city, bio, relevant seller type/verification, and
   active/approved listings.
3. Never expose draft, `pending_review`, rejected, blocked, or owner-only listing data.
4. Reuse the existing product-detail and listing-card components.
5. Route “Nachricht senden” through the existing `chats`/`messages` system. Because
   `get_or_create_chat` currently requires an approved seller, design and review a
   compatible extension for profiles without seller rows rather than adding another
   messaging model.
6. Test anonymous/authenticated visibility, profile/listing privacy, typed routing, and
   existing-chat reuse.

## 5. Dedicated Map route

Start after public profiles.

1. Add `/map` as a typed full-screen route, not a sixth tab or embedded results toggle.
2. Enter from map actions on Home search and Categories/Search app bars.
3. Use permission-gated viewer GPS only as the transient center, with manual German-city
   fallback; never persist viewer GPS to listings or profiles.
4. Offer 5/10/20/30/50/100 km and `Alle`, clustered markers, listing previews, the
   existing product-detail route, and shared category/condition/price filters.
5. Reuse `public.products.latitude`/`longitude`, `products_location_idx`,
   `marketplace_distance_km`, and `search_marketplace_products`; do not create
   `public.listings`, duplicate `city_lat`/`city_lng`, or a disconnected search path.
6. Add a reviewed canonical German-city reference source and a server-authoritative
   submission contract that stores a stable, jittered centroid for private listings.
   Close the current coordinate-write privilege gap before populating map points.
7. Extend/version the radius RPC to return only effective safe marker coordinates,
   enforce active/approved and explicit-DE eligibility, and support the shared filters.
8. Add optional precise public business coordinates only for verified business sellers
   who explicitly opt in; never derive these from private/legal address data.
9. Add pinned map/location dependencies only when implementation begins, then test
   permission denial, manual fallback, clustering, radii, privacy, RTL, and simulator UI.

## 6. Discovery consistency

- Route Home and Categories search controls to a real Search screen.
- Reuse existing search and suggestion RPCs.
- Preserve server-side filtering, pagination, empty/error/offline states, and Germany-only eligibility.
- Add a Favorites destination.
- Replace Home's local favorite set with the account-scoped persistent favorite controller.

## 7. Partial-feature completion

1. Notification inbox, device registration, and push delivery respecting preferences.
2. Seller banner, hours, directions, and explicitly approved public contact information.
3. Kurdish support for database-localized content and full-route Kurdish QA.
4. Connectivity-driven offline and recovery behavior.
5. Operational data-export and deletion processors behind existing request UI.

## 8. Release readiness

1. Android production signing.
2. Export launcher assets from the approved icon source and verify all targets.
3. Final German legal/operator content.
4. Product deep-link handling on Android and iOS.
5. Real project README and operational setup documentation.
6. Crash monitoring, performance QA, privacy/security review, and store metadata.

## Acceptance rules for every increment

- Reuse the existing Riverpod/repository/router/design-system architecture.
- Extend existing migrations; never recreate or drop schema objects casually.
- Keep public private-seller location city-only and require explicit German eligibility.
- Keep chat realtime; do not add polling.
- Keep all five ARBs symmetric and preserve Kurdish framework delegates.
- Run targeted tests, full unit/widget tests, analyzer, and `git diff --check`.
- Exercise completed screens on a real iOS simulator in light/dark and relevant RTL/LTR locales.
- Update `docs/STATUS.md` with commands and observed results, not intended behavior.
