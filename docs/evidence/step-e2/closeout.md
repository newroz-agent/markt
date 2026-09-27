# Step E2 closeout — owner side ("Mein Unternehmen")

Date: 2026-09-27. Branch `step-e1-5-osm-import`. Local Docker Desktop database only; no
`db reset`, nothing against the remote project. E3 and Step F have not started.

## Delivered

**Item 0: seller document upload (added to the plan 2026-09-27)**
- The owner picks the directory type first (Restaurant, Café, Imbiss, Arztpraxis). The
  documents screen then lists exactly the two documents that type needs:
  - identity + business registration, or
  - identity + medical registration for doctors.
- Each document is uploaded as a photo (camera or gallery, re-encoded as JPEG) or as a PDF
  into the private `seller-documents` bucket, then recorded in `seller_documents`.
- Each document shows its status (missing, in review, approved, rejected), its upload date
  and any rejection note.
- A rejected document can be uploaded again; a document in review can be withdrawn.
- The type can change until a directory profile exists; after that only through the
  profile.
- This reuses the existing storage policies and the admin verification queue. The queue now
  names identity and business-registration documents in all five languages (before, it
  showed the raw database values).

**Owner hub and editors**
- **Hub:**
  - verification status (verified, in review, documents missing)
  - document progress
  - tiles for profile, opening hours and menu (the menu only for food types)
  - a publish switch that stays disabled until the owner is verified
- **Profile editor:** type-aware. Cover image, description, phone, website and spoken
  languages for everyone; cuisines, price level and halal/vegetarian/vegan for food types;
  specialty and insurance for doctors. It checks the same rules as the server before saving.
- **Hours editor:** Monday to Sunday, up to 6 slots per day. A slot may run past midnight;
  choosing 00:00 as the closing time means the end of the day.
- **Menu editor:** sections and dishes. Create, edit, reorder, delete, availability switch,
  price, halal/vegetarian/vegan (vegan always counts as vegetarian). Saved as one
  replacement through `owner_replace_directory_menu`.
- **Entry points:** "Mein Unternehmen" in Account, shown to signed-in users without a
  seller and to business sellers, hidden for private sellers. Five signed-in-only routes
  under `/business`.
- **Strings:** 151 new keys in each of the five ARB files (de, ku, en, ar, tr). There are
  no hardcoded strings; the only literals are the `€` price-level symbols.
- **New dependency:** `file_selector`, Flutter's official package, for picking PDFs.

## Server changes (all applied via psql after dry-run and approval)

- **`20260927000500_step_e1_5_claim_revert.sql`:** when a claiming seller is deleted and
  the place falls back to unclaimed, its outreach status changes from `claimed` to
  `contacted`.
- **`20260927000600_directory_rating_separate.sql`** (0 existing rows changed):
  - The directory rating lives on the profile and counts only directory reviews.
  - The seller rating counts only purchase reviews.
  - Owners cannot write their directory rating.
  - Search and detail return the directory rating.
- **`20260927000700_step_e2_owner_onboarding.sql`** (0 existing rows changed at apply
  time), scoped exactly as decided:
  1. `owner_start_directory` creates a **pending business** seller (shop name, city,
     directory type, no listing), only for users without any seller.
  2. When an admin approves the full required set, a **pending business** seller becomes
     `approved`. The existing `record_seller_status_history` trigger records this with the
     approving admin as the actor. The set is identity + business registration, or
     identity + medical registration when the profile or declared type is doctor.
  3. Private sellers are never auto-approved. Rejected and suspended sellers are never
     re-opened. The listing-approval path is unchanged.
  4. Users who already have a seller are refused. A private → business path is Step F
     (account switching), not started.

  Supporting parts of `000700`, none of which change any status:
  - `owner_set_directory_type`: business sellers only; fixed once a profile exists.
  - `get_my_directory_onboarding`: one call for all owner screens, own data only.
  - `sellers.directory_type`, kept in sync with the profile type.
  - A document row may only point into the owner's own storage folder. This closes a
    pre-existing gap where an owner could reference another seller's file.
  - At most one document per kind can wait for review.

## Verification

- **SQL tests:** `supabase/tests/step_e2_owner_onboarding.sql` passes through `ROLLBACK`
  on the live schema. It covers:
  - start, type change and the private-seller refusal;
  - the document folder rule and one pending document per kind;
  - rejection notes reaching the owner;
  - approval of the full set for doctor, restaurant and marketplace business sellers,
    including the history row naming the admin;
  - no approval for private, rejected or suspended sellers;
  - doctor verification once the draft profile exists;
  - anonymous callers refused.

  E1, E1.5, B, C, D map, D postal and admin also pass through `ROLLBACK`
  (`regression-sql-output.txt`).
- **Flutter:** `flutter analyze --no-pub` reports no issues, and `flutter test --no-pub`
  passes 292/292. That includes 15 E2 model and screen tests and 2 account-entry tests.
- **Live iOS evidence** in `ios/`:
  - Device: iPhone 17 Pro simulator, iOS 26.1, UDID
    `CFF133B6-F73A-4335-A497-5244B15D1C39`, against local Supabase `127.0.0.1:54321`, in
    German.
  - Nine 1206×2622 PNGs plus `results.json`: 9/9 checkpoints PASS, 1/1 integration test
    PASS.

  | Screenshot | Shows |
  |---|---|
  | `step_e2_start` | new user, type chosen first (Arztpraxis), name field |
  | `step_e2_documents_rejected` | doctor needs identity + medical proof; identity approved, medical rejected with the admin's note |
  | `step_e2_documents_uploaded` | after re-uploading a PDF: "In Prüfung", upload date, withdraw action |
  | `step_e2_admin_queue` | admin verification queue lists the doctor's new medical proof; "Dokument öffnen" works through a signed URL |
  | `step_e2_hub` | verified restaurant: 2 of 2 approved, draft profile, 7 slots, 3 sections / 7 dishes, publish switch enabled |
  | `step_e2_profile`, `step_e2_profile_fields` | type, cover placeholder, description, phone, website; cuisines, price level, diet switches |
  | `step_e2_hours` | weekly slots including Saturday overnight |
  | `step_e2_menu` | sections with reorder and delete, dishes with price, flags and availability |

  The harness replaces only the native file picker, handing the real upload path a
  generated PDF, because a test cannot operate the iOS document picker. The storage upload,
  the database row and the admin queue are real. The harness checks that the object exists
  in the private bucket and that the document is pending.

## Data written to the local DB (approved)

- **Seed:** 3 test accounts (auth user plus login identity), 2 business sellers, 4
  documents, 1 restaurant profile, 7 opening-hour slots, 7 menu items. The passwords are
  local-only constants in the seed file.
- **The harness ran three times.**
  - Run 1 stopped at the admin queue: the wait condition matched the previous screen's
    chips.
  - Run 2 stopped at the profile checkpoint: the field was below the fold in a lazily
    built list.
  - Before each rerun, I re-ran the idempotent seed to reset the doctor's documents.
  - Run 3 passed.
- **Result:**
  - 3 PDF objects exist in the doctor's private folder. Two are orphans: the seed reset
    removed their rows.
  - The doctor now has one pending medical document in the admin queue.
  - Each run created login sessions for the four accounts.

## Known issues and observations

- **Hours screenshot predates a fix.** The Saturday overnight label is cut off
  ("12:00 – 02:00 (nächs…"). The weekday row now puts the day and the add button above
  full-width slots, and a widget test asserts the label is not truncated at phone width.
  Refreshing the screenshot means another harness run, which writes data (one more
  upload), so it needs approval.
- **Snackbar survives an account switch.** The app keeps one snackbar host for all
  screens, so the doctor's "Hochgeladen" message is still visible on the admin screenshot.
  It is minor and not fixed; snackbars could be cleared when the signed-in account changes.
- **Empty preview area for PDFs in the admin queue.** The doctor's card has a large blank
  area. This is existing admin UI.
- **Type chips no longer show a checkmark.** The checkmark covered the type icon; the
  selected colour marks the choice.
- **Cover image upload** is implemented and covered by the widget tests, but was not part
  of the live run (the harness has no image to pick).
- **Deviations from the plan text:**
  - Editors work as drafts before verification. E1 verifies a doctor only once a doctor
    profile exists, so hiding the editor would block doctor verification. Publishing
    stays locked until verification.
  - The Account entry is also shown to users without a seller, because otherwise no one
    could start.
- **Open for E3:** owners cannot set a map pin or address in E2. Distance and directions
  in E3 depend on Step D's precise location, which requires an opted-in, verified business.
  E3 needs to decide where owners set it.
- **Migration ledger:** `000500`, `000600` and `000700` were applied through psql and have
  no ledger rows. They are added to the STATUS caveat.
