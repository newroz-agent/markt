# Zêrîn — Agent Handoff

Read this file, then `docs/STATUS.md` (the detailed source of truth), then the relevant
plan before doing work. Verify the live repository and database; this handoff is a guide,
not a substitute for inspection.

## 1. Project and current branch

- **Zêrîn**: a premium classifieds marketplace and local business directory for Germany,
  focused on Kurdish communities. Flutter + Riverpod codegen + typed go_router + Supabase.
- Repo: `/Users/lawand/flutterapp`.
- Completed Steps A–F (E1/E1.5/E2 and F through F3) are on `main` via PR #1's merge
  commit `a5c9562`, which contains `549cb2d`. Current work branch:
  `step-e3-public-directory`, created from that merged `main`.
- Local Supabase database: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`;
  API: `http://127.0.0.1:54321`.
- iOS evidence device: iPhone 17 Pro simulator, iOS 26.1, UDID
  `CFF133B6-F73A-4335-A497-5244B15D1C39`, bundle id
  `de.zerin.zerinMarketplace`. Local runs use the uncommitted `dart_defines.json`.

## 2. Standing rules (non-negotiable)

### Environment

- Docker Desktop only (`docker context` must be `desktop-linux`). Never start Colima or
  switch contexts. If Docker is unreachable, stop and ask.
- Never run `supabase db reset`.
- Never mutate the linked/remote Supabase project (`db push`, `migration repair`, etc.)
  without explicit approval.

### Data safety

- Audit first.
- Every data write/import/backfill/delete/write-capable harness run needs an isolated
  dry-run, then explicit per-run approval.
- Apply approved migrations to the effective local DB via direct `psql`; record the
  noncanonical migration ledger in STATUS.
- Migration acceptance tests create deterministic fixtures and end in `ROLLBACK`.

### Flutter and evidence

- All UI copy lives in all five ARBs: de template plus ku/en/ar/tr. Arabic is RTL;
  Kurdish Kurmanji is LTR.
- Use typed errors and explicit `rpc<T>` calls; run code generation and `dart format`.
- Evidence belongs in `docs/evidence/<step>/`, never `/tmp`. Harnesses clean everything
  they create, pass or fail.
- Never commit `dart_defines.json`, `.kiro/`, `.scratch/`, or `semantic-review/`.
- Do not push directly to main. Merge through a pull request.

## 3. Locked product decisions

- Unified classifieds for private and business sellers. No cart/checkout/payments.
- Every listing starts `pending_review`; admins approve it.
- Buyer/seller contact is in-app chat only.
- Germany-only. Private listing points use stable 300–500 m city jitter; only eligible,
  verified, opted-in businesses expose precise location.
- Directory ratings are separate from purchase ratings. Doctors have no ratings/menu.
- OSM imported places remain separate unclaimed records; outreach data is admin-only.

### Step F identity contract (complete)

- One login owns at most one private and one business seller (`UNIQUE(user_id, kind)`).
- The person always exists in the switcher; the private seller row is created lazily on
  the first private listing. Business is created only through explicit directory start.
- Device active identity is remembered per auth UID and server-validated on every
  session/start. It is presentation/default context only, never authorization.
- Every seller operation passes an explicit seller UUID (or explicit null only for lazy
  private listing creation) and the database verifies ownership.
- Sell asks dual users to confirm person/business and binds the whole draft to it.
- My Listings is one screen with private/business sections.
- Inbox is unified. Buyer side is always person; seller side is the exact identity bound
  to `chat.seller_id`. Unread remains account-wide.
- Public person profile remains `/profile/:username`; business directory remains seller-ID
  based. Edit Profile is person-only.
- The temporary no-ID compatibility overloads have been removed by Step F3.

## 4. Completed and verified

Steps A–D, admin expansion, categories/deals, compare-at price, E1/E1.5/E2, and all of
Step F (F1 audit, F2a database, F2b identity/business client, F2c Sell/listings/chat/live
evidence, F3 compatibility removal) are complete. See `docs/STATUS.md` and evidence under
`docs/evidence/`.

### Final Step F state

- Applied local migrations include:
  - `20260928000100_step_f2a_multi_identity.sql`
  - `20260930000100_step_f3_drop_legacy_identity_overloads.sql`
- F3 effective schema: 0 legacy no-ID overloads; all 7 UUID-first APIs remain.
- F3 changed no rows. Effective retained data after the local F2c seed: 8 auth users,
  10 sellers, 35 products, 4 chats, 7 messages; exact hashes are in
  `docs/evidence/step-f/f3-closeout.md`.
- F3 SQL: `step_f3.sql` plus every other non-legacy suite passed once each (14/14), all
  through rollback.
- Flutter: `flutter analyze --no-pub` clean; `flutter test --no-pub` 330/330.
- Part 1a fixed a real lifecycle bug: nullable-person submission refreshed the identity
  catalog only on success. It now bumps revision in `finally`, so a seller created by
  prepare is discovered even when upload/submit fails; retry uses that UUID.
- Part 1b adds Arabic RTL widget coverage to Sell identity choice, My Listings sections,
  and inbox identity labels.
- Real Step F iOS evidence: 4/4 screenshots and 1/1 test under
  `docs/evidence/step-f/ios/`.
- Local-only retained F2c accounts are seeded by
  `supabase/snippets/step_f2c_local_seed.sql`: dual owner, buyer counterpart, and other
  seller owner. They intentionally remain in the effective local DB like E2 fixtures.

### Ledger caveat

The effective local schema was advanced with direct `psql`, but
`supabase_migrations.schema_migrations` still has 17 rows and max version
`20260907000700`. Both `20260928000100` and `20260930000100` (plus earlier direct-psql
migrations listed in STATUS) are absent from the ledger. Before any remote database push,
perform a separately approved `supabase migration repair` plan; do not guess or push now.

## 5. No work is currently in flight

Step F is complete. Do not reopen it unless a regression is reported. Known pre-launch
issues remain recorded in STATUS, including listing-photo deletion ordering, account
export/deletion across every seller identity, and report-target FK/check incompatibility.

## 6. Next step — E3

PR #1 is merged. On `step-e3-public-directory`, read the E3 plan in full and audit the
merged client and live local schema before implementation. E3 is the public directory UI
slice and includes the address-draft and Imbiss decisions recorded in its plan. The E3.1
audit changes no schema or client code; resolve its open product questions before build.
The merge does not authorize remote Supabase mutation.

## 7. Later backlog (after E3, context only)

Map v2 (`docs/plans/zerin-map-v2.md`), OSM claim flow, listing-photo deletion fix,
account-level export/deletion processor across all identities, reports `ON DELETE SET NULL`
versus exactly-one-target conflict, production map tile provider, push delivery,
business Impressum, remote parity/ledger repair, and release readiness (signing, icons,
legal texts, deep links).
