# Zêrîn — Step E: Business Directory (Restaurants, Cafés, Doctors)
### Put this file in docs/plans/. Build in three sub-steps (E1, E2, E3). Stop after EACH sub-step with a closeout report and wait for confirmation.

---

## Product decisions (locked)
1. **Owners register themselves.** A directory entry belongs to a verified business
   seller (`sellers.kind = 'business'`, `is_verified_seller() = true`). No admin-created
   entries, no claim flow.
   *Amended by Step E1.5 (2026-09-27):* unclaimed OpenStreetMap places are imported into
   a separate table and shown as unverified; an admin can link one to a business seller
   (`claimed`). Owner profiles themselves are unchanged.
2. **Ratings for restaurants and cafés only.** Doctors can never be rated — enforced
   server-side, not just hidden in the UI.
3. **Structured menu** (sections + items with prices) for restaurants and cafés only.

## Core idea: extend, don't duplicate
A restaurant, café or practice IS a verified business seller. Reuse what exists:
seller verification + admin queue, precise map pin (Step D), seller profile page,
buyer↔seller chat (`get_or_create_chat`), reports (`reports.seller_id` / `review_id`),
notifications. The directory adds a 1:1 extension of `sellers`, not a new identity.

## Standing rules (unchanged)
- Docker Desktop only, never Colima; never `supabase db reset`.
- **Audit first**: read the live schema before writing anything. In particular the
  existing `reviews` table (columns, constraints, RLS, what it currently targets) and
  `sellers.rating_average` / `rating_count`. Reuse them if they fit; if they are
  product-only, explain and propose before changing them.
- New migrations via psql, listed in the STATUS.md migration-ledger caveat, each with
  a transaction-scoped SQL acceptance test that creates its own fixture users in
  `auth.users` (never depend on the real step-b-ios accounts).
- No hardcoded UI strings — all five ARB files (de, ku, en, ar, tr). Arabic RTL.
- Properly formatted Dart, small widgets, typed exceptions, no empty catch blocks,
  explicit `rpc<T>` types.
- Evidence under `docs/evidence/step-e1|e2|e3/`, never /tmp.

---

## E1 — Schema, rules and server contracts (no UI)

**Directory profile** (1:1 with a business seller):
- `type`: restaurant | cafe | doctor (enum).
- Common: description, phone, optional website, cover image (existing storage
  conventions), **languages spoken** (e.g. Kurdî, Arabic, Turkish, German, English —
  high value for this community), `is_published`.
- Restaurant/café: cuisines (fixed list incl. kurdisch, syrisch, türkisch, arabisch,
  persisch, deutsch, italienisch, …), `price_level` 1–4, dietary flags on the
  business (halal, vegetarian options, vegan options).
- Doctor: specialty (Fachrichtung, fixed list), insurance accepted
  (gesetzlich / privat / beide).
- Enforce type-specific fields with CHECK constraints (e.g. doctors cannot have
  cuisines or price_level).

**Opening hours**: structured weekly schedule, multiple intervals per day, closed
days, interpreted in Europe/Berlin. "Open now" is computed **server-side**.

**Menu** (restaurant/café only, enforced server-side): sections (name, sort order)
and items (name, optional description, `price_cents`, available flag, dietary tags
halal/vegetarian/vegan). Owner-only writes via RLS. No item photos in v1.

**Reviews**: 1–5 stars + optional text, one review per user per business (editable),
owner cannot review their own business, **impossible for type = doctor** (server-side
guard), aggregate rating kept consistent. Reviews stay reportable via the existing
`reports.review_id`.

**Publication rule**: a directory profile is publicly visible only when
`is_published = true` AND `is_verified_seller(seller_id) = true`. Losing verification
hides it automatically.

**Doctor verification — STOP AND ASK, do not change silently:**
`is_verified_seller()` requires an approved `business_registration` document, but
doctors are a freie Beruf and usually have no Gewerbeanmeldung. Audit this and propose
how a practice can be verified (e.g. which `seller_document_kind` counts as
professional proof) before touching `is_verified_seller()`.

**RPCs**: public directory search (type, radius — reuse the Step D distance pattern —
cuisine, price level, min rating (never for doctors), open now, spoken language,
paging); public directory detail (profile + hours + open-now + menu + rating summary);
owner upserts for profile, hours and menu; review upsert/delete. Public projections
must never expose private seller fields.

**E1 done when**: migration applied, acceptance test passes to ROLLBACK (including:
doctor review rejected, doctor menu rejected, unverified business hidden, owner
self-review rejected, open-now correct across midnight intervals), Step B/C/D and admin
SQL tests still pass, `flutter analyze` + `flutter test` still green. Stop and report.

---

## E2 — Owner side ("Mein Unternehmen")
- **0. Seller document upload (added 2026-09-27).** Without it no business or doctor can
  ever be verified and the admin queue never receives anything. The seller picks the
  directory type first, then sees exactly the documents that type needs (identity +
  business_registration, or identity + medical_professional_registration for doctors),
  uploads each as image or PDF to the private `seller-documents` bucket, and sees each
  document's status and any rejection note. Reuses the existing storage policies and the
  admin verification queue. Server support: a declared `sellers.directory_type` before any
  profile exists, and approving the last required document of a pending directory seller
  approves the seller (directory sellers never get a listing approved).
- Entry in Account, visible only to business sellers; if not yet verified, show the
  path to the existing verification flow instead of the editor.
- Editors: directory profile (type-aware fields), opening hours (weekly editor with
  multiple intervals), menu (sections + items: create, edit, reorder, delete,
  availability toggle) — menu editor only for restaurant/café.
- Publish/unpublish toggle.
- Tests + real iOS screenshots of each editor. Stop and report.

---

### Private sellers and the directory (decision 2026-09-27)
- Users who already have a seller (in particular a private seller) are refused by
  `owner_start_directory`; nothing else is built in E2.
- **Step F — account switching (option D), after E2, only once the Step F brief arrives:**
  one login, up to one private and one business seller per user; private listings always
  stay under the private identity, so no relabeling of existing listings is needed.

## E3 — Public discovery
- New route `/directory` (NOT a new bottom tab), entered from a Home section with
  four chips: Restaurants, Cafés, Imbiss, Ärzte.
- **Default type set (decision 2026-09-27):** the directory shows restaurants and cafés
  together by default. `fast_food` is *not* in the default list; it appears only through
  a separate "Imbiss" filter chip, because it is 837 of the 1123 imported places and
  would otherwise dominate the list. Doctors stay behind the "Ärzte" chip.
  - Server gap to close in E3: `search_business_directory` filters by a single
    `p_type`. Add a type-set filter (e.g. `p_types directory_business_type[]`, keeping
    `p_type` for compatibility) so the default {restaurant, cafe} is one paged query
    with a correct `total_count` — never merge two paged calls client-side.
  - Chip label: new ARB key (e.g. `directoryTypeFastFood`), de "Imbiss", in all five
    locales.
- List cards: cover, name, type, cuisine or specialty, rating (restaurants/cafés only),
  distance, open-now badge, spoken languages.
- Filters: reuse the existing filter bottom-sheet pattern; rating filter hidden for
  doctors.
- Detail screen: header, info, opening hours with open-now, call button (`tel:` via
  url_launcher), directions (existing Step D logic), menu (restaurant/café), reviews
  with write/edit own review (restaurant/café only), "Nachricht senden" into existing
  chat.
- Near the rating, a short localized note that reviews come from registered users and
  are not verified as actual visits (transparency about review verification).
- Admin: for reports targeting a review, add a "remove review" action to the existing
  reports queue (today review reports can only be dismissed).
- **Unclaimed OSM entries (from Step E1.5) — requirements:**
  - Data contract: `search_business_directory` items with `source = 'osm'` and
    `is_claimed = false` carry `place_id` (no `seller_id`); open them with
    `get_directory_imported_place_detail(place_id)`. Owner entries keep
    `get_business_directory_detail(seller_id)`. Branch on `source`, never on null ids.
  - List card and detail header show the localized note `directoryUnverifiedOsmNote`
    („Nicht verifiziert · Daten © OpenStreetMap-Mitwirkende“), all five locales.
  - No verified badge, no rating/review UI (list and detail, `reviews_enabled = false`),
    no menu section, no "Nachricht senden"/chat button, no description block.
  - Allowed: call (`phone`), website, directions (coordinates are always present),
    cuisines, halal/vegetarian/vegan only when the value is `true` (null = unknown,
    never shown as "no"), opening hours.
  - Opening hours: when `has_hours = false`, show "hours unknown" — never "closed";
    the open-now badge is shown only when `has_hours = true`.
  - Cover: use the type's placeholder image (`cover_image_path` is null).
  - Filters: rating, price level and spoken language exclude imports server-side; the
    UI must not imply imports were filtered out for any other reason.
  - `fast_food` entries are reachable only via the "Imbiss" chip (see default type set);
    new cuisines `lebanese`, `iraqi`, `middle_eastern`, `kebab`, `falafel` need labels.
- Tests + real iOS screenshots: directory list, filters, restaurant detail with menu,
  doctor detail (no rating UI), review submission, and one unclaimed OSM detail page
  showing the unverified/attribution note. Stop and report.

## Out of scope for Step E
Table reservations, appointment booking, online ordering/payment, menu item photos,
showing directory places as a separate map layer, events, jobs, travel.
