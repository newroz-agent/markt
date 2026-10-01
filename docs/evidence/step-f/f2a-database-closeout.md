# Step F2a database closeout

Executed: 2026-09-29 16:05 CEST
Branch before closeout commit: `step-e1-5-osm-import`
Starting commit: `4638623bb087790d37b508f59188690ca34cb400`

## Scope and environment

- Database-only F2a; F2b/F2c were not started.
- Docker context: `desktop-linux` (Docker Desktop); container: `supabase_db_flutterapp`.
- Effective database: local `postgres` on the existing Supabase stack.
- No `supabase db reset`, remote database mutation, migration push, or ledger repair was run.
- Migration: `supabase/migrations/20260928000100_step_f2a_multi_identity.sql`
  - SHA-256: `08b53b1b86e1ed78bec317635b209479c803fc7eadff5e7ec73649593e37fa45`
- Acceptance: `supabase/tests/step_f2a.sql`
  - SHA-256: `a56678b134b13ea62b7326e1c1ce2fcdab876057278525913c575fda286ee6e4`

## Required fresh-clone gate

A new database, `f2a_dryrun_20260928_02`, was created from `template0`. A full `pg_dump -Fc` of the still-unmigrated effective database was restored with original owners and ACLs through `pg_restore --single-transaction` as the local `supabase_admin` role.

The candidate migration was applied only to that clone, followed by one run of `step_f2a.sql` with `ON_ERROR_STOP=1`. The suite passed through its final `ROLLBACK`. In addition to the complete F2a matrix, the amended checks proved:

- authenticated direct `INSERT` into another owner's `business_directory_profiles` row fails with SQLSTATE `42501` from RLS;
- authenticated direct `UPDATE` of another owner's profile sees zero writable rows, and the owner later observes the row unchanged;
- UUID-first onboarding getter, directory type, profile upsert, hours, menu, and directory-start RPCs reject a foreign `p_seller_id`;
- explicit listing preparation rejects a foreign seller ID.

The clone contained zero F2a fixture rows after acceptance and was dropped. A post-drop source check still showed `sellers_user_id_key`, no `sellers_user_kind_key`, and no `get_my_identity_catalog()`, proving the gate did not migrate the effective database.

## Effective local apply and data impact

After explicit approval and the passing clone gate, the migration was applied exactly once to the effective local database via direct `psql`. Its transaction reached `COMMIT`.

Post-apply checks:

| Check | Result |
|---|---:|
| Existing seller rows | 7 |
| Existing owned seller rows | 4 |
| Existing product rows | 33 |
| Duplicate non-null `(user_id, kind)` groups | 0 |
| Old `sellers_user_id_key` | absent |
| New `sellers_user_kind_key` | `UNIQUE (user_id, kind)` |
| `get_my_identity_catalog()` | present |
| `products(id,seller_id)` fingerprint before | `a79f54f8a13e6ce15e516d78a8dc84b5` |
| `products(id,seller_id)` fingerprint after | `a79f54f8a13e6ce15e516d78a8dc84b5` |

No seller, product, or existing listing-to-seller assignment was rewritten.

## Effective-database SQL acceptance

The following files were then run exactly once each against the effective local database with `ON_ERROR_STOP=1`. Every suite passed and reached `ROLLBACK`; `supabase/tests/legacy/` was excluded.

1. `supabase/tests/step_f2a.sql`
2. `supabase/tests/20260924000100_admin_verification_reports.sql`
3. `supabase/tests/chat_phase1.sql`
4. `supabase/tests/phase3_country_moderation.sql`
5. `supabase/tests/phase3_public_data.sql`
6. `supabase/tests/precise_location_gaps.sql`
7. `supabase/tests/step_b_sell_moderation.sql`
8. `supabase/tests/step_c_user_profiles.sql`
9. `supabase/tests/step_d_map.sql`
10. `supabase/tests/step_d_postal_code_hardening.sql`
11. `supabase/tests/step_e1_5_osm_import.sql`
12. `supabase/tests/step_e1_business_directory.sql`
13. `supabase/tests/step_e2_owner_onboarding.sql`

Post-suite isolation check: zero F2a fixture rows; sellers/products remained `7/33`; the product-to-seller fingerprint remained `a79f54f8a13e6ce15e516d78a8dc84b5`.

## Flutter compatibility gate

The shipping client still uses legacy no-ID overloads. After the effective database migration:

- `flutter analyze --no-pub` — `No issues found!` (4.4s)
- `flutter test --no-pub` — `297/297` passed (1m 10s)

The no-ID overloads are a temporary rollout bridge. Once F2c ships and Flutter no longer calls them, they must be removed in a follow-up migration.

## Migration ledger caveat

Direct `psql` does not update `supabase_migrations.schema_migrations`. The effective schema now includes `20260928000100`, while the local ledger remains 17 rows with maximum version `20260907000700`. `20260928000100` is therefore added to the same noncanonical-ledger list as the other direct-`psql` migrations. Before any real remote `supabase db push`, reconcile the ledger with `supabase migration repair` under separate explicit approval.

## Hard stop

F2a is complete. F2b and F2c remain unstarted and require explicit approval.
