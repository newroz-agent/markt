# Zêrîn — Step F: Account Switching (Private + Business Identity)
### Put this file in docs/plans/. Two phases with a hard stop between them.

---

## Product decision (locked)
One login, up to **two seller identities** per user:
- **Private** — a person selling their own used items. No documents.
- **Business** — shop, restaurant, café or practice: documents, verification,
  directory profile, opening hours, menu, precise pin.

Private listings always stay under the private identity and business listings under
the business identity — nothing is ever converted or relabeled. Max one private and one
business identity per user (multiple businesses per user: not now).

## Standing rules (unchanged)
Docker Desktop only, never Colima; never `supabase db reset`; audit first; dry-run
before ANY data write and wait for approval; migrations via psql in the ledger caveat,
each with a SQL acceptance test using its own fixture users; no hardcoded strings (five
ARB files, Arabic RTL); formatted Dart, typed errors, explicit `rpc<T>`; harnesses
clean up everything they upload; evidence under `docs/evidence/step-f/`.

---

## Phase F1 — Audit (read-only). STOP after it.
List, with file and line, every place that assumes **one seller per user**, grouped:
- **Database**: `sellers.user_id` uniqueness; functions that look up "the caller's
  seller" (e.g. `prepare_listing_submission`, `submit_listing`, `owner_start_directory`,
  profile RPCs such as `get_my_profile`, chat inbox/unread RPCs, notification helpers,
  data export and account deletion requests), RLS policies and triggers.
- **Flutter**: repositories, providers and screens that fetch or cache "my seller"
  (Sell flow, My Listings, Account, Mein Unternehmen, chat inbox, profile identity
  overlay).
- For each: what breaks with two sellers, and the proposed change.
- Also confirm current data: no user has more than one seller today (so the constraint
  change needs no data migration).

Deliver the list and stop. Do not change anything until I approve.

---

## Phase F2 — Implementation (after approval)

**Database**
- Replace the unique `sellers.user_id` with unique `(user_id, kind)`.
- Every function that needs a seller takes an explicit seller id or kind and verifies
  ownership server-side (`owns_seller`). The client's "active identity" is never
  trusted on its own.
- `owner_start_directory`: allow a user who has a private seller; refuse only if the
  user already has a business seller.
- Chat: a user can never open a chat with their own other identity. The inbox returns
  chats of both identities, each with the identity it belongs to.
- Reviews: a user can never review their own business from their private identity
  (same user).
- Account deletion and data export requests must cover both identities.

**Flutter**
- **Identity switcher** in Account: shows the private identity and, if it exists, the
  business identity (name + avatar/logo), with the active one highlighted. If no
  business exists: "Geschäft registrieren" leads to the E2 onboarding.
- Active identity is remembered per user on the device and reset on sign-out.
- **Sell flow**: if both identities exist, ask "Als Privatperson / Als Geschäft" before
  the form. Business listings follow the business rules.
- **My Listings**: grouped or filtered by identity.
- **Inbox**: one unified list, each chat labeled with its identity; a badge count covers
  both.
- **Mein Unternehmen**, documents and the directory editor: business identity only.
- Public pages unchanged: private profile at `/profile/:username`, business at its seller
  page.

**Tests and evidence**
- SQL acceptance: a user creates a business identity next to a private one; listings
  stay under their identity; ownership checks reject using the other user's seller id;
  self-chat and self-review blocked across identities; a second business is refused.
- Regression: all existing SQL suites and `flutter test` pass.
- Real iOS screenshots: the switcher with both identities, the Sell-flow identity
  choice, the inbox with identity labels, and a private user starting a business.

## Out of scope
Multiple businesses per user, transferring a business to another user, team members /
staff accounts, Impressum pages for business identities (later, before launch).
