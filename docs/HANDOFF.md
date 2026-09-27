# Zêrîn — Agent Handoff
### Paste this into the new agent. Also save it as docs/HANDOFF.md so future agents can read it.

You are taking over an in-progress project from a previous agent. Before doing anything,
read this whole file, then `docs/STATUS.md` (the single source of truth for what is
built and verified), then the plans in `docs/plans/`. Do not trust this file over the
live repository and database: verify.

---

## 1. Project
- **Zêrîn**: a premium classifieds marketplace and local business directory for Germany,
  Kurdish-community focused. Flutter + Riverpod (codegen) + go_router (typed routes) +
  Supabase (Postgres, Auth, Storage, Realtime).
- Repo: `/Users/lawand/flutterapp`. Work happens on branch `step-e1-5-osm-import`
  (main is still at 79dd523 and unchanged). Check `git log` for the latest commits.
- Local Supabase: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`,
  API `http://127.0.0.1:54321`.
- iOS simulator: iPhone 17 Pro, iOS 26.1, UDID `CFF133B6-F73A-4335-A497-5244B15D1C39`,
  bundle id `de.zerin.zerinMarketplace`. Run with `--dart-define-from-file=dart_defines.json`.

## 2. Standing rules (non-negotiable)
**Environment**
- Docker Desktop only (`docker context` = `desktop-linux`). Never start Colima, never
  switch Docker contexts. If Docker is unreachable, stop and ask.
- Never run `supabase db reset`. Never touch the remote project (no `db push`, no
  `migration repair`) unless explicitly told.

**Data safety**
- Audit first: read the live schema before writing any migration or code.
- Any command that writes data (imports, backfills, deletions, harness runs that write,
  seeds) runs as a dry-run first, then waits for explicit approval. Approvals are per
  run; anything beyond the approved runs needs a new approval.

**Migrations and SQL tests**
- New files in `supabase/migrations/`, applied via
  `psql ... -v ON_ERROR_STOP=1 -f <file>`, and listed in the migration-ledger caveat in
  STATUS.md (these direct-psql migrations are NOT in `schema_migrations`; the ledger
  needs `supabase migration repair` before any remote push).
- `ALTER TYPE ... ADD VALUE` always in its own migration.
- Every migration has a transaction-scoped acceptance test in `supabase/tests/` that
  creates its own fixture users in `auth.users`, asserts on fixture IDs (never on global
  counts of whatever is in the DB), and ends in `ROLLBACK`.

**Flutter code**
- No hardcoded UI strings: all five ARB files (de is the template; ku, en, ar, tr).
  Arabic is RTL; Kurdish (Kurmancî, Latin script) is first-class.
- `dart format`, small private widgets, no giant single-line widget trees, typed
  exceptions, no empty catch blocks, explicit `rpc<T>` types.
- Existing design tokens only (petrol/gold/ivory, Bricolage Grotesque + Figtree).

**Evidence and reporting**
- Real iOS simulator screenshots + `results.json` under `docs/evidence/<step>/`, never
  `/tmp`. Live harnesses must clean up everything they upload, pass or fail.
- Stop at the end of each step with a closeout report: files with line numbers,
  migration names, `flutter analyze --no-pub` and `flutter test --no-pub` results, SQL
  suites run, screenshots, and an honest list of what is NOT done.
- Never commit `dart_defines.json` or any secrets. Do not commit `.kiro/`, `.scratch/`,
  `semantic-review/`.

## 3. Locked product decisions
- Unified classifieds: private individuals and businesses list through one flow. No
  cart, checkout or payments. Contact is in-app chat only.
- Every listing starts `pending_review`; admins approve. No auto-approval.
- Private listings: city-level location only, jittered 300–500 m. Only verified
  businesses get a precise pin. Germany only. `postal_code` is never stored.
- Admin hub: listings moderation, seller-document verification, reports.
- Business directory (Step E): owners self-register and verify. A pending business
  seller becomes approved automatically when its required documents are approved
  (identity + business_registration, or identity + medical_professional_registration for
  doctors). Ratings only for restaurants, cafés and fast food, never doctors; the
  directory rating is separate from purchase ratings. Structured menus. OSM-imported
  unclaimed entries (1123 in Berlin) show an unverified note and have no reviews, menu,
  description or chat. Outreach emails are admin-only, with a suppression list; no
  automated email sending.
- Step F (decided, not built): one login, up to one private and one business seller
  identity per user, with an identity switcher.

## 4. Done
Steps A–D, admin expansion, new categories and deals, compare-at price, E1 (directory
schema), E1.5 (OSM import + outreach contacts), E2 (owner side, document upload,
business onboarding, migration 000700), snackbar leak fix, E2 harness cleanup.
Details and evidence: STATUS.md and `docs/evidence/`.

## 5. In flight at handoff: verify first (read-only), report, then continue
The previous agent was approved to do these; confirm each is actually done:
1. Migration `000800` (suspension clears the public pin instead of raising; directory
   type changes run the verification wipe) applied, and its test passes.
2. The leftover Step B photo deleted (path in
   `docs/evidence/step-e2/dryrun-stepb-leftover.txt`).
3. Step B harness re-run once with its fixed cleanup, before/after listing and photo
   counts equal; Step B output moved from `/tmp` to `docs/evidence/step-b/`.
4. Known issue recorded in STATUS.md: deleting a listing leaves its photos in storage
   forever (pre-launch fix, also for account deletion).

For anything not done, report it and ask for approval before doing it (rule: dry-run
first). Then run all SQL suites and `flutter test` and report the counts.

## 6. Next step: Step F, Phase F1 only
Read `docs/plans/zerin-step-f-account-switching.md` in full. Do Phase F1: a read-only
audit of every place that assumes one seller per user (database functions, RLS,
triggers, Flutter repositories/providers/screens), with file and line and the proposed
change for each. Stop after the list. Change nothing until approved.

## 7. Backlog after Step F (for context, do not start)
E3 public directory (address-draft decision recorded in the E3 plan), Map v2
(`docs/plans/zerin-map-v2.md`), claim flow for OSM entries, listing-photo deletion fix,
reports ON DELETE SET NULL vs exactly-one-target conflict, production map tile provider,
push notification delivery, Impressum for business identities, remote parity and
migration-ledger repair, release readiness (Android signing, icons, legal texts,
deep links).
