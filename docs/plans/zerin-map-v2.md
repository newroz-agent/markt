# Zêrîn — Map v2: Branded Tiles + Image Markers + Layers
### Put this file in docs/plans/. Run only AFTER Step E3 (directory) is closed.

---

## Decision: keep flutter_map
flutter_map renders any Flutter widget as a marker, which makes photo/logo pins
straightforward. Do not switch to Google Maps or Mapbox unless the audit finds a
concrete blocker — if so, stop and explain it before changing anything.

## Standing rules (unchanged)
Docker Desktop only, never Colima; never `supabase db reset`; audit first; migrations via
psql in the ledger caveat with a SQL acceptance test; no hardcoded strings (five ARB
files); formatted Dart, typed errors; evidence under `docs/evidence/map-v2/`.

---

## 1. Production tiles with the Zêrîn look
- Replace the public OpenStreetMap tile servers (not allowed for production apps) with a
  proper tile provider, preferably MapTiler (or Stadia if the audit shows a clear reason).
- A custom style matching the design tokens: petrol surfaces, restrained gold accents,
  warm ivory light mode, and a dark style for dark mode.
- API key via `--dart-define`, never hardcoded or committed. Correct attribution for the
  provider and OpenStreetMap.
- Tell me the provider's free-tier limits and what happens (cost) above them.

## 2. Image markers
- **Listings:** a small rounded thumbnail of the primary photo with the price as a
  compact chip (Airbnb-style). Tapping keeps the existing preview → detail flow.
- **Verified stores and claimed directory entries:** the business logo in a circular
  marker with a gold ring; fallback to initials or a type icon.
- **Unclaimed (OSM-imported) entries:** type icon only (restaurant / café / doctor) —
  they have no photos.
- Clusters keep showing counts; optionally a small stack of 2–3 thumbnails.
- Placeholder while a thumbnail loads; never a blank or broken marker.

## 3. Thumbnails (performance-critical)
- Markers must NEVER load full-size images. Generate a small thumbnail variant
  (around 128 px WebP) at upload time, next to the existing compressed image, and
  backfill thumbnails for existing listings and logos.
- Audit whether Supabase image transformations are available on our plan and what they
  cost; prefer upload-time thumbnails if that avoids ongoing cost.
- Thumbnails follow the same visibility rules as the full images (only approved
  listings, only public business logos).

## 4. Layers
- A layer switcher on /map: Angebote (listings), Geschäfte (verified stores),
  Orte (directory: restaurants, cafés, doctors), each toggleable.
- Directory places use their own server-side radius search from Step E; do not pull all
  rows to the client.

## 5. Privacy (unchanged)
Private listings stay on their jittered city point — a photo on the pin must not change
location precision. Only verified businesses and directory entries get precise points.

## 6. Performance acceptance
- Measure on the real simulator with at least 500 markers across layers: scrolling and
  zooming must stay smooth; report frame timings or a profile summary.
- Images cached; markers outside the viewport not rendered.

## Closeout
Tests for marker selection (listing/store/unclaimed), thumbnail fallback and layer
toggling; real iOS screenshots in light and dark mode, clustered and zoomed-in, with
image markers visible; report tile provider limits/cost.
