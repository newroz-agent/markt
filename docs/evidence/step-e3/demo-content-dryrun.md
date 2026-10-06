# E3.0 local demo content — audit and clone dry run (2026-10-06)

## Baseline audit

- Docker context: `desktop-linux`; local API/database only. The effective database had
  35 products (32 active), 32 image rows, 10 sellers, and 8 auth users.
- All eight target leaf categories exist and are active. Each had zero active listings:
  `anzuege`, `goldschmuck`, `silberschmuck`, `eheringe`, `saiteninstrumente`,
  `schlaginstrumente`, `gewuerze-importwaren`, and `suesswaren`. The existing 32 demo
  products are in other categories, so this batch does not duplicate them.
- Berlin, Hamburg, Köln, and München exist in `german_cities`. No `e3d0/` objects
  existed in the local `product-images` bucket.

## Candidate

- `supabase/snippets/step_e3_demo_seed.sql` creates four local fixture accounts with
  random, inaccessible passwords; four approved sellers (two private, two business);
  twenty active products; and one image row per product. Every created UUID and slug
  begins `e3d0`. It uses no Storage uploads.
- Four products each cover Anzüge, Gold/Silber/Eheringe, Musikinstrumente (Saz, Oud,
  Def), Gewürze & Importwaren, and Süßwaren. Prices are in euro cents and nine products
  have a higher compare-at price for Angebote.
- Demo images are hotlinked Pexels URLs: `product_images.image_url` points directly
  at `images.pexels.com`, nothing is downloaded or stored in Zêrîn Storage, and the
  app loads each photo from Pexels at view time. `storage_path` (`e3d0/<n>/primary.jpg`)
  is a placeholder with no object behind it. Each row records its exact Pexels photo
  page in `products.specifications.demo_image_source_url`. All 20 CDN URLs returned HTTP 200
  to read-only HEAD requests. The source pages are visible beside each product row in
  the seed; no Unsplash or other source is mixed into this batch.
- `tools/demo/e3_local_demo.sh` fixes the connection to `127.0.0.1:54322`, requires
  Docker Desktop, refuses arbitrary database names, and requires
  `E3_DEMO_APPROVED=1` for an effective-local write. The SQL also requires the local
  guard. `tools/demo/cleanup_e3_demo.py` deletes any `e3d0/` Storage objects through
  the local Storage API before `step_e3_demo_cleanup.sql` deletes rows. It refuses
  effective-local cleanup without approval and refuses to use the effective Storage
  API while pointed at a clone.

## Clone result

- Created `e3_demo_dryrun_20261006` from `template0`; restored a full `pg_dump -Fc`
  of the effective local database with the Docker PostgreSQL 17 tools and the
  `supabase_admin` role, preserving object ownership and ACLs.
- The seed passed on the clone, then passed again idempotently: 4 users, 4 sellers,
  20 products, 20 image rows, 0 Storage objects. Category group counts were 4 each;
  all 20 were active, had a map point and recorded Pexels source URL. Seller cities:
  private Berlin 5, private Köln 4, business Hamburg 5, business München 6.
- Clone cleanup passed: 20 image rows, 20 products, 4 sellers and 4 users deleted.
  Post-cleanup E3 counts were `0/0/0/0/0` for users/sellers/products/images/objects.
  The final seed text was run once more on the clone and cleaned successfully.
- The clone was dropped. The effective local database remained at 35 products,
  32 image rows, 10 sellers, 8 auth users, and zero `e3d0` products or objects.

## Gate

Outcome: see `demo-content-apply.md`. That file records the one approved apply, the
stronger local-target guard that replaced the `e3_local_demo` flag, and the capture.

At dry-run time, no seed or screenshot harness had run on the effective local database. A separate,
explicit approval is required before the one local apply. After that apply, capture
the requested iOS category, detail, map, German Home Angebote, Kurdish Home, and
Arabic Home screenshots under this evidence directory. The Storage API deletion path
has not been exercised because this image-only-by-URL batch creates no objects.
