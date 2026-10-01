# Step F3 dry-run and assertion-strength map

Executed: 2026-10-01 13:01 CEST
Effective database: unchanged; F3 not applied
Disposable database: `f3_dryrun_20261001_01` (dropped after proof)

## Part 1 checks

- Lazy-private partial failure: `SellSubmissionController` now bumps `identityCatalogRevision` in `finally` whenever the submitted person identity had a null seller ID. The test models prepare committing the private seller followed by upload failure. Catalog fetch advances from 1 to 2, returns the created private seller ID, and retry succeeds; retrying the stale null identity would throw the simulated `(user_id, kind)` duplicate.
- Arabic RTL widget coverage added for the F2c Sell identity choice, My Listings private/business sections, and inbox identity labels.
- Focused Part 1 run: 29/29 passed.
- Full Flutter gate: `flutter analyze --no-pub` clean; `flutter test --no-pub` 330/330 passed.

## Exhaustive current-caller audit

Already UUID-first before F3:

- Flutter `SupabaseSellRepository`: four-key prepare including `p_seller_id`.
- Flutter `SupabaseBusinessRepository`: `p_seller_id` for getter/type/profile/hours/menu and `p_existing_private_seller_id` for start.
- `integration_test/step_e2_live_test.dart`: explicit business seller ID.
- F2c seed/harness: no legacy calls.

Updated SQL callers:

- `step_b_sell_moderation.sql`: 3 listing preparation calls.
- `phase3_country_moderation.sql`: 1 listing preparation call.
- `precise_location_gaps.sql`: 3 profile upserts.
- `step_e1_business_directory.sql`: 1 menu replacement.
- `step_e1_5_osm_import.sql`: 2 menu replacements.
- `step_e2_owner_onboarding.sql`: start/getter/type/profile calls and ACL checks.
- `step_f2a.sql`: compatibility assertions and no-arg getter proof.

Historical definitions in earlier migrations remain immutable.

## Assertion before/after map

Only behavior/assertion changes are listed here. Calls that merely gained the exact seller UUID are listed afterward.

| File / proof | Before | After | Strength |
|---|---|---|---|
| `step_f2a.sql` compatibility contract | Legacy listing wrapper created one business, ignored a later private request, returned the same ID/kind, and kept one seller. | One assertion enumerates all 7 legacy regprocedure signatures and requires every one to be absent. `step_f3.sql` independently repeats absence and requires all 7 explicit survivors. | Intentional final-contract replacement; proves removal rather than compatibility behavior. |
| `step_f2a.sql` private→business gate | Legacy no-ID `owner_start_directory` rejected a private seller with `42501`. | Obsolete rejection removed; adjacent explicit test creates a separate business from the exact private ID, asserts 2 identities, and asserts second business is rejected `22023`. Legacy start absence is asserted. | Stronger for the approved two-identity contract. |
| `step_f2a.sql` onboarding selection | No-arg getter on a dual account deterministically chose business. | UUID getter must return the exact requested business ID while retaining profile/hours/menu checks. | Stronger: exact binding, no implicit selection. |
| `step_b_sell_moderation.sql` business preparation | Legacy prepare created a business; assertions required returned kind `business` and persisted seller `pending`. | Explicit directory start creates business, explicit prepare must return that exact ID, kind remains `business`, and seller remains `pending`. | Stronger: preserves status/kind and adds exact-ID binding. |
| `phase3_country_moderation.sql` new business | Legacy prepare implicitly created the seller; later assertions required seller DE/pending and submitted product DE/pending-review. | Explicit directory start creates seller, explicit prepare must return that exact ID; every original country and moderation assertion remains. | Stronger: original proof plus exact-ID binding. |
| `step_e2_owner_onboarding.sql` anon ACLs | Anon lacked execute on legacy no-arg getter and 3-arg start. | Anon lacks execute on UUID getter and 4-arg start; F2a/F3 require legacy functions absent. | Stronger complete final API boundary. |
| `step_e2_owner_onboarding.sql` private seller lifecycle | Private seller was refused by legacy start/type; no-arg getter showed only paths from its private documents. | Exact private ID can create one separate business; original private kind/status is unchanged; account has exactly 2 identities; type mutation against private ID still fails `42501`; second business fails `22023`; explicit business getter returns exact business and leaks no private documents. | Replaces obsolete refusal with stronger current coexistence/isolation proof. |
| `step_e2_owner_onboarding.sql` missing seller/type | Legacy no-ID set-type returned `P0002` when caller had no seller. | Explicit unknown business UUID returns `42501`. | Stronger fail-closed behavior; no seller-existence disclosure. |
| `step_e2_owner_onboarding.sql` anonymous getter call | Anon call to no-arg getter failed `42501`. | Anon call to exact UUID getter fails `42501`; legacy getter absence separately required. | Equivalent authorization proof for final API plus removal proof. |

Argument-only migrations whose assertions remain unchanged:

- Step B first private preparation: adds null UUID; pending seller, image contract, submit, visibility, moderation and notifications unchanged.
- Step B private retry preparation: passes the existing private ID; added exact returned-ID equality, all rejection-flow assertions unchanged.
- Precise-location gaps: each of 3 profile upserts adds its fixture seller ID; verification/pin wipe/retention assertions unchanged.
- E1 directory doctor menu rejection: adds doctor seller ID; expected `23514` unchanged.
- E1.5 fast-food/cafe menu calls: add exact owner seller IDs; menu, claim, delete and revert assertions unchanged.
- E2 validation/start/getter/profile/status calls outside the table above: only add null/exact UUID; invalid-name/city/type SQLSTATEs, document status/note, approval history, verification, type lock, required document kinds, and rejected seller status assertions are unchanged.

New F3-only assertions (no weaker predecessor): legacy count 0, explicit count 7, authenticated execute retained, anon/service-role execute denied, critical prepare/getter/start PostgREST argument names and the profile UUID-first key retained, exactly one overload per API name, direct seller INSERT still revoked, and `(user_id, kind)` uniqueness remains clean.

## Migration and zero-data-impact proof

Migration: `20260930000100_step_f3_drop_legacy_identity_overloads.sql`
SHA-256: `b2217a2f482be81330474264e565438772146ebaf3195ec8182cb38bce294df9`

Acceptance: `supabase/tests/step_f3.sql`
SHA-256: `a92596ceb9dc48e1bff4e54318e4df6a9347be602fd8712f8ecccb01b89f514a`

The migration preflight required the exact 7 legacy + 7 explicit identities and rejected unreviewed overloads. It executed exactly seven `DROP FUNCTION` statements without `CASCADE`, then postflight required legacy 0 / explicit 7. Duration: 0.16s.

Before and after clone values were identical:

- users 8; profiles 8; sellers 10; seller hash `ff20718c97a3b16b48d441fc1f7093c9`
- seller documents 10
- products 35; product hash `5697b348d6631b5116939503cf81f359`
- product→seller hash `2ad6411eb79cd18be45f49fa1ad0b9ac`
- chats 4; chat hash `7941a1c1b6492ad4c1035426036f364b`
- messages 7; message hash `cc83e392f628da1ad7b2a8e61d025eae`
- notifications 7; reviews 0

## Post-migration SQL matrix

Each suite ran as its own command with a 3-minute ceiling:

- `step_f3.sql` 0.07s
- `step_f2a.sql` 0.13s
- `20260924000100_admin_verification_reports.sql` 0.09s
- `chat_phase1.sql` 0.11s
- `phase3_country_moderation.sql` 0.08s
- `phase3_public_data.sql` 0.08s
- `precise_location_gaps.sql` 0.08s
- `step_b_sell_moderation.sql` 0.12s
- `step_c_user_profiles.sql` 0.07s
- `step_d_map.sql` 0.10s
- `step_d_postal_code_hardening.sql` 0.06s
- `step_e1_5_osm_import.sql` 1.17s
- `step_e1_business_directory.sql` 0.51s
- `step_e2_owner_onboarding.sql` 0.10s

All 14 passed through rollback. Clone post-suite hashes remained baseline.

## Cleanup / hard stop

The disposable clone was dropped. Effective source remains unchanged with 7 legacy + 7 explicit overloads, 10 sellers, 35 products, and product→seller hash `2ad6411eb79cd18be45f49fa1ad0b9ac`.

F3 is dry-run proven only. Effective application requires explicit approval.
