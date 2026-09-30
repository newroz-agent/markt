# Step F2c client and live-evidence closeout

Executed: 2026-09-30 23:33 CEST
Starting commit: `8a8809193eb2c8942de47532637cdac6e1975fa4`
Branch: `step-e1-5-osm-import`

## Client behavior

### Sell

- A dual-identity user always sees the pre-form choice “Als Privatperson / Als Geschäft”.
- The freshly server-validated active identity supplies only the initial selection; the user must confirm it.
- Person-only accounts enter the private flow directly. A person with no private seller sends explicit `p_seller_id: null`, allowing F2a to lazily create the private seller.
- `SellListingDraft` carries the immutable chosen catalog identity. Kind/name are derived display metadata, never editable identity selectors.
- UUID-first `prepare_listing_submission` receives all four keys. The returned seller ID is verified, then used for every image path and `submit_listing`.
- Changing identity resets step, validation state, catalog/template state, title/prices/description, city/category/condition/specifications, photos, busy state, and submission state. Late template-photo completion is generation guarded.

### My Listings

- One `/my-listings` screen remains.
- It fetches by every non-null seller UUID in the fresh catalog and maps each product to that exact identity.
- The UI renders separate Privat and Geschäft sections and shows each listing's identity label.
- Active identity never filters or authorizes this screen.

### Chat

- The inbox remains one unified list and unread remains account-wide.
- Flutter now consumes F2a `viewer_role`, `viewer_identity_type`, `viewer_seller_id/name/avatar`, and seller identity fields.
- Seller-side context is accepted only when `viewer_seller_id == chat.seller_id`; buyer-side context must be person/null-seller.
- Inbox and conversation header use the same localized “Als …” helper.
- No UI or cache derives the chat label from active identity.

### Cache invalidation

- My Listings consumes the freshly validated whole catalog.
- Lazy private creation bumps identity catalog revision before My Listings invalidation.
- Inbox and chat details watch identity catalog revision, not active selection.

## Automated validation

- Focused identity/Sell/chat matrix: 92/92 passed.
- `flutter analyze --no-pub`: clean.
- `flutter test --no-pub`: 326/326 passed (1m 00s).
- A faithful disposable clone received all SQL suites separately: `step_f2a.sql` and all 12 non-legacy suites passed. Slowest: `step_e1_5_osm_import.sql`, 1.14s.
- Clone/source rollback parity remained 7 sellers, 33 products, 1 chat, 1 message, product-seller hash `a79f54f8a13e6ce15e516d78a8dc84b5`.
- Full seed proof: `f2c-seed-dryrun.txt`.

## Effective local seed

After explicit approval, `supabase/snippets/step_f2c_local_seed.sql` was applied exactly once to the effective Docker Desktop database and reached COMMIT in 0.23s.

Retained local-only accounts:

- `step-f2c-dual@example.invalid` — private + approved/verified business
- `step-f2c-buyer@example.invalid` — chat counterpart
- `step-f2c-other@example.invalid` — owner of the buyer-side chat seller

Fixture shape: 3 users/profiles/sellers, 2 approved business documents, 2 identity-bound pending listings, 3 chats, 3 incoming unread messages plus 3 normal bootstrap system messages, and corresponding local notifications/outbox rows. Seed SHA-256: `c00d760fc7d7de57261f81a119b3f3c0b8e1847f58eb1bf39fa877ac9b9ccfab`.

## Live iOS evidence

One authorized harness run completed on iPhone 17 Pro simulator, iOS 26.1 (23B86): 4/4 checkpoints and 1/1 integration test PASS.

Files under `docs/evidence/step-f/ios/`:

- `step_f_identity_switcher.png` — 1206×2622, SHA-256 `6f99a1dba9ca5433b2c7d65c69d1591b7fb6bf5cec73976461bdbec2080539a4`
- `step_f_sell_identity_choice.png` — 1206×2622, SHA-256 `1fa02cdd950915f527290b34844a1b22b99433f6ae0c55df44e5e4a1dd3033e5`
- `step_f_my_listings_sections.png` — 1206×2622, SHA-256 `805ad4a522dc02941f5e56440dfa2ad9f3a11664165d5e67cfb0336adf4036f6`
- `step_f_inbox_identity_labels.png` — 1206×2622, SHA-256 `6ad364a081a07f43a8108808fcbeeac0f671dcfa6bc464fa22455f99fa19fe2c`
- `results.json` — SHA-256 `2443ebd1cb97b3ff00a1ab39accde552745fd8451cfe665bb04a866a8b10d2de`

Visual inspection confirmed both switcher rows with business active, business-preselected Sell choice, both listing sections and cards, and three inbox rows labeled as person/business/person with one unread each.

Cleanup/result contract:

- created rows: 0
- uploaded objects: 0
- exact fixture before/after counts: match
- device preferences: restored
- cleanup error: null
- inbox bindings: seller/private-person, seller/business, buyer/person
- unified unread: 3

The harness did not open a conversation, so `mark_chat_read` was never called. Exact pre/post inspection of all six chat messages showed no changes: the three fixed incoming messages still have `read_at = NULL`, and the three system messages retain `2026-09-30 12:00/12:10/12:20+00`. The optional approved seed restoration rerun was therefore not needed and was not run.

## Review boundary and hard stop

Review is limited to `git diff HEAD` plus new files for this F2c step; no whole-branch-to-main review is permitted. The next step is the small migration removing temporary legacy no-ID overloads. It requires explicit approval and has not started.
