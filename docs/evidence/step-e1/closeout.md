# Step E1 closeout — business directory schema, rules and server contracts

Written 2026-09-27 during Step E1.5, because the original E1 closeout was never
delivered. Every statement below was re-checked against the migration
`20260927000200_step_e1_business_directory.sql`, the live local schema, the E1 audit
(`audit.md`) and the evidence in this folder. Nothing here comes from memory of the
E1 session.

## What E1 delivered (server only, no directory UI)

- `20260927000100_medical_professional_document_kind.sql`: adds
  `seller_document_kind = 'medical_professional_registration'` in its own migration.
  PostgreSQL only lets a later transaction use a new enum value after the one that
  added it has committed.
- `20260927000200_step_e1_business_directory.sql`:
  - `business_directory_profiles`: a 1:1 extension of a **business** seller (primary
    key `seller_id`), with type `restaurant|cafe|doctor`, languages, cuisines, price
    level, diet flags, specialty and insurance. A `directory_type_fields` check keeps
    each type's fields consistent: doctors have no cuisines, price or diet flags, and
    only doctors have a specialty and insurance.
  - `business_directory_hours`: weekly intervals in Europe/Berlin, with overnight
    support (`opens_at > closes_at`). `directory_is_open()` treats the closing time as
    exclusive.
  - Menu tables for sections and items, allowed for restaurants and cafés only
    (enforced by a trigger).
  - Owner write access through RLS plus the RPCs `owner_upsert_directory_profile`,
    `owner_replace_directory_hours` and `owner_replace_directory_menu`.
  - Public `search_business_directory` and `get_business_directory_detail`. Both
    return only `is_published` profiles whose owner passes `is_verified_seller()`
    **now**. Drafts are visible only to their owner.
  - A seller-scoped public storage bucket, `directory-covers`.
- One UI change: the admin verification queue labels the new document kind
  ("Approbation / Kammernachweis"), in all five languages.

## Doctor verification with `medical_professional_registration`

`is_verified_seller(seller_id)` is the single helper behind the seller badge, the
Step D precise-location gate and directory visibility. E1 replaced its body so that
it evaluates:

```
seller.kind = 'business' AND seller.status = 'approved'
AND an APPROVED 'identity' document
AND (
      ( the seller's directory profile currently has type = 'doctor'
        AND an APPROVED 'medical_professional_registration' document )
   OR ( there is NO doctor profile
        AND an APPROVED 'business_registration' document )
)
```

- **Evaluated on every call.** Nothing is cached or stored. Changing a profile from
  doctor to café immediately drops verification unless an approved business
  registration also exists. Changing to doctor requires the medical proof. The E1
  acceptance test covers both directions.
- **Identity stays mandatory** for everyone. For doctors, the medical proof replaces
  the business registration. A generic `other` document never verifies anyone.
- **No circular onboarding.** A doctor can save an unpublished draft before being
  verified; it becomes public only once verification holds.
- **Doctor-specific rules are enforced in the database:**
  - doctors cannot have a menu (trigger and RPC);
  - doctors cannot be reviewed (review trigger);
  - search and detail return `rating_average` and `rating_count` as null for doctors;
  - searching doctors with `p_min_rating` fails with 22023;
  - changing a profile to doctor is blocked while it still has a menu or directory
    reviews.
- **Side effect, approved before implementation:** because the helper is shared, a
  doctor with identity plus medical proof (and no business registration) also counts
  as verified for the marketplace badge and precise location.
- **Gap for E2:** RLS already allows an owner to insert a seller document of any
  kind (`seller_documents_insert_own`), and admins can review the medical proof. But
  the app has **no seller-side document upload screen**, so a doctor cannot submit
  the proof in the app today.

## The reviews discriminator

E1 reuses the existing `reviews` table and seller rating columns instead of creating
new ones. The discriminator is a new enum, `review_context = 'purchase' | 'directory'`,
stored in a new column `reviews.context` (NOT NULL, default `'purchase'`).

- **Existing purchase reviews are unchanged.** Because of the default, existing
  inserts that omit `context` still create purchase reviews, which keep their
  order-item eligibility and `verified_purchase = true` (the test inserts one that
  way).
- **Shape check `reviews_context_target`** (replaces `reviews_kind_target`):
  - `purchase`: requires `order_item_id`, plus the previous kind rules (a product
    review has a product; a seller review has no product).
  - `directory`: `kind = 'seller'`, and `order_item_id`, `product_id`, photos and
    `verified_purchase` must all be absent or false. `order_item_id` became nullable
    only for this case.
- **One directory review per user per business:** a partial unique index on
  `(reviewer_id, seller_id) WHERE context = 'directory'`. `upsert_directory_review`
  uses it to edit the existing review.
- **Server-controlled fields** (`protect_review_fields` trigger, for non-admins):
  - On insert: `reviewer_id` is set to `auth.uid()`, `status` to `published`, and
    `verified_purchase` to `context = 'purchase'`. A client cannot claim a purchase.
  - On update: context, kind, target, reviewer and verified flag cannot change. A
    directory review may only switch between `published` and `hidden`.
- **Eligibility** (`validate_directory_review_write` trigger): a directory review
  needs a published, currently verified restaurant or café (fast food was added in
  E1.5), and the owner cannot review their own business. Doctors, unverified
  businesses and owners get 23514.
- **RLS:**
  - SELECT shows published directory reviews only while the business is still
    published and verified.
  - INSERT allows either the purchase path or a directory path with no purchase claim.
  - The old DELETE policy was removed. `delete_directory_review` hides the review
    instead of deleting it, so any `reports.review_id` keeps its target (a physical
    delete would violate the reports check constraint).
- **Aggregates:** `recalculate_review_aggregates` now holds a per-seller advisory
  lock and runs its update without the caller's JWT claims.
  **It does not filter by context.** `sellers.rating_average` and `rating_count` blend
  purchase seller reviews and directory reviews. The E1 test asserts this on purpose
  (4.5 from one purchase 5 and one directory 4). For a business that sells in the
  marketplace *and* runs a restaurant, the rating is one combined number. That was the
  approved "reuse the seller rating" design, but it is worth a conscious decision
  before E3 shows ratings.
- Review text follows the pre-existing rule: null, or 3–3000 characters.

## Verification at E1 close

- `supabase/tests/step_e1_business_directory.sql` passed through `ROLLBACK`
  (`acceptance-output.txt`). Regressions B, C, D map, D postal and admin passed
  (`regression-sql-output.txt`).
- `flutter analyze` was clean; `flutter test` passed 262/262.
- Both migrations were applied with direct `psql`, so they have no rows in the
  migration ledger (same caveat as B–D).

## Changes made to E1 objects since E1 (during E1.5)

- `fast_food` was added to `directory_business_type` and treated like restaurant and
  café in:
  - `directory_type_fields`
  - the menu trigger and `owner_replace_directory_menu`
  - `validate_directory_review_write`
  - the `reviews_select_visible` policy
- `search_business_directory` now also returns unclaimed OSM imports.
  `get_business_directory_detail` gained the keys `source`, `is_claimed`, `place_id`,
  `reviews_enabled` and `has_hours`.
- **E1 acceptance test.** It first used a language filter to hide the imports.
  Following the request that tests not depend on local data, it now:
  - pages through the whole search result with `pg_temp.search_all()` and asserts on
    fixture ids: restaurant `…001` and doctor `…002` are present, unverified café
    `…003` is absent;
  - restricts the anonymous direct-read checks (profiles and menu sections) to the
    three fixture seller ids, instead of counting all rows in the table.
