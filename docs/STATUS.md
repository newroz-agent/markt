# Zêrîn Project Status

Updated: 2026-09-28 — pre-Step F handoff remediation and regression audit
Canonical product contract: `docs/SCOPE.md`

> Step D evidence note (2026-09-22). The migration
> `supabase/migrations/20260920000100_step_d_map.sql` and the acceptance
> `supabase/tests/step_d_map.sql` are present and end in `commit`/`rollback`
> with assertion-driven checks. The four items below marked ✅ are confirmed
> from the committed files or the local worktree. The two items marked ⚠️
> could not be re-confirmed in this session: a live local Supabase was not
> reachable, and the Step D screenshot directory
> `/tmp/zerin-step-d-ios-screenshots/` did not exist at closeout. They are
> retained verbatim from the Step D driver/ledger as the intended evidence,
> but their present-tense validity is unverified here.

Status rule: `✅ done` means implemented and covered by current evidence; `🟡 partial`
means a working slice exists but named acceptance remains; `❌ missing` means no
operational implementation. Out-of-scope historical SQL is not counted as product work.

## Pre-Step F handoff remediation (2026-09-28)

- ✅ `20260927000800_precise_location_gaps.sql` applied exactly once to the local
  effective schema via direct `psql`; its acceptance test passed exactly once through
  `ROLLBACK`. It remains intentionally absent from `schema_migrations` pending the
  migration-ledger repair required before any remote push.
- ✅ The exact unreferenced Step B object listed below was deleted once through the local
  Storage service with the local service role; post-check: 0 objects, 0 image rows,
  0 listings at that path.
- 🟡 The one approved Step B iPhone rerun proved cleanup count parity (`33` listings,
  `32` image rows, `2` Storage objects both before and after; one listing/object removed)
  and produced six PASS screenshots under `docs/evidence/step-b/`. The functional test
  stopped before approval/publication because an obsolete viewport assertion required
  the approve-button center below 800 px but measured 818 px. The harness now checks
  actual hit-testability instead; no second live run was made under the one-run limit.
- ✅ Final integrated Flutter gate: `flutter analyze --no-pub` — `No issues found!`
  (4.4s); `flutter test --no-pub` — `00:41 +293: All tests passed!` (293/293).
- 🟡 Twelve current transaction-scoped SQL suites were each run once across this pass;
  10 passed to `ROLLBACK`. `chat_phase1.sql` has a stale raw buyer-avatar expectation
  that conflicts with Step C's opaque-avatar projection. `phase3_country_moderation.sql`
  still attempts a direct authenticated product insert that Step B intentionally
  revoked. The legacy `phase3_country_upgrade.sql` is a pre-008, migration-applying
  probe without `ROLLBACK` and was correctly excluded from the live current-schema gate.

## Rating decision (2026-09-27)

- ✅ Decision: directory and purchase ratings are **never blended**. The directory rating
  (`business_directory_profiles.rating_average/rating_count`) counts only
  `context = 'directory'` reviews and is what directory search/detail return; the seller
  rating (`sellers.rating_*`) counts only `context = 'purchase'` reviews. Purchase reviews
  can no longer be created (checkout was removed). Owners cannot write their directory
  rating (trigger resets it for non-admin callers).
- ✅ Implemented in `20260927000600_directory_rating_separate.sql`, applied 2026-09-27 via
  psql after approval (0 existing rows changed). The E1 acceptance test now expects seller
  5/1 (purchase) and directory 4/1 → 0/0 after the soft delete, instead of the blended
  4.5/2. All SQL suites pass on the live schema
  (`docs/evidence/step-e2/regression-after-000600.txt`).

## Step E2 — owner side ("Mein Unternehmen")

- ✅ Item 0 (document upload), hub, profile/hours/menu editors, publish switch, Account
  entry, routes under `/business`, all copy in five ARB files; admin queue now labels
  identity/business-registration documents too. `flutter analyze` clean; `flutter test`
  292/292 (`docs/evidence/step-e2/`).
- ✅ `20260927000700_step_e2_owner_onboarding.sql`, scoped as decided 2026-09-27 and
  nothing broader: (1) `owner_start_directory` creates a PENDING business seller (shop
  name, city, directory type, no listing) only for users without a seller;
  (2) approving the full required set (identity + business_registration, or identity +
  medical_professional_registration for doctors) moves a PENDING BUSINESS seller to
  `approved`, recorded by the existing `record_seller_status_history` trigger with the
  approving admin; (3) private sellers are never auto-approved, rejected/suspended sellers
  never re-opened, the listing-approval path is unchanged; (4) private sellers are refused
  (upgrade options proposed, nothing implemented). Supporting parts:
  `owner_set_directory_type` (business sellers only, never touches status),
  `get_my_directory_onboarding`, declared `sellers.directory_type`, document-path
  hardening, one pending document per kind. `supabase/tests/step_e2_owner_onboarding.sql`
  covers every rule. Dry-run passed with every suite and changed 0 existing rows at apply
  time (`dryrun-e2-migrations.txt`); applied 2026-09-27 after approval. Acceptance and all
  regressions pass on the live schema (`regression-sql-output.txt`).
- ✅ Live iOS evidence: nine 1206×2622 PNGs + `results.json` (9/9 checkpoints, 1/1 test
  PASS) in `docs/evidence/step-e2/ios/` on the iPhone 17 Pro simulator (iOS 26.1) against
  local Supabase, German UI: start, documents rejected/uploaded, admin queue receiving the
  upload, hub, profile (2), hours, menu. Seed `supabase/snippets/step_e2_local_seed.sql`;
  harness `integration_test/step_e2_live_test.dart` + `test_driver/step_e2_driver.dart`.
- 🟡 The hours screenshot shows a truncated overnight label; fixed in code afterwards with a
  widget test, screenshot not refreshed (needs another approved harness run).

## Loose ends before Step F (2026-09-27)

- ✅ Snackbars: `ZerinApp` owns the app-wide `ScaffoldMessenger` and clears it whenever
  the signed-in account changes (sign-in, sign-out, switch); widget test
  `test/app/app_snackbar_reset_test.dart` (mutation-checked). Confirmed live: the refreshed
  admin-queue screenshot no longer shows the doctor's snackbar.
- ✅ E2 orphans: the 3 approved items were deleted (pending row first, then the 3 PDFs via
  the storage service); the doctor's folder is empty and back to the seeded state.
- ✅ Harness cleanup (`integration_test/support/harness_cleanup.dart`), pass or fail:
  E2 removes what it uploaded — re-run 9/9 PASS, 1 upload removed, 0 files left, hours
  screenshot refreshed. The E2 seed refuses to orphan uploaded files.
- 🟡 Step B: the harness itself was out of date (the details list is lazily built since the
  compare-at field; `/moderation` opens on the overview tab since the admin expansion) —
  both fixed. Cleanup now removes photos before deleting the listing and records global
  before/after counts for listings, image rows, and Storage objects. The one approved
  iPhone rerun restored all three counts exactly (`33/32/2` before and after; one listing
  and one object removed), but stopped after six PASS screenshots because the approve
  button center was 818 px while an old assertion required less than 800 px. That
  arbitrary coordinate assertion is now a hit-testability check, but it was not rerun
  under the one-run approval. Partial evidence is in `docs/evidence/step-b/`.
- ✅ The pre-existing unreferenced Step B object
  `8bfc114f-0b44-45dc-9a1f-0e767eb8575d/2ace6666-b043-45b0-b90f-ea9fb8b35c0d/1790545861569718-0.webp`
  was deleted exactly once through the local Storage service with the local service role;
  a read-only post-check returned 0 Storage objects, 0 image rows, and 0 listings.
- ⚠️ Required pre-launch lifecycle fix: ordinary listing deletion currently deletes the
  database row before its protected `product-images` objects, after which Storage RLS
  hides those objects even from the app's admin client. The listing photos then stay in
  Storage forever unless a service-role cleanup removes them. Product deletion must
  remove every listing photo before deleting the row, and account deletion must also
  remove all photos for every listing owned by that account. Harness cleanup does not
  fix the production lifecycle.
- ✅ `20260927000800_precise_location_gaps.sql` was applied once via direct `psql` and
  `supabase/tests/precise_location_gaps.sql` passed once through `ROLLBACK`: suspending
  or rejecting clears the public pin in the same write, and directory profile
  create/delete/type changes run the unverified wipe. The migration remains absent from
  `supabase_migrations.schema_migrations` under the direct-psql ledger caveat.

## Step F — account switching (decided, not started)

- Decision 2026-09-27: option D. One login, up to one private and one business seller per
  user; private listings always stay under the private identity. Built as its own step
  after E2, only after the Step F brief. Until then `owner_start_directory` keeps refusing
  users who already have a seller.

## Step E1.5 — OpenStreetMap restaurant/café import (server side)

- ✅ Checkpoint decisions (2026-09-27): unclaimed places live in a separate
  `directory_imported_places` table (no `sellers` row); `fast_food` is a new directory
  type; `lebanese`, `iraqi`, `middle_eastern`, `kebab`, `falafel` are new cuisines; OSM
  aliases `arab`/`egyptian`/`yemeni`/`yemenese`→arabic, `iranian`→persian,
  `döner`/`shawarma`→kebab, `levantine`/`levante`/`palestinian`/`oriental`→middle_eastern;
  `afghan` excluded; the raw OSM `cuisine` string is kept in `osm_cuisine`.
- ✅ `20260927000300_step_e1_5_directory_enums.sql` (enum values, committed first) and
  `20260927000400_step_e1_5_osm_directory_imports.sql` applied via direct `psql`.
  `fast_food` owner profiles get menu/review parity with restaurant/café; otherwise the
  E1 owner RPCs are unchanged. Imported places, their hours, outreach contacts and the
  suppression list have RLS enabled and **no** `anon`/`authenticated` table grants;
  admins use `admin_set_directory_outreach_status` / `admin_export_directory_outreach_csv`.
- ✅ `search_business_directory` returns owner profiles plus unclaimed, visible imports with
  `source`, `is_claimed`, `place_id`, `reviews_enabled`, `has_hours`; new
  `get_directory_imported_place_detail`. Neither ever returns outreach data. Rating,
  price-level and language filters exclude imports (OSM has no such data).
- ✅ Reviews on imports are rejected in the database (`validate_directory_review_write`,
  SQLSTATE 23514) — proven via `upsert_directory_review` and a direct insert.
- ✅ Import: snapshot `tools/osm/snapshots/berlin-food-2026-09-27.json` (one Overpass
  request, 6915 elements) → `tools/osm/import_berlin_food.dart --apply` (local container
  only). 1123 places: 837 fast_food, 250 restaurant, 36 cafe; 472 with parseable hours
  (92 rejected strings logged), 217 phone, 221 website, 66 OSM email. Second run:
  1123 unchanged, 0 inserted/updated.
- ✅ `supabase/tests/step_e1_5_osm_import.sql` passes to `ROLLBACK` (grants, projections,
  review guard, claim/suppression/re-run, CSV formula guard). E1/B/C/D/D-postal/admin
  regressions pass to `ROLLBACK`; the E1 search assertion now filters by language so it
  counts owner profiles only. `flutter analyze` clean; `flutter test` 275/275.
  Evidence: `docs/evidence/step-e1-5/`.
- ✅ OSM/ODbL attribution tile ("Datenquellen") in the Account legal card, all five ARB files.
- ✅ Deferred by decision (2026-09-27): §4 directory screens and the iOS screenshots move
  to E3, whose plan now lists the unclaimed-entry UI rules as requirements. The
  `directoryUnverifiedOsmNote` string already exists in all five ARB files.
- ✅ Fix: the claim check originally required `claimed_seller_id` and `claimed_at` to be
  null together, which made deleting a claiming seller fail (FK `ON DELETE SET NULL`).
  Now `directory_imported_places_claim_shape` only requires `claimed_at` while a seller is
  linked; the place becomes unclaimed again. Covered by the acceptance test.
- ✅ Snapshot stays out of git (`tools/osm/snapshots/` in `.gitignore`); SHA-256
  `6cfdb2ab…339ee0`, date and OSM base timestamp in `docs/evidence/step-e1-5/snapshot.txt`.
- ✅ Test isolation: the E1 and E1.5 SQL tests no longer depend on local data. Both page
  through the full search result (`pg_temp.search_all()`) and assert on fixture ids
  (verified fixtures present, unverified/claimed/removed fixtures absent); the E1
  anonymous direct-read checks are scoped to the fixture seller ids.
- ✅ Seller deletion with a claimed place: a seller with reviews cannot be deleted
  (`reviews.seller_id` RESTRICT → place stays claimed/hidden); otherwise the owner profile,
  hours and menu cascade away and the place reverts to a plain unclaimed OSM entry (no
  menu, `reviews_enabled = false`, reviews/menus still rejected with 23514). Proven in
  the E1.5 acceptance test.
- 🟡 `20260927000500_step_e1_5_claim_revert.sql` (resets the outreach status from
  `claimed` to `contacted` when the seller link is lost) is written and dry-run proven —
  migration + full acceptance in one rolled-back transaction
  (`docs/evidence/step-e1-5/dryrun-000500-with-acceptance.txt`) — but **not applied**:
  awaiting approval under the dry-run-first rule. Until then the standalone E1.5
  acceptance test stops at `outreach status no longer claims a seller`
  (`acceptance-output-without-000500.txt`).
- ✅ E3 plan: default directory = restaurants + cafés; `fast_food` only via an "Imbiss"
  chip (837 of 1123 imports); server needs a type-set filter in E3.
- ✅ E1 closeout delivered: `docs/evidence/step-e1/closeout.md`. E2 not started.
- 🟡 Migration ledger: `20260927000300` and `20260927000400` join the psql-applied list below.

## Step E1 — business directory server contracts

- ✅ `supabase/migrations/20260927000100_medical_professional_document_kind.sql`
  adds `medical_professional_registration` in its own committed migration. The later
  E1 migration uses it only after the enum transaction has committed.
- ✅ `supabase/migrations/20260927000200_step_e1_business_directory.sql` adds the
  seller-owned 1:1 directory profile, fixed types/cuisines/languages/specialties,
  type-specific checks, Europe/Berlin weekly opening intervals, restaurant/café menu,
  owner-only RLS, a seller-scoped `directory-covers` bucket, public search/detail,
  owner profile/hours/menu writes, and directory review upsert/soft-delete RPCs.
- ✅ Doctor verification evaluates the current directory type on every call. Approved
  identity remains mandatory; doctors use approved medical professional registration,
  while every other business still requires approved business registration. Changing
  a doctor to another type drops verification immediately unless that business proof
  exists. Unpublished drafts are owner-visible; public search/detail require both
  `is_published` and current `is_verified_seller()`.
- ✅ Existing `reviews` are extended with an explicit `purchase|directory` context.
  Purchase reviews retain order-item eligibility and verified-purchase behavior.
  Directory reviews require a published, verified restaurant/café, allow one editable
  review per user/business, reject owners and doctors, and carry no purchase claim or
  photos. Delete hides the row, excludes it from aggregates, and preserves any
  `reports.review_id` link.
- ✅ The admin queue displays the medical proof kind with localized copy in de/ku/en/ar/tr;
  generated localizations are current and the widget test checks the German label.
- ✅ `supabase/tests/step_e1_business_directory.sql` passes through `ROLLBACK`, including
  live type-dependent verification, unchanged ordinary-business verification, hidden
  unverified publication, midnight intervals, doctor review/menu rejection, owner
  self-review rejection, real delivered-order purchase-review regression, editable
  directory review aggregation, and reported-review soft deletion.
- ✅ Final regressions pass through `ROLLBACK`: Step B, Step C, Step D map, Step D postal
  hardening, and admin verification/reports. `flutter analyze --no-pub` reports no
  issues; `flutter test --no-pub` passes 262/262. Evidence is under
  `docs/evidence/step-e1/`. E2 has not started.

## Admin panel expansion

- ✅ Planning files are present at `docs/plans/zerin-addendum-profile-and-map.md`, `docs/plans/zerin-admin-panel-expansion.md`, and `docs/plans/zerin-new-categories-and-deals.md`.
- ✅ `supabase/migrations/20260924000100_admin_verification_reports.sql` adds admin-only queue/action RPCs (`get_admin_verification_queue`, `get_admin_reports`, `moderate_seller_document`, `resolve_report`), preserves `moderate_listing` unchanged, reuses the existing private `seller-documents` bucket (signed URLs only), `is_verified_seller()`, the existing `blocked` product status, and the `create_user_notification` helper. Applied to the live local DB via direct `psql` (no `supabase db reset`).
- ✅ One live-DB bug was found and fixed during this pass: `resolve_report` used a PL/pgSQL variable named `reason` that is ambiguous against the `reports.reason` column, so the dismiss path failed on Postgres with `column reference "reason" is ambiguous`. The migration now declares `#variable_conflict use_column` on `resolve_report`; the acceptance test passes to `ROLLBACK` after the fix.
- ✅ `supabase/tests/20260924000100_admin_verification_reports.sql` passes with `ON_ERROR_STOP=1` against the live local schema through `ROLLBACK`; `supabase/tests/step_b_sell_moderation.sql` re-ran to `ROLLBACK` to confirm the existing listings flow still works.
- ✅ Live-DB end-to-end assertions (to `ROLLBACK`): approving both `identity` + `business_registration` documents flips `is_verified_seller()` from false to true with no extra step; dismissing a report leaves the listing `active`; `block_listing` sets the listing to `blocked` and resolves the report.
- ✅ `/moderation` is now an admin-gated hub with Overview (pending listings / pending seller documents / open reports, each linking into its section), Listings (unchanged logic), Seller Verification (pending docs with shop name, kind, date, signed-URL preview via `url_launcher` for PDFs and `CachedNetworkImage` for images, approve/reject with optional `admin_note` on reject), and Reports (open reports with target title, reason, details, dismiss + product-only block-listing with confirm). Every user-facing string is localized through ARB keys in all five locales (`de`, `ku`, `en`, `ar`, `tr`); only the numeric `Text('$count')` / `Text('$value')` remain literal. Oversized lines were split; `flutter gen-l10n` regenerated `app_localizations*.dart`.
- ✅ `flutter analyze --no-pub`: `No issues found!` (zero oversized lines, zero hardcoded English UI strings); `flutter test --no-pub`: 260/260 pass (Step D's 256 + 4 new: overview links, document approve, document reject-with-note, reports dismiss+block; the 3 pre-existing listing tests were updated for the hub tabs and German l10n).
- ✅ Three 1206×2622 PNGs and machine-readable `results.json` record three PASS checkpoints + one PASS integration test at `docs/evidence/admin-expansion/` on the real iPhone 17 Pro simulator (`iOS 26.1`, UDID `CFF133B6-F73A-4335-A497-5244B15D1C39`) against local Supabase `http://127.0.0.1:54321`: `admin_expansion_overview.png`, `admin_expansion_seller_verification.png`, `admin_expansion_reports_queue.png` (`pending_listings=1`, `pending_docs=2`, `open_reports=1`). Screenshots show the German UI. Harness: `integration_test/admin_expansion_live_test.dart` with driver `test_driver/admin_expansion_driver.dart`.
- 🟡 Migration-ledger caveat (same as Steps B–D): the effective local schema contains Steps B/C/D plus the admin expansion, categories, compare-at-price, and E1 passes, but `supabase_migrations.schema_migrations` has no rows for `20260914000100`, `20260914000200`, `20260920000100`, `20260922000100`, `20260924000100`, `20260925000100`, `20260925000200`, `20260927000100`, `20260927000200`, `20260927000300`, `20260927000400`, `20260927000500`, `20260927000600`, `20260927000700`, or `20260927000800` because they were applied through the documented direct-`psql` path. Before any real `supabase db push` to remote, run `supabase migration repair` to reconcile ledger rows vs. effective schema. Remote parity remains unverified. No `supabase db reset`, Colima use, Docker context switch, or remote mutation was performed.
- ⚠️ Known pre-existing schema issue: reports target foreign keys use `ON DELETE SET NULL`, while `reports_exactly_one_target` requires exactly one non-null target. Deleting a reported product, seller, review, or message can therefore fail; this pass records the issue but does not change it.
- ℹ️ Demo fixtures left in the local DB for the iOS evidence (local-only, not migrations): pending business seller `Demo Manufaktur Berlin` with 2 pending docs, 1 `pending_review` listing `Admin Demo Kamera`, 1 open `spam` report. They do not affect the committed schema.

## Product contract

- ✅ One unified listing model for private individuals and business sellers.
- ✅ Every submitted listing is manually moderated and starts `pending_review`.
- ✅ Buyer–seller contact is in-app chat only.
- ✅ Germany-only, with city-level public location and explicit country eligibility.
- ⛔ Cart, checkout, orders, product payments, Stripe, commissions/payouts,
  partner-store onboarding, and a Stores tab are out of scope.
- ✅ Shell contract is Home · Categories · Sell · Chat · Account.
- ✅ Public-safe user identity at `/profile/:username`, distinct from the linked
  seller/store profile, is implemented by Step C.
- ✅ `/map` is a dedicated full-screen shell route — added by Step D, not a sixth tab —
  with server-side radii and privacy-safe listing points.
- ✅ Step D adds a real Map screen, `flutter_map`/`flutter_map_marker_cluster`/`latlong2`
  packages, `geolocator` device location, and `lib/features/map/` (data/domain/presentation).
- ✅ Server-derived private points: `products.latitude`/`longitude` are owned by the
  `derive_product_map_point` trigger and never written by device GPS, private address,
  or direct client coordinate injection (verified by `step_d_map.sql` injection-override
  assertion). `postal_code` is never projected by the Map RPC.
- ✅ Canonical `public.german_cities` (20 reviewed WGS84 centroids), server-owned and
  read-only to clients; `products`/`sellers`/`profiles.city` now reference it.
- ✅ `public.listings_within_radius(center_lat,center_lng,radius_km,...)` projects the
  marker set: server-side radius + all discovery filters; verified opted-in businesses
  keep their reviewed precise point, every other listing keeps its stable 300–500 m
  city-jittered point; private listings never project an address.
- ✅ Deterministic 300–500 m privacy jitter per product via `safe_listing_city_point`
  (MD5 of product id, fixed 0.29–0.51 km envelope); viewer GPS/map center is query input
  only and is never persisted to a listing.
- ℹ️ Verified-business precise points still live in Step C `sellers` fields
  (`latitude`/`longitude`/`address_line`, `precise_location_opt_in`); Step D wires them
  into the Map projection but does not change their write path.

## Current quality gate

- ✅ `flutter pub get` succeeds after removing `flutter_stripe` and its locked transitive packages.
- ✅ `flutter analyze --no-pub`: `No issues found!` on the final Step D closeout run
  (4.2s), against the full worktree including `lib/features/map/` and the Step D
  migration/test files.
- ✅ `flutter test --no-pub`: 256/256 tests pass (`00:10 +256: All tests passed!`)
  with zero failures. The Step C ledger's 237-test tally is superseded by the
  Step D suite, which adds map privacy/radius/filter coverage.
- ✅ `supabase/tests/step_c_user_profiles.sql` passes with `ON_ERROR_STOP=1` against
  the effective local Step C schema through final `ROLLBACK`; it covers username
  normalization/conflicts/reserved names, safe projections, opaque avatar ownership,
  active-only listings, productless seller chat identity, avatar clear, and guarded
  verified-business location data.
- ✅ `supabase/tests/step_b_sell_moderation.sql` previously passed against the effective
  local schema through `ROLLBACK`; it covers forced pending submission, protected
  images, moderation, public visibility, notification/outbox enqueue, and Realtime.
- ✅ `plutil -lint ios/Runner/Info.plist` previously reported `OK`; the Step B
  `flutter build apk --debug --no-pub` produced `app-debug.apk` with the camera
  manifest merged.
- ✅ A real iPhone 17 Pro simulator (`iOS 26.1`, build `23B86`, UDID
  `CFF133B6-F73A-4335-A497-5244B15D1C39`) completed the live local-Supabase Step C
  profile edit → public profile → message-seller chat hand-off.
- ✅ Four inspected 1206×2622 PNGs and machine-readable passing results are at
  `/tmp/zerin-step-c-ios-screenshots/`: `step_c_my_profile.png`,
  `step_c_edit_profile.png`, `step_c_public_profile.png`, and
  `step_c_message_seller_chat_handoff.png`.
- ✅ The Step C live harness confirms the destination chat uses the existing
  `/chat/:chatId` UI, has the expected seller and buyer, and has `product_id IS NULL`.
- ✅ `git diff --check` passes.

The suite grew from the verified 190-test Step B baseline to 237 tests. Step C adds
profile data/controller/widget/route coverage, safe public identity overlays, and chat
identity coverage. The live iOS harness is retained at
`integration_test/step_c_live_test.dart` with driver
`test_driver/step_c_driver.dart`; its `results.json` records four PASS checkpoints and
one PASS integration test.

## Step D closeout evidence

- ✅ `flutter analyze --no-pub`: `No issues found!` (4.2s) on the final Step D worktree,
  including the new `lib/features/map/` slice.
- ✅ `flutter test --no-pub`: 256/256 pass (`00:10 +256: All tests passed!`); zero
  failures. The baseline rose from Step C's 237 to 256, covering Map RPC projections,
  jitter envelope, and verified-store precise-point routing.
- ✅ `git diff --check` passes against HEAD.
- ✅ Four 1206×2622 PNGs and a machine-readable `results.json` record four PASS
  checkpoints + one PASS integration test at `docs/evidence/step-d/` (the driver's
  `outputDirectory` was retargeted from `/tmp` to this persistent path):
  `step_d_map_pins_30km.png`, `step_d_radius_all_clusters.png`,
  `step_d_private_pin_preview.png`, `step_d_listing_detail_handoff.png`.
- ✅ The Step D live harness ran on the real iPhone 17 Pro simulator (`iOS 26.1`,
  build `23B86`, UDID `CFF133B6-F73A-4335-A497-5244B15D1C39`) against local Supabase
  `http://127.0.0.1:54321`. `results.json` evidence: `near_count=12`,
  `all_count=32` (12 < 32), private jitter `0.3816 km` (inside the 0.29–0.51 envelope),
  precise store point `52.516275, 13.377704` / `Unter den Linden 77, Berlin`.
- ✅ Step D SQL acceptance `supabase/tests/step_d_map.sql` re-ran post-hardening via
  psql to `ROLLBACK`; `supabase/tests/step_d_postal_code_hardening.sql` also passes to
  `ROLLBACK`, asserting `postal_code` is forced NULL after a direct INSERT and after a
  direct UPDATE. `postal_code` is NULL for all 32 products.
- ✅ Step D SQL acceptance `supabase/tests/step_d_map.sql` asserts: canonical 20-city
  seed, city-foreign-key integrity, backfilled German points, no partial coordinate
  pairs, 0.29–0.51 km jitter envelope, direct-coordinate injection override, radius
  filter composition, precise verified-store projection, private address-free pin,
  verification-revoke fallback, and RPC input validation. It ends in `rollback`; it was
  not re-executed against a live Postgres here.
- ℹ️ `geolocator_linux: 0.2.4` is a `direct overridden` sole dependency override,
  scoped to the Linux host embed; it satisfies `geolocator 14.0.3`'s Linux-platform
  requirement and does not resolve into or affect the iOS/Android AOT builds this app
  ships (there is no `geolocator_linux` transitive edge for `darwin`/`android`).
- ✅ `supabase/migrations/20260922000100_step_d_postal_code_hardening.sql` (applied via direct `psql`, same as Steps B–D) installs the `null_unless_server_postal_code` before-insert/update trigger on `public.products`, which forces `postal_code` to NULL on every client write, and backfilled the 30 existing rows. Verified on the live local DB: `has_column_privilege` showed the earlier column-level REVOKE was inert under the existing table-level grants (`anon` SELECT, `authenticated` INSERT/UPDATE all still true), so trigger enforcement is the mechanism of record — there is still no column-level SQL privilege revocation. `select count(*) from public.products where postal_code is not null` = 0 of 32.
- ✅ `supabase/tests/step_d_postal_code_hardening.sql` passes to `ROLLBACK` against the live local schema: it asserts the stored `postal_code` is NULL after BOTH a direct client INSERT and a direct client UPDATE, plus trigger-exists and no-persisted-PLZ sanity. (Two self-inflicted fixture bugs were fixed along the way: the probe description violated `products_description_check`, and a bare top-level `assert(...)` is not valid outside a PL/pgSQL `DO` block.)
- ✅ `supabase/snippets/step_d_local_seed.sql` is a deterministic, idempotent, local-only seed recreating the live-test accounts (`step-b-ios-owner`, `step-b-ios-admin`, with the harness-expected passwords), the admin role, the private seller, and the Step D demo data, so test data no longer exists only inside one database. It is written to disk and has NOT been executed (no `supabase db reset` was run).
- ℹ️ Environment incident (2026-09-22): `colima start` was run once, which brought up a **separate empty Docker VM**; the local Supabase stack briefly pointed at that empty instance, which is why `auth.users` looked empty and the ledger appeared truncated. Switching the Docker context back to Docker Desktop (`desktop-linux`) and restarting Supabase restored the correct database (17 ledger rows, `german_cities` present, both `step-b-ios` accounts present). Standing rules now: Docker Desktop only, never Colima or a context switch, never `supabase db reset`, and all simulator screenshots/results.json under `docs/evidence/`, never `/tmp`.

- ℹ️ `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` /
  `NSLocationWhenInUseUsageDescription` (iOS) and `android.permission.CAMERA` /
  `ACCESS_FINE_LOCATION` (Android) are a **pre-existing gap** from the Sell/Profile
  `image_picker` flow, **not** introduced by Step D. `git diff HEAD` shows them as a
  single uncommitted block in the current worktree; the Map screen reuses the same
  `geolocator`/`image_picker` permission surface rather than adding new ones. They are
  required for production iOS/Android and must be retained regardless.
## Flutter application

- ✅ App bootstrap initializes Supabase only when both runtime defines exist and otherwise uses unconfigured repositories.
- ✅ Typed `go_router`, onboarding persistence, auth-aware redirects, Riverpod state, light/dark themes, and five locales are present.
- ✅ Home reads campaigns, categories, new arrivals, deals (19 products with `compare_at_price_cents`), and sellers.
- 🟡 Home search still opens Categories; Home favorite hearts remain local-only.
- ✅ Root categories and routed category product browsing are data-backed. The 2026-09-25 categories pass adds Musikinstrumente (top-level) plus Gold/Silberschmuck/Eheringe/Antiker Schmuck (under Uhren & Schmuck), Anzüge (under Mode Herren), and Frische Lebensmittel/Gewürze & Importwaren (under Lebensmittel & Süßes, tree activated) — all with 5-language names; the Home Angebote section reuses `compare_at_price_cents` with no new column.
- 🟡 Global search/results remains missing; the root Categories search field is read-only.
- ✅ Category product screen supports subcategories, condition, seller kind, German city, sorting, list/grid, search, and pagination.
- ✅ Product detail includes gallery, persistent favorite, sharing, report submission, seller identity, seller listings, similar listings, and chat CTA.
- ✅ Public seller profile supports unified private/business identity, verification state, bio, city, rating, and paginated listings.
- 🟡 Seller banner, hours, directions, and approved public contact fields are not implemented.
- ✅ Buyer–seller chat has inbox, unread totals, product context, realtime refresh, pagination, read tracking, and idempotent send retry.
- ✅ Chat is a first-class auth-gated shell tab with unread badge; `/inbox` remains available from Account.
- ✅ Sell is one catalog-first/free-form four-step path for private and business sellers, with required details, the shared German-city picker, optional Originalpreis (compare-at price, validated server-side to be greater than price or NULL), 1–10 gallery/camera/template photos, client WebP compression, protected upload, review, and pending confirmation.
- ✅ My Listings under Account keeps pending/active/rejected/draft/sold/blocked submissions owner-visible, including rejection reasons; uploaded private-bucket images use signed URLs.
- ✅ The server-admin-gated `/moderation` route is a hub with Overview, Listings (pending/approved/rejected counts and the shared full-context queue with approve and optional-reason reject — logic unchanged), Seller Verification (pending docs with signed-URL preview, approve/reject with optional note), and Reports (dismiss + product-only block-listing with confirm).
- ✅ Step C provides an expanded My Profile header in Account with display name,
  `@username`, city, listing count, bio, avatar, edit action, and public-profile action;
  account email is never rendered there.
- ✅ Auth-gated `/edit-profile` supports display name, server-backed unique/reserved
  usernames, shared German city selection, 500-character bio, gallery/camera WebP
  avatar replacement/removal, typed errors, and save feedback.
- ✅ Public `/profile/:username` exposes only safe person identity, approved active
  listings, self/not-found/error states, and a seller-linked Message action.
- ✅ Message seller from a public profile reuses the existing productless seller chat
  contract and `/chat/:chatId`; it does not introduce a second messaging model.
- ✅ Step D `/map` implements viewer-location permission/manual-city fallback, marker
  clustering, and map entry actions, served by the `lib/features/map/` slice.
- 🟡 Favorites persist on Product Detail and now have an Account destination, but Home
  favorite hearts are not synchronized.
- ✅ Recently viewed products have an Account destination backed by the existing view history.
- 🟡 Notification preferences persist, and moderation creates the existing `system` notification plus `notification_outbox` row; no worker consumes that outbox, so APNs/FCM device delivery and a notification inbox remain unavailable.
- 🟡 Privacy UI can request export/deletion and cancel deletion; operational processors are unverified/missing.
- 🟡 Legal readers exist; production content and first-class Kurdish DB content are not accepted.
- 🟡 Coordinated offline detection/recovery is not implemented yet.

## Removed dead Flutter scope

- ✅ Deleted `lib/features/cart/`.
- ✅ Deleted `lib/features/checkout/`.
- ✅ Deleted `lib/features/orders/`.
- ✅ Removed `flutter_stripe`, `stripe_android`, `stripe_ios`, and `stripe_platform_interface` from dependency resolution.
- ✅ No remaining Dart/YAML references to those feature paths, widgets, or packages.
- ℹ️ Historical commerce tables/enums remain in migrations. They are isolated legacy schema and must not be extended or treated as roadmap work without a separately reviewed cleanup migration.

## Supabase/backend

- ✅ Working-tree migration chain contains 26 migration files through
  `20260925000200_sell_compare_at_price.sql`.
- ✅ Step B adds server-forced pending submission, protected 1–10 WebP path validation, bypass-resistant atomic product/image creation, owner/admin visibility, admin-only dashboard and moderation RPCs, moderation metadata/reasons, product Realtime, and existing notification/outbox enqueue.
- ✅ Step C extends the existing `public.profiles` model with normalized unique
  usernames, profile city/bio, an opaque avatar key, safe own/public/batch RPCs,
  authenticated edit/avatar contracts, and private-seller chat identity projection.
- ✅ The effective local database was freshly verified before the final Flutter checks:
  `profiles.username/city/bio/avatar_key` and `get_public_profile`,
  `update_my_profile`, and `get_chat_inbox` are present; the Step C rollback SQL test
  then passed in full.
- ✅ Flutter repositories actively use Supabase Auth, PostgREST, RPC, Realtime, and protected Storage URLs.
- 🟡 Linked remote parity is still unknown. The latest read-only
  `supabase migration list --linked` attempt remains the Step B attempt that timed out
  while creating the temporary login role (status 544). No diff was available to
  review and no migration push or remote mutation was attempted.
- 🟡 Local migration history remains noncanonical: the effective schema contains Steps B/C/D plus the admin expansion, categories, compare-at-price, and E1 passes, but `supabase_migrations.schema_migrations` has no rows for `20260914000100`, `20260914000200`, `20260920000100`, `20260922000100`, `20260924000100`, `20260925000100`, `20260925000200`, `20260927000100`, `20260927000200`, `20260927000300`, `20260927000400`, `20260927000500`, `20260927000600`, `20260927000700`, or `20260927000800` because they were applied through the documented direct-`psql` effective-schema path. Before any real `supabase db push` to remote, run `supabase migration repair` to reconcile ledger rows vs. effective schema, so the push does not re-apply or skip migrations.
- ✅ Admin expansion migration `20260924000100_admin_verification_reports.sql` adds `get_admin_verification_queue`, `get_admin_reports`, `moderate_seller_document`, and `resolve_report` (all admin-gated, `authenticated` execute grants), reusing `is_verified_seller()`, the `blocked` product status, and `create_user_notification`. Acceptance `supabase/tests/20260924000100_admin_verification_reports.sql` passes to `ROLLBACK` against the live local schema. `moderate_listing` is untouched.
- ✅ Categories migration `20260925000100_new_categories_and_deals.sql` adds 13 category rows (1 top-level Musikinstrumente + 12 subcategories) with all 5 language names, matching the seed data shape (`icon_key`, `image_url`, `sort_order`, `is_active`); activates the Lebensmittel tree (parent + spec-listed children). No new columns: `compare_at_price_cents` is reused for the existing Home Angebote section. Applied via direct `psql`, idempotent on re-run.
- ✅ Sell compare-at-price migration `20260925000200_sell_compare_at_price.sql` adds CHECK constraint `products_compare_at_price_check` (NULL or > price_cents) on `products`, replaces the 10-param `submit_listing` with an 11-param version adding `p_compare_at_price_cents bigint default null`, validated server-side. Existing 10-arg positional callers still resolve (default fills 11th). Applied via direct `psql` (drop old signature, create new, revoke/grant). Step B acceptance test re-ran to `ROLLBACK`.
- 🟡 Category and Home country behavior still needs one canonical Germany-only query review; Home intentionally retains legacy unknown-country rows.
- 🟡 Search/suggestion RPCs exist but are not routed from Flutter.
- ✅ Map schema reconciliation confirms `public.products` already owns `city`,
  `postal_code`, `latitude`, and `longitude`; Phase 2 already had
  `products_location_idx`, `marketplace_distance_km`, and server-side radius filtering
  in `search_marketplace_products`. Step D reused these and added the privacy envelope.
- ✅ Step D migration `20260920000100_step_d_map.sql` creates read-only
  `public.german_cities`, the `safe_listing_city_point` jitter function, the
  `derive_product_map_point` before-insert/update trigger, and the
  `listings_within_radius` Map RPC. Acceptance `supabase/tests/step_d_map.sql`
  asserts the jitter envelope, injection override, verified-store precise point,
  private safe pin, verification-revoke fallback, and RPC input validation.
- ⚠️ `supabase/tests/step_d_map.sql` was not re-run against a live local Postgres in
  this closeout session (local Supabase unreachable); the file is assertion-driven
  and ends in `rollback`. Re-run via `psql` against an effective schema before any
  remote push.
- ✅ `public.profiles` remains the one user table; `public.sellers.user_id` is the
  distinct linked seller identity and sensitive seller fields remain separated.
- ✅ Public profile RPCs expose display name, username, city, bio, safe avatar object,
  listing count, and non-auth seller identity without exposing profile IDs, email,
  phone, raw avatar paths, preferences, or consent data.
- ✅ New profile avatars use opaque `<avatar_key>/<uuid>.webp` objects with server
  reservation/commit/clear and owner-only write policies; auth UUIDs are not exposed by
  the public projection.
- ✅ Seller-linked public profiles can open/reuse a productless chat through the
  existing approved-seller contract. Profiles without an approved seller intentionally
  have no message CTA; universal profile-to-profile messaging is not part of Step C.
- 🟡 Favorites/reports/notification/legal/privacy schema exists beyond currently accepted UI coverage.
- ✅ An authenticated server-admin-only moderation frontend processes pending listings through the same approve/reject contract used by the SQL acceptance test.

## Integrations

- ✅ Supabase runtime and graceful no-key mode are implemented.
- 🟡 Apple/Google OAuth calls exist through Supabase; production provider/callback acceptance remains unverified.
- ⛔ Stripe is out of scope and has been removed from Flutter dependencies/configuration.
- 🟡 Moderation notification rows and durable outbox enqueue are implemented and tested; actual FCM/APNs delivery is not operational because no Edge Function/worker consumes `notification_outbox`.
- ❌ Analytics collection, crash reporting, and AI integrations are not implemented.

## Localization, UI, and accessibility

- ✅ `de`, `en`, `ar`, `tr`, and `ku` ARBs are symmetric, including Step C profile copy.
- ✅ Arabic is RTL; Kurdish is LTR with custom Material/Cupertino delegates.
- ✅ Central Material 3 themes, bundled typography, semantic colors, spacing, radius, motion, and minimum touch-target tokens are reused.
- ✅ German/light My Profile, Edit Profile, public profile, and existing-chat hand-off
  have an inspected real-simulator visual pass with no exception or overflow.
- 🟡 Full-route dark/RTL/Kurdish/accessibility and dynamic-text acceptance remains open.
- 🟡 Final launcher source PNGs remain absent.

## Worktree and Git state

- Step A stabilization is based on commit `79dd523` on `main`, tracking `origin/main`;
  the intended Step B/Step C stabilization patch remains uncommitted.
- ✅ The final Step C closeout adds only its live acceptance harness/driver and this
  status evidence; `git diff --check` passes.
- ✅ Scope audit found no `/map` route, `MapRoute`, `MapScreen`, Map provider, mapping
  or geolocation package, `lib/features/map/` directory, or Map UI. The router/package
  diff contains Step B/C routes and Stripe removal only.
- `night-havarti` remains a clean linked worktree at old commit `8161b52`.
- ✅ `enchanted-apricot` was re-audited and retired during Step A; nothing was merged
  and its branch was not deleted.
- A temporary recovery copy of its tracked patch and untracked generated controller is
  outside the repository at `/tmp/zerin-enchanted-apricot-retirement-backup`.

## Next build order

1. Verify linked remote migration parity from a network that can establish the Supabase login role; review the diff before any push.
2. Keep Map deferred until separately started; when approved, add dedicated `/map` using server-derived private points and opt-in verified-business points, existing radius-search infrastructure, shared filters, and the product route.
3. Route real search/results from Home and Categories.
4. Synchronize every favorite surface.
5. Add the external notification-outbox delivery worker/device registration, then continue seller-profile completion, Kurdish DB content, offline recovery, and privacy processors.
6. Finish signing, icons, legal/operator content, deep links, README, monitoring, and release QA.
