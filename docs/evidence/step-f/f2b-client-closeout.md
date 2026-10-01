# Step F2b client closeout

Executed: 2026-09-30 20:45 CEST
Starting commit: `b01978fde20c88df9ac1719210d0289f186526ce`
Branch: `step-e1-5-osm-import`

## Scope

F2b is a Flutter-only client step over the already-applied F2a database contracts. No migration, SQL write, database reset, remote database operation, Sell flow, My Listings behavior, or inbox behavior changed.

## Shared identity lifecycle

- `get_my_identity_catalog` is the only catalog source.
- The catalog parser requires the permanent person entry and accepts at most one optional business entry; raw avatar object paths are resolved before reaching UI.
- Active selection stores only a stable display token under `identity.active.v1.<auth UID>`; no catalog or authorization decision is cached.
- Startup/session initialization fetches the server catalog before reading or exposing the stored token.
- Invalid or missing selection falls back in the required order: person/private, business, none; repaired fallback is persisted and an empty catalog removes stale selection.
- Each auth session owns a distinct provider family. Account A → B immediately exposes loading with no A value, and late A fetch/write completion cannot publish into B.
- Business creation and successful person profile/avatar changes increment a shared catalog revision, forcing same-session server revalidation.
- Successful auth sign-out captures and clears only that UID after the auth call succeeds. Failed auth sign-out never removes it. A post-auth local cleanup failure retains the captured UID and can retry without repeating remote sign-out.
- Active identity is consumed only by Account presentation/default context. Business authorization always uses explicit seller UUIDs and server ownership checks.

## Account and business UI

- Account shows the person row for every signed-in user.
- The optional business row shows pending, verified, rejected, or suspended status and has selected semantics, outline, color, and checkmark highlighting.
- Without a business, “Geschäft registrieren” is present for person-only and private-only users.
- Personal profile header, public-profile action, and Edit Profile remain person-only.
- Business registration always includes `p_existing_private_seller_id`, including JSON null, selecting the F2a UUID-first overload.
- Business hub, documents, profile, hours, and menu routes require `businessSellerId`.
- Onboarding, type, profile, hours, and menu RPCs all send `p_seller_id`; document/cover paths and withdrawal are seller-scoped too.
- Missing legacy route scope and malformed UUIDs fail before repository access. Valid foreign UUID ownership remains enforced by F2a.

## Localization and directionality

New Account keys were added to all five source ARBs and generated outputs:

- `accountSellingProfilesTitle`
- `accountPersonalIdentity`
- `accountRegisterBusiness`

Pending/verified labels reuse existing business keys; rejected/suspended reuse existing localized restriction labels. Account widget coverage confirms Arabic RTL, while the locale suite confirms Kurdish remains LTR.

## Validation

Focused final affected matrix: 78/78 passed, including catalog parsing, restore/fallback/refresh, stale-session isolation, sign-out success/failure/retry, Account states and selection persistence, Arabic RTL, exact UUID-first RPC maps, explicit route seller propagation, and missing/malformed business scope.

Final project gates:

- `dart format` on every changed Dart file: no changes required on final pass.
- `flutter analyze --no-pub`: `No issues found!` (4.3s).
- `flutter test --no-pub`: 316/316 passed (24s).
- `git diff --check`: passed.
- Production diffs under `lib/features/sell`, `lib/features/chat`, and `lib/features/products`: zero.

An independent semantic review identified same-session catalog invalidation, retryable post-sign-out local cleanup, and restricted-status labeling gaps; all three were corrected before the final 78-test and 316-test gates.

The retained `integration_test/step_e2_live_test.dart` now uses deterministic explicit seller routes and the UUID-first onboarding RPC. It was not executed because F2b did not request or authorize a write-capable live evidence run; real iOS evidence belongs to F2c.

## Hard stop

F2b is complete. F2c remains unstarted and requires explicit approval.
