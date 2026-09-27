# Zêrîn — Addendum: Map + User Profile System
### Paste into Claude Code alongside `master-prompt-zerin-final.md` and `zerin-scope-resolution-next-steps.md`

> Naming note: an earlier draft used the name **DÛKAN** for this feature spec. The locked
> brand name for this project is **Zêrîn** (brand board + app icon already exist under
> that name). Everywhere below, "Zêrîn" is the app. If you actually want to rename the
> whole app to DÛKAN, say so explicitly — that's a bigger decision (new icon, new brand
> board, new bundle IDs) and shouldn't happen as a side effect of a profile-system spec.

---

## Repository reconciliation (binding implementation notes)

The requirements below are accepted, but their generic schema names must be mapped to
this repository before implementation. Where a later section says `listings`, it means
**`public.products`**. Do not create `public.listings` or duplicate existing objects.
These notes take precedence over generic schema suggestions in this addendum.

### Existing map/location foundation

- `public.products` already has `city`, `postal_code`, `latitude`, and `longitude`.
  Reuse `latitude`/`longitude` as the listing's privacy-safe map point; do not add
  parallel `city_lat`/`city_lng` columns.
- Phase 2 already provides `products_location_idx`,
  `marketplace_distance_km(...)`, and `search_marketplace_products(...)` with
  `p_latitude`, `p_longitude`, and `p_radius_km`. Radius filtering is therefore
  already server-side. Extend or version that RPC for map marker output and shared
  filters rather than introducing a second disconnected `listings_within_radius`
  contract. Its current result includes distance but not marker coordinates.
- No `public.german_cities` reference table exists. Add it only through a reviewed
  migration as the canonical, server-owned source for the existing German-city picker
  and centroid lookup; do not trust coordinates submitted by a client. Seed provenance,
  normalization/aliases, and update procedure must be documented.
- A server-authoritative submission path must derive a stable city-centroid point and
  apply privacy-preserving jitter for private listings. Device GPS, residential
  addresses, and user-supplied latitude/longitude must never be written to a private
  listing. Jitter must be generated on the server and remain stable instead of changing
  on each read.
- The current moderation migration describes postal/coordinate fields as quarantined,
  but the effective table grants/RLS do not by themselves enforce derived-only writes.
  Map/Sell implementation must close that gap with reviewed RPC/trigger and privilege
  rules before coordinates are populated.
- `public.sellers` has no public `latitude`, `longitude`, or `address_line` fields.
  Adding an opt-in precise public business location is deferred to the Map migration and
  must require `kind = 'business'`, approved verification, and explicit opt-in. Keep
  legal/residential data in `seller_private_details` private. The map RPC may use the
  verified business point; private sellers always use the listing's safe city point.
- Public map data must expose only the effective safe marker point, never `postal_code`,
  legal addresses, or raw private inputs. The future RPC/projection must also enforce
  active/approved status and explicit Germany eligibility. `Alle` maps to a null radius,
  while the confirmed 5/10/20/30/50/100 km choices fit the existing RPC validation.

### Existing profile/storage/chat foundation

- Extend **`public.profiles`**; never create another user table. It already stores
  `display_name` and `avatar_path`, alongside private `phone`, preferences, consent, and
  settings fields. It does not yet have `username`, profile `city`, or profile `bio`.
- Profiles are currently selectable only by their owner/admin. Add a public-safe
  view or RPC keyed by normalized username that returns only avatar delivery data,
  display name, username, city, bio, relevant seller type/verification, and active
  listings. Do not make the mixed private `profiles` row broadly readable, and do not
  return the auth UUID, email, phone, preferences, consent, or verification documents.
- Enforce normalized case-insensitive username uniqueness, syntax/length rules, and
  reserved-name/impersonation protection in PostgreSQL. Client availability checks are
  advisory; the save operation must handle a database conflict atomically.
- The existing `avatars` bucket is public WebP storage and owner writes are scoped to
  `<auth-user-id>/<uuid>.webp`. A public profile URL using that path would expose an auth
  identifier, contrary to this addendum. Before profile implementation, choose and
  review an opaque public-key or controlled-delivery design while reusing the `avatars`
  bucket; do not expose `avatar_path` directly from the public profile contract.
- `public.sellers.user_id` already links at most one private/business seller identity to
  its underlying user profile. Keep `/sellers/:sellerId` for seller/store identity and
  add `/profile/:username` for person identity; neither replaces the other.
- `get_or_create_chat(p_seller_id, p_product_id, p_buyer_id)` currently requires an
  approved linked seller and models buyer/seller participants. Therefore a profile
  message action already works only for profiles with an approved seller identity. For
  universal profile messaging, carefully extend the existing `chats`/`messages` model
  and RPC after Sell/moderation—do not add a second messaging system or guess that every
  profile already has a seller row.
- Auth metadata currently seeds `profiles.display_name`; after profile work,
  `public.profiles` is the public identity source of truth. Auth email and metadata stay
  private.

No Map/Profile migration or Flutter implementation is authorized by this reconciliation
alone. Build order remains Sell → moderation → username/profile → public profile → Map,
and linked remote migration parity must be reviewed before any push.

---

## 1. Map — dedicated full-screen screen, eBay-Kleinanzeigen style (confirmed)

**Confirmed model: a separate, dedicated map screen — not a toggle embedded inside
Categories/Search results.**

- **Entry point:** a map icon button on Home's search bar and on the Categories/Search
  results app bar → opens `/map` as its own full-screen route. This is a **route, not a
  6th bottom-nav tab** — the existing 5-tab structure (Home/Categories/Sell/Chat/Account)
  stays exactly as decided.
- **Center point:** defaults to the user's current GPS location (permission prompt with
  German privacy-friendly copy; falls back to letting them manually pick/search a city if
  denied or unavailable). A search field lets them re-center on a different city anytime.
- **Radius filter — the core interaction, like Kleinanzeigen:** a horizontal chip row or
  dropdown with **5 km / 10 km / 20 km / 30 km / 50 km / 100 km / Alle** (no limit).
  Changing the radius live-filters the visible pins around the center point.
- **Pins:** clustered markers; tap a cluster/pin → bottom-sheet preview card (photo,
  title, price, city, condition); tap the preview → the same listing detail screen used
  everywhere else (no duplicate detail screen just for map-originated taps).
- The existing filter bottom sheet (category, condition, price) should also be reachable
  from this screen, so the map isn't a second, disconnected search experience — same
  filters, different visualization.

### 1.1 Privacy-consistent distance calculation
Radius search needs *some* coordinate to filter against, but this must not leak a private
seller's exact address — the existing "city-only, no district/PLZ" decision doesn't
change because of this feature.

- Add a static reference table `public.german_cities (name text primary key, latitude
  numeric, longitude numeric)`, seeded once from a documented standard German city
  dataset — never from user-submitted coordinates.
- When a listing's city is selected through the shared city picker, resolve it on the
  server and store the privacy-safe point in the existing `public.products.latitude` /
  `longitude` columns — do not add duplicate coordinate columns.
- For private-seller listings, apply a stable server-generated jitter (roughly
  ±300–500 m) to the centroid so listings in the same city do not stack on one point and
  never imply more precision than "somewhere in this city."
- Verified business sellers may explicitly opt into their real public business point
  instead (§1.3); legal/residential address data is never a fallback map source.
- The "within X km" filter extends the existing server-side
  `search_marketplace_products` radius contract. A viewer's device location is only a
  transient center parameter and is never written to a product, seller, or profile.

### 1.2 Schema and RPC mapping
- `public.products`: reuse `latitude numeric` and `longitude numeric` for the effective
  privacy-safe listing point; keep `postal_code` out of public map projections.
- New canonical reference: `public.german_cities (name text primary key, latitude
  numeric, longitude numeric)` with server-owned seed/normalization rules.
- Existing RPC: extend or version `search_marketplace_products(..., p_latitude,
  p_longitude, p_radius_km, ...existing filter params)` to return safe marker points and
  preserve server-side distance filtering. Do not add `public.listings` or a separate,
  disconnected `listings_within_radius` API.

### 1.3 Store precise pins (unchanged product requirement, mapped to this schema)
- `public.sellers` business rows may gain nullable public `latitude`, `longitude`, and
  `address_line` fields plus an explicit opt-in state. PostgreSQL must allow a populated
  precise point only for verified, approved business sellers that opted in.
- Precise fields remain null for private seller rows. Their products rely entirely on
  the stable jittered city point in `public.products.latitude`/`longitude`.

### 1.4 Suggested packages
- `flutter_map` + OpenStreetMap tiles for rendering (no API key friction, no per-request
  billing — fits a lean classifieds app; revisit `google_maps_flutter` only if OSM's
  German geocoding/search quality proves insufficient in testing)
- `geolocator` for reading the viewer's current device location (permission-gated, with
  the manual-city fallback from §1 above)

---

## 2. User Profile System

Every authenticated user gets a public-facing profile identity, separate from the
technical auth account. This applies to **everyone** — private sellers and business
accounts both have an underlying user profile (§3 keeps the concepts distinct).

### 2.1 Profile photo
- Upload from camera or photo library
- Supabase Storage (`avatars` bucket, already exists) with secure policies
- Support: upload, replace, delete, cached display, loading state, fallback avatar
- Don't expose private storage paths directly — use signed/public URLs per the existing
  storage policy pattern already used for other buckets

### 2.2 Display name
- Free text, shown throughout the app wherever a user/seller identity appears (listing
  cards, chat, listing detail seller card)

### 2.3 Username
- Unique, **case-insensitive** uniqueness, safe-character validation, reasonable length
  limits, cannot contain reserved system names, cannot impersonate verified
  businesses/admins, editable subject to availability
- Never use the user's email as their public identity
- Used for: profile URL, future mentions, future profile sharing, internal identity

### 2.4 City
- Same German-city field/picker already used for listings (§6.5 of the base master
  prompt) — reuse it, don't build a second location picker
- Public profile location stays city-level. Never show a private residential address for
  a private user (this matches §1 above).

### 2.5 Bio
- Optional short "Über mich" text, length-validated, no hardcoded copy (goes through ARB
  localization like everything else)

### 2.6 Public profile
- Route: `/profile/:username` (typed route via `go_router_builder`, matching the existing
  router pattern)
- Shows: photo, display name, @username, city, bio, seller type where relevant,
  verification state where relevant, **active/approved listings only**, basic stats (e.g.
  listing count)
- **Never show** draft / pending_review / rejected / blocked listings on a public profile
  — only to the owner, in their own private dashboard, per the existing authorization
  model
- From a public profile, "Nachricht senden" opens the existing chat — reuse
  `get_or_create_chat`, don't build a second chat path

### 2.7 My Profile (authenticated own view)
Sections: profile header, my listings, favorites, messages, recently viewed, settings,
edit profile. Reuse existing navigation/components — this isn't a new tab, it's what the
Account tab becomes/expands into.

### 2.8 Edit profile
- Fields: photo, display name, username, city, bio
- Username availability check must be safe against enumeration/race conditions
  (uniqueness constraint at the DB level, not just client-side check)
- Save flow: loading state, success state, inline validation errors, conflict handling
  (e.g. username taken between check and save)

### 2.9 Privacy boundary
**Public via profile queries:** photo, display name, username, city, bio, public listings.
**Never exposed via public profile queries:** email, auth identifiers, private account
metadata, sensitive seller verification data. Enforce with Supabase RLS + column-scoped
queries — don't rely on the client to simply not display fields it technically received.

### 2.10 Database
- Inspect the current `profiles` table first — **do not create a second user table.**
- If `username` doesn't exist: add it via migration with a unique index, case-insensitive
  uniqueness (e.g. a `citext` column or a unique index on `lower(username)`), validation
  constraint, and RLS updated so public reads only get the public-safe column set (view
  or column grants — pick whichever the existing RLS pattern already uses elsewhere).

### 2.11 Business vs. private profile — keep distinct
- **User profile:** person, avatar, @username, city, bio
- **Business/store profile:** store name, logo, verification, store info, city
  (+ optional precise address per §1), business listings
- A business account still has an underlying user profile — don't duplicate identity data
  between the two; the store profile references the owning user profile.

### 2.12 Localization
German, Kurdish (first-class, not an afterthought), English, Arabic (RTL), Turkish — same
five locales as the rest of the app. No hardcoded production strings.

### 2.13 Design
Use the existing Zêrîn tokens (petrol surfaces, restrained gold, Bricolage/Figtree type,
existing spacing/radius/elevation) — see `master-prompt-zerin-final.md` §3. The profile
should feel elegant and personal, not like a generic social-media clone.

### 2.14 Testing
Cover: profile loading, username uniqueness, case-insensitive username conflicts, profile
editing, avatar upload flow, privacy rules, public listing visibility, route generation.

Run: `flutter analyze`, `flutter test`,
`flutter run --dart-define-from-file=dart_defines.json`, validate on the iOS simulator —
same working rule as the rest of the project (real simulator screenshots, not a static
render).

### 2.15 Acceptance criteria
A user must be able to: create an account, choose a display name, choose a unique
@username, upload a profile photo, choose a German city, add an optional bio, view their
own profile, edit their profile, view public profiles of others, see public listings on
those profiles, see profile identity consistently across the app (listing cards, chat,
listing detail), and have their email/address/private data stay private.

Integrates with: listings, seller identity, chat, favorites, account, moderation, and
future verification — without duplicating any of those systems.

---

## 3. Where this fits in the build order

This is a **Step B/C-level feature**, not urgent infrastructure — it makes sense right
after the Sell flow + moderation panel (Step B in `zerin-scope-resolution-next-steps.md`),
since listings need an owner identity to point to anyway. Suggested order:
Sell flow → Moderation panel → **Username/profile** → public profile page → map view.
Don't build the map before profiles exist, since store map pins pull from the business
profile record.
