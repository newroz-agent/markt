# Step F3 effective closeout

Executed: 2026-10-01
Branch: `step-e1-5-osm-import`
Migration: `supabase/migrations/20260930000100_step_f3_drop_legacy_identity_overloads.sql`
Dry-run and assertion map: `docs/evidence/step-f/f3-dryrun.md`

## Part 1a — lazy private creation partial failure

This was a real client lifecycle bug.

Before F3, `SellSubmissionController.submit` bumped `identityCatalogRevision` only after `SellRepository.submitListing` returned successfully. The UUID-first prepare RPC can commit a lazily created private seller before the client uploads photos or invokes final submit. If either later phase failed, the controller retained a catalog whose person identity still had `sellerId == null`. A subsequent attempt could therefore repeat the null lazy-creation path instead of using the seller that now existed.

`lib/features/sell/presentation/controllers/sell_controller.dart` now:

1. computes `refreshLazyPrivateIdentity` before starting the request when the draft is a person identity with null seller ID;
2. keeps success/error state handling unchanged;
3. bumps `identityCatalogRevision` from `finally`, so it runs after either success or failure.

`test/features/sell/sell_controller_test.dart` models the exact partial boundary: attempt 1 marks the private seller as created, then throws a photo-upload/network failure. It asserts the identity catalog refetches (fetch count 1 → 2), exposes the created private seller UUID, and attempt 2 succeeds using that UUID. The fake deliberately throws a simulated `(user_id, kind)` duplicate if retry still carries null, so the passing retry proves the stale-null path is gone.

## Part 1b — Arabic RTL widget coverage

The following files now contain explicit Arabic directionality and localized-content tests:

- `test/features/sell/sell_flow_test.dart` — dual-identity Sell choice; asserts RTL plus Arabic title/person/business labels.
- `test/features/sell/my_listings_test.dart` — private/business My Listings sections; asserts RTL plus Arabic section labels.
- `test/features/chat/chat_ui_test.dart` — server-bound inbox identity label; asserts RTL plus Arabic “as identity” text.

Focused Part 1 run: 29/29 passed. Final Flutter gate before effective migration application: `flutter analyze --no-pub` clean and `flutter test --no-pub` 330/330 passed.

## Caller migration and assertion strength

All executable Flutter, integration, seed, and SQL callers use UUID-first signatures. Historical migration definitions remain unchanged. The complete before/after assertion-strength table is in `f3-dryrun.md`; reviewed conclusions:

- original status, moderation, verification, location, menu, document and country postconditions remain;
- exact seller-ID binding was added where the old wrapper selected implicitly;
- obsolete private-seller refusal was replaced by current private/business coexistence, no-conversion, no-document-leak and second-business-denial proofs;
- F2a now enumerates all seven legacy signatures and requires each to be absent;
- F3 independently requires legacy 0 / explicit 7, the critical prepare/getter/start argument names, the profile UUID-first key, and reviewed ACLs.

## Effective migration application

Approved pre-state matched the proven clone:

- legacy overloads 7; UUID-first overloads 7
- users 8; sellers 10; products 35; chats 4; messages 7
- seller hash `ff20718c97a3b16b48d441fc1f7093c9`
- product hash `5697b348d6631b5116939503cf81f359`
- product→seller hash `2ad6411eb79cd18be45f49fa1ad0b9ac`
- chat hash `7941a1c1b6492ad4c1035426036f364b`
- message hash `cc83e392f628da1ad7b2a8e61d025eae`

The migration was applied exactly once via direct `psql`. It reached COMMIT in 0.15s after exactly seven `DROP FUNCTION` operations. It used no `CASCADE` and performed no DML.

Post-state:

- legacy overloads 0; UUID-first overloads 7
- every count and hash above is identical
- retained F2c fixtures remain users 3 / sellers 3 / products 2 / chats 3 / unread 3
- `supabase_migrations.schema_migrations` remains 17 rows, max `20260907000700`, because direct `psql` does not update the ledger

## Effective SQL acceptance

Every direct non-legacy suite ran exactly once as its own command with a three-minute ceiling and ended in rollback:

1. `step_f3.sql` — 0.07s
2. `step_f2a.sql` — 0.15s
3. `20260924000100_admin_verification_reports.sql` — 0.09s
4. `chat_phase1.sql` — 0.10s
5. `phase3_country_moderation.sql` — 0.08s
6. `phase3_public_data.sql` — 0.09s
7. `precise_location_gaps.sql` — 0.09s
8. `step_b_sell_moderation.sql` — 0.10s
9. `step_c_user_profiles.sql` — 0.12s
10. `step_d_map.sql` — 0.11s
11. `step_d_postal_code_hardening.sql` — 0.07s
12. `step_e1_5_osm_import.sql` — 1.20s
13. `step_e1_business_directory.sql` — 0.51s
14. `step_e2_owner_onboarding.sql` — 0.09s

Post-suite checks found zero F2a/E2 fixture users, legacy 0 / explicit 7, and unchanged data hashes and ledger.

## Step F completion and next order

Step F is complete through F3. `docs/HANDOFF.md` now directs the next agent to:

1. open and merge a pull request from `step-e1-5-osm-import` into `main` (no direct push to main and no implied remote Supabase authorization);
2. only after the PR merge, start E3 from the merged main state.
