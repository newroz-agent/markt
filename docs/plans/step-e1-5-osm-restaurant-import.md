# Zêrîn — Step E1.5: Import Real Berlin Restaurants & Cafés (OpenStreetMap)

> **Status:** Ready to start — E1 closed 2026-09-27 (local DB, 262/262 tests). Run the preflight checks in §0 first.
> **Location:** `docs/plans/step-e1-5-osm-restaurant-import.md`
> **Evidence folder:** `docs/evidence/step-e1-5/`

---

## 0. Preconditions (check before starting)

- [x] E1 closeout accepted (enum + directory migrations `20260927000100`, `20260927000200`).
- [x] **Preflight A — unclaimed rows:** the E1 closeout doesn't say whether directory profiles can exist without an owner. Check the E1 schema. If `owner_id` is `NOT NULL`, or RLS/RPCs assume an owner, E1.5 needs a small migration first. It must not weaken the owner RPCs.
- [x] **Preflight B — `fast_food` type:** confirm which directory types E1 created. If there is no `fast_food` type, stop and ask whether to map it to `restaurant` or add a new type (ARB strings in all five languages).
- [x] **Preflight C — review guard:** E1 allows reviews on restaurants and cafés. Unclaimed OSM entries must reject reviews at the **database** level (RPC/RLS guard), not only in the UI. Add this to the acceptance test.
- [x] **Preflight D — public projections:** confirm the E1 search/detail RPCs return `source` and a claimed/unclaimed flag. They must never return outreach data.
- [x] Local Supabase running via **Docker Desktop**. No `db reset`.
- [x] Remote project is **out of scope** — nothing is prepared or run against it until the ODbL obligations for production have been checked.

**Preflight outcome (2026-09-27):** E1 could not hold ownerless rows (profile keyed on a
verified business seller; public reads gated on `is_verified_seller`; description, phone,
languages, price level required) → separate `directory_imported_places` table. No
`fast_food` type → added as a new type. Review guard holds in the DB (no seller row →
23514). Search/detail now return `source` + `is_claimed`, never outreach data.

## 1. Source rules (non-negotiable)

- **Only source:** OpenStreetMap via the Overpass API. Data is ODbL — allowed with attribution **„© OpenStreetMap-Mitwirkende“**.
- **Forbidden:** scraping or copying anything from Google Maps, Yelp, TripAdvisor, Lieferando, Instagram or business websites — no name lists, ratings, reviews, photos, descriptions or menus from those sources.
- **Overpass usage policy:** one bounded query, reasonable timeout (≤ 180 s), no retry loops hammering the server.
- Save the raw response as a **dated snapshot** (e.g. `tools/osm/snapshots/berlin-food-YYYY-MM-DD.json`) so re-imports work from the snapshot without re-querying.
- If the agent's sandbox cannot reach the network: write the script and give the exact command for Lawand to run it himself.

## 2. Scope v1

**Area:** Berlin administrative boundary (`boundary=administrative`, `admin_level=4`, `name=Berlin`).

**Include:** `amenity=restaurant`, `amenity=cafe`, `amenity=fast_food` — **only** where `cuisine` matches the community focus:

`kurdish, turkish, syrian, lebanese, arabic, iraqi, persian, middle_eastern, kebab, falafel`

- `cuisine` is often multi-valued (`turkish;kebab`) — match if **any** value is in the list (split on `;`, trim, lowercase).
- ⛔ **Checkpoint:** show the final cuisine list and the count per cuisine **before** importing anything into the database.

**Exclude:** doctors (self-registration only), shops, events, jobs, and any element without a `name`.

Draft Overpass query (single request):

```
[out:json][timeout:180];
area["boundary"="administrative"]["admin_level"="4"]["name"="Berlin"]->.berlin;
nwr["amenity"~"^(restaurant|cafe|fast_food)$"]["name"]["cuisine"](area.berlin);
out center tags;
```

(Cuisine filtering happens in the script, so the count per cuisine can be reviewed from the snapshot.)

## 3. Field mapping

Import **only** what OSM provides:

| App field | OSM source |
|---|---|
| name | `name` |
| type | `amenity` → restaurant / cafe / fast_food (mapped to the app's directory types) |
| coordinates | node `lat/lon`, or `center` for ways/relations |
| address | `addr:street`, `addr:housenumber`, `addr:postcode`, `addr:city` |
| phone | `phone` / `contact:phone` |
| website | `website` / `contact:website` |
| cuisine | `cuisine` (filtered values) |
| diet flags | `diet:halal`, `diet:vegetarian`, `diet:vegan` (`yes`/`only` → true; else null) |
| opening hours | `opening_hours` — **only if it parses cleanly** (see below) |

**Opening hours:** import only if the OSM string parses cleanly into our weekly structure. Ambiguous or unsupported syntax (`PH`, `SH`, `sunrise`, week numbers, date ranges, comments, `"by appointment"`, `off` exceptions we can't represent, etc.) → leave hours **empty**. **Never guess.** Log every rejected string for the report.

**Do NOT create:** ratings, reviews, menus, photos, descriptions. Use the type's placeholder cover image.

**Every row:** `source='osm'`, `osm_type`, `osm_id`, `imported_at`, no owner. Unique key on `(osm_type, osm_id)`.

## 4. Behavior in the app

- Unclaimed entries appear in directory search and on detail pages.
- Detail page shows a clear localized note: **„Nicht verifiziert · Daten © OpenStreetMap-Mitwirkende“**.
- No verified badge, no review UI, no menu, no chat button. Call, website and directions are fine.
- OSM attribution added to the app's legal/about area too.
- All new strings in **all five ARB files** (de, ku, en, ar, tr) — no hardcoded strings.

## 5. Outreach contacts (internal, admin-only)

Goal: contact owners of imported places so they can claim their page and add their own photos and menu — or ask to be removed.

**Collection**
- Emails **only** from OSM tags `email` / `contact:email`. No scraping of websites, Google or any other source.
- Entries without an email: keep OSM `website` and `phone` for manual lookup.

**Table** (separate, never in the public directory entry): entry reference, email, source (`osm`), collected_at, outreach status (`not_contacted` | `contacted` | `claimed` | `declined` | `removal_requested`), contacted_at, admin notes.
- **RLS: admins only.** Never exposed to `anon`/`authenticated` or any public RPC. Proven in the SQL acceptance test.

**Opt-out & removal**
- Admin action marks a place `declined` / `removal_requested`, **hides its entry immediately**, and adds `osm_type + osm_id` to a **suppression list**.
- Every future re-import respects the suppression list — a removed business must never reappear.

**Export**
- Admin-only CSV export: name, cuisine, address, email or website/phone, status.

**No automated email sending** in this step — no mail service, no bulk send. Sending stays a manual decision after the legal check (UWG/DSGVO).

## 6. Import mechanics

- Idempotent import script in `tools/` or `supabase/snippets/`, clearly named (e.g. `tools/osm/import_berlin_food.*`), keyed on `osm_type + osm_id`.
- Re-runs **update unclaimed rows only**; **never touch entries already claimed** by an owner.
- **Never delete automatically** — report elements that vanished from OSM instead.
- Suppressed `osm_type + osm_id` are skipped before insert/update.
- **Local database only.**

## 7. Closeout report

- [x] Counts per type and per cuisine.
- [x] How many have parseable opening hours, phone, website, and an OSM email.
- [x] 5 sample rows (emails masked, e.g. `in***@example.de`).
- [x] SQL proof: outreach emails unreadable for `anon` and `authenticated`.
- [x] Proof that a suppressed `osm_id` is not re-imported.
- [x] Re-run proof: second run changes **0 claimed rows** and updates only as expected.
- [x] Tests for the import mapping: hours parsing (incl. unparseable cases) and cuisine filter (incl. multi-value `;` cases).
- [ ] Real iOS screenshots in `docs/evidence/step-e1-5/`: directory list with imported entries; one unclaimed detail page showing the unverified/attribution note.

## 8. Standing rules

- Docker Desktop only; **no `db reset`**.
- Migrations applied via psql → note the migration-ledger caveat in the report.
- No hardcoded strings; all copy in the five ARB files.
- Nothing against the remote Supabase project.
