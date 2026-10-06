# Zêrîn — Canonical Product Scope

**Status:** Authoritative. This document supersedes every earlier business-store,
cart, checkout, orders, payment, and Stripe scope.

Deferred Profile/Map detail and schema reconciliation:
[`../zerin-addendum-profile-and-map.md`](../zerin-addendum-profile-and-map.md).

## 1. Product model

Zêrîn is a Germany-only unified listing marketplace for both private individuals
and business sellers. Both seller kinds use the same listing flow and the same
manual moderation lifecycle.

- Every submitted listing starts as `pending_review`.
- Sellers cannot publish or approve their own listings.
- An approved listing becomes publicly discoverable.
- Buyer–seller contact happens only through Zêrîn's in-app chat.
- The app does not broker a product payment or complete an order.

## 2. Explicitly out of scope

Do not build or restore any of the following unless this contract is explicitly
revised:

- cart or cart tab;
- checkout or order confirmation;
- buyer/seller order management, returns, invoices, or fulfilment workflows;
- product payments or payment-method selection;
- Stripe, Stripe Connect, commissions, payouts, or payment webhooks;
- a separate partner-store onboarding flow;
- a Stores browse tab that replaces the unified seller/listing model;
- WhatsApp, phone, or other off-platform ordering actions.

Historical commerce tables and enums may remain in the database until a
separate, reviewed cleanup migration is approved. New Flutter features must not
depend on or extend those historical objects.

## 3. Primary user flow

1. Browse Home, categories, search results, seller profiles, and approved listings.
2. Sign in before protected actions.
3. Contact a seller through a product-linked in-app conversation.
4. Create a listing through the unified Sell flow.
5. Submit it for manual review as `pending_review`.
6. An administrator approves or rejects it with a reason.
7. Approved listings become public; the seller receives the decision in Zêrîn.

## 4. Navigation

The shell has exactly five destinations:

1. **Home**
2. **Categories**
3. **Sell** — elevated center FAB-style destination
4. **Chat** — inbox with unread-count badge; authentication required
5. **Account**

Sell is also authentication-gated. Chat remains routable as `/inbox`, and an
individual conversation remains `/chat/:chatId`.

## 5. Listings and moderation

The unified Sell flow supports catalog-template selection or free-form entry.
A submission requires:

- title;
- price;
- German city;
- category;
- condition;
- description;
- photos.

Photos use the existing image tooling and Supabase storage policies. Location
shown publicly is city-level only. Existing moderation enums, triggers, RLS,
and status transitions must be reused rather than recreated.

The minimum admin workflow is a role-restricted review queue showing listing
content and seller kind, with approve/reject actions and a rejection reason.
Security and role enforcement belong in PostgreSQL/RLS/RPCs, not only in the UI.

## 6. Discovery and engagement

- Home presents campaigns, categories, new listings, deals, and sellers.
- Categories support subcategories, filtering, sorting, list/grid display, and pagination.
- Search uses the existing server-side search/suggestion functions.
- Favorites are persistent and account-scoped on every surface.
- Seller profiles may show public identity, cover image, bio, city, opening hours,
  directions, rating, and approved public contact information, but never private details.
- Reports and moderation remain in-app.
- Notifications may use an inbox and push delivery, respecting stored preferences.

## 7. User and seller profiles

Every authenticated account has a public-safe identity in the existing
`public.profiles` model: avatar, display name, unique case-insensitive username,
German city, and optional bio. PostgreSQL enforces username uniqueness, syntax,
reserved names, and conflict handling. Email, auth UUIDs, phone, account settings,
residential addresses, and sensitive verification data are never public profile data.

- Public user route: `/profile/:username`.
- Public user profiles show only public-safe identity and active/approved listings.
- Draft, pending, rejected, blocked, and private account data remain owner/admin-only.
- The Account destination expands into My Profile, my listings, favorites, messages,
  recent views, settings, and edit profile; it does not become another shell tab.
- User/person identity and seller/store identity remain distinct but linked.
  `/sellers/:sellerId` remains the seller/store route.
- “Nachricht senden” reuses the existing chat tables and path. Universal profile
  messaging may extend that model but must not create a second messaging system.
- Reuse the existing `avatars` bucket with a reviewed delivery/path contract that does
  not expose an auth identifier.

## 8. Dedicated Map route

Map is a deferred full-screen route at `/map`, entered from map actions on Home search
and the Categories/Search app bar. It is not embedded as a search toggle and is not a
sixth shell destination.

- Viewer center defaults to permission-gated live GPS with a manual German-city
  fallback. Viewer GPS is never persisted to a profile, seller, or listing.
- Radius choices are 5/10/20/30/50/100 km and `Alle`; filtering remains server-side.
- Map uses clustered markers, a listing-preview bottom sheet, and the existing product
  detail route.
- Category, condition, and price filters are shared with search/category discovery.
- A private listing's map point is a server-derived city centroid with stable
  privacy-preserving jitter, never a residential address or listing author's GPS.
- A verified business may explicitly opt into a precise public business point.
- In this repository “listing” means `public.products`: reuse its existing
  `latitude`/`longitude`, distance function, and radius-search RPC rather than creating
  `public.listings` or duplicate coordinate columns. Public map queries expose only the
  effective safe point.

## 9. Geography and privacy

- The marketplace is Germany-only.
- Seller and product country eligibility must be explicit; never infer it from
  free-form city, tax data, address data, shipping destinations, or coordinate bounds.
- Private user/seller location is city-level in every public response.
- RLS, column privileges, and public-safe projections/RPCs are the source of truth for
  data exposure; client-side omission is not a privacy boundary.

## 10. Localization

Supported locales are `de` (default), `en`, `ar`, `tr`, and `ku`.

- Arabic is RTL.
- Kurdish is Kurmanji in Latin script and LTR.
- ARB keys remain symmetric across all five locales.
- Flutter has no built-in Material/Cupertino localization for `ku`; the custom
  delegates in `lib/l10n/ku_localizations.dart` must remain registered before
  Flutter's global delegates.
- Database-facing localized content must ultimately support Kurdish rather than
  silently treating German fallback as completion.

## 11. Legal and account controls

Account keeps `Impressum`, `AGB`, `Datenschutzerklärung`, and
`Widerrufsbelehrung` reachable within two taps. DSGVO controls include consent,
data export, account deletion, and deletion cancellation. A visible request UI
is not considered complete until its asynchronous processor is operational.
The pre-launch legal review includes directory review transparency under UWG: explain
who may review, the one-review-per-place rule, moderation, and that actual visits are
not verified.

## 12. Locked implementation rules

- Package imports use `package:zerin_marketplace/...`.
- Reuse Riverpod providers, repository interfaces, typed `go_router` routes,
  Supabase bootstrap, and existing migrations.
- Config remains compile-time `--dart-define`; no-key builds degrade gracefully.
- Extend existing SQL objects; never recreate or drop objects without a reviewed migration.
- Reuse `lib/core/theme/theme.dart` and `lib/core/widgets/widgets.dart`.
- Do not introduce new colors, spacing, radii, durations, or duplicate shared widgets.
- Every completed screen includes loading, empty, error, and offline behavior
  where applicable, minimum 44 px targets, semantics, keyboard handling, dark
  mode, RTL, and real-device/simulator acceptance.
- Update `docs/STATUS.md` after every completed increment.
