# Zêrîn — Admin Panel Expansion: Seller Verification + Reports
### Paste into Claude Code. Additive only — do not change the existing listings moderation queue's behavior.

---

## Rules for this pass
- **Audit first**, same discipline as Steps C/D: inspect the live schema for
  `seller_documents` (columns already confirmed in an earlier audit: `id`, `seller_id`,
  `uploaded_by`, `kind`, `storage_path`, `mime_type`, `status`, `admin_note`,
  `reviewed_by`, `reviewed_at`, `created_at`, `updated_at`) and for `reports` (columns
  unknown — read them from `information_schema` before writing any UI or query). Check
  whether an approve/reject RPC already exists for seller documents (the listings
  moderation queue already uses `moderate_listing(uuid,text,text)` — check for an
  equivalent seller-document function before writing a new one).
- **Reuse `is_verified_seller()`** exactly as-is — it already requires both an approved
  `identity` document and an approved `business_registration` document for a `business`
  seller. Approving both documents through the new UI should be the only thing needed
  for a seller to become verified; don't duplicate that logic client-side.
- **Reuse the `blocked` product status** (confirmed to exist in `product_status`) for
  the "take action" path on a report — don't invent a new status.
- Reuse the existing notification/device-token infrastructure for seller-facing
  decisions (document approved/rejected, listing blocked from a report) — same pattern
  as Step B's listing approve/reject notifications.
- Admin-role-gated, same guard pattern as the existing `/moderation` route.
- Real iOS simulator screenshots, same standing rule as every step so far.

---

## 1. Structure
Turn the existing moderation area into a small hub with three sections, keeping the
current listings queue's behavior completely unchanged:

1. **Listings** (existing — do not modify its logic, only its place in the navigation)
2. **Seller Verification** (new)
3. **Reports** (new)

Add a simple overview screen above the three with pending counts for each
(pending listings, pending seller documents, open reports), each linking into its
section. Exact routing (sub-routes vs. tabs vs. a segmented control) is an
implementation detail — pick whatever fits the existing router/shell patterns cleanly.

## 2. Seller Verification section
- **Queue:** pending `seller_documents` rows, grouped by seller (a seller needs both an
  approved `identity` doc and an approved `business_registration` doc to become
  verified — show both side by side per seller so the admin can act on both at once).
- **Per document:** seller `shop_name`, document kind, submission date, and the actual
  uploaded file — resolve it through a secure signed URL (documents are sensitive;
  never a public bucket URL) so the admin can actually view the identity photo or
  business registration file.
- **Actions:** approve / reject per document, with an optional `admin_note` reason on
  reject (the column already exists).
- On approving the required documents, verification becomes true automatically via
  `is_verified_seller()` — no separate "mark verified" action needed.
- Notify the seller (approved or rejected, with the reason if rejected).

## 3. Reports section
- **Queue:** open reports — listing title/thumbnail, reporter info if available, reason,
  submission date — linking to the actual reported listing so the admin can see what
  was flagged before deciding.
- **Actions:**
  - **Dismiss** — mark the report resolved, no change to the listing.
  - **Block listing** — set the listing's status to `blocked` (reuse the existing enum
    value, don't add a new one) and mark the report resolved.
- Notify the seller if their listing gets blocked from a report, with a reason.

## 4. Definition of done
- The existing listings moderation flow from Step B still works exactly as before —
  verify with its existing tests before adding new ones.
- A seller with both documents approved through the new UI becomes verified
  (`is_verified_seller()` returns true) with no extra manual step.
- An admin can dismiss a report or block the reported listing, and the listing's public
  visibility reflects that immediately.
- `flutter analyze` clean; new tests for the seller-verification and reports flows,
  following the existing moderation test patterns.
- Real iOS simulator screenshots: the admin overview with counts, the seller
  verification queue with a document open, and the reports queue with the
  block-listing action.
- `docs/STATUS.md` updated in the same evidence-ledger format as Steps A–D.
