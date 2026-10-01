# E1 live-schema audit and approved design

Date: 2026-09-27. Read the full plan at `zerin-business-directory.md`;
the requested `docs/plans/zerin-business-directory.md` is absent.
Live local Docker Desktop database audited read-only using psql.
Definitions are recorded in `live-schema-audit.txt`. The user subsequently approved
the three proposals with explicit implementation conditions; the E1 migrations and
acceptance evidence now implement those decisions.

## Reviews

- Existing reviews target either products or sellers, not products alone.
- Every review requires an order item; uniqueness is `(order_item_id, kind)`.
- INSERT/UPDATE RLS requires purchase eligibility; the INSERT trigger forces
  `verified_purchase = true`. Neither fits registered-user directory reviews.
- Ratings already enforce 1–5. Optional text currently requires 3–3000 characters.
- Published seller reviews already feed `sellers.rating_average/rating_count`
  through aggregate triggers. There are currently zero live review rows.
- Public SELECT currently allows every published review, irrespective of the
  directory publication or verification state. Directory visibility must be guarded.
- `reports.review_id` already references reviews. Physical deletion of a reported
  review conflicts with the report's exactly-one-target CHECK because its FK uses
  ON DELETE SET NULL. Use retained, removed-status review rows for directory deletion
  to preserve report context; exclude removed rows from public results and ratings.

Proposed extension: reuse seller reviews and rating columns; permit a null order
item only for explicitly constrained directory reviews with no product and
`verified_purchase = false`. Enforce one directory review per reviewer/seller,
owner exclusion, doctor exclusion, immutable context, and appropriate RLS/trigger
guards. Preserve existing purchase-review behavior. Serialize aggregate updates
per seller and test authenticated aggregate writes and concurrent correctness.

## Doctor verification decision

The live `is_verified_seller(uuid)` requires an approved business seller plus
approved identity and business_registration documents. Available document kinds
are identity, business_registration, vat_certificate, bank_account, and other.
There is no dedicated professional-proof kind.

Approved implementation: add `medical_professional_registration` as a
dedicated document kind for administrator-reviewed medical professional proof.
Keep approved seller status and identity mandatory. For a doctor directory profile
only, accept approved medical_professional_registration in place of the business
registration requirement. Other businesses retain the existing requirement;
generic `other` documents never confer verification. Permit an unpublished doctor
draft before verification to avoid circular onboarding; public visibility still
requires verification. Changing type must re-evaluate eligibility and must not
allow restaurant menus/reviews on a doctor profile.

The shared helper affects existing badges and precise-location eligibility as well
as the directory. Approval was received before it was changed. The enum addition is
in its own migration so it commits before the value is used. E2 has not started.
