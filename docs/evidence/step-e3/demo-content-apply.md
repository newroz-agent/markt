# E3.0 local demo content — apply, local-target guard, iOS capture (2026-10-07)

Follows `demo-content-dryrun.md`. Times are UTC.

## Apply (one approved run)

- The seed was applied exactly once to the effective local database after per-run
  approval, in the session before this one. It was not applied again.
- Live check on 2026-10-07: products 55 (20 `e3d0`, 52 active), product_images 52
  (20 `e3d0`), sellers 14 (4 `e3d0`), auth.users 12 (4 `e3d0`), `e3d0/` Storage objects 0.
  That is the dry-run baseline 35/32/10/8 plus 20/20/4/4. No `e3_demo_dryrun_*` clone
  database remains.

## Demo images are hotlinked Pexels URLs

`product_images.image_url` for all 20 demo rows points directly at `images.pexels.com`.
No image is downloaded or stored in Zêrîn Storage, and the app fetches each photo from
Pexels at view time. `storage_path` (`e3d0/<n>/primary.jpg`) is a placeholder with no
object behind it. Each product keeps its Pexels photo page in
`specifications.demo_image_source_url`. This is local demo content only and must never
reach the remote project.

## Local-target guard (added 2026-10-07, no data write)

- `supabase/snippets/step_e3_demo_local_guard.sql` is included by both the seed and the
  cleanup before `begin`. With `ON_ERROR_STOP`, it raises (psql exit 3) unless the
  client target is `127.0.0.1:54322`, the database is `postgres` or `e3_demo_dryrun_*`,
  and the server's own address equals the `supabase_db_flutterapp` container IP.
  The earlier `-v e3_local_demo=true` flag only checked a variable and exited 0.
- `tools/demo/e3_local_demo.sh` checks the following before connecting: Docker context
  `desktop-linux`, a running `supabase_db_flutterapp`, host port 54322 published by
  that container's 5432, and exactly one container IP. It passes that IP to the guard
  and unsets every `PG*` variable (for example `PGHOSTADDR`, `PGSERVICE`) so libpq
  cannot redirect the fixed URL.
- `tools/demo/cleanup_e3_demo.py` refuses to run without the IP that only the wrapper
  exports.
- Verified in read-only sessions (`default_transaction_read_only=on`), all before
  `begin`:

  | Case | Result |
  | --- | --- |
  | seed without the IP variable | refused, exit 3 |
  | seed with only the old `e3_local_demo=true` | refused, exit 3 |
  | seed with a wrong IP | refused, exit 3 |
  | seed through `localhost` instead of `127.0.0.1` | refused, exit 3 |
  | cleanup with a wrong IP, and without the variable | refused, exit 3 |
  | guard alone, correct local target | passes, exit 0 |
  | wrapper without `E3_DEMO_APPROVED=1` | refused, exit 2 |
  | wrapper with a nonlocal database name | refused, exit 2 |
  | cleanup script called directly | refused, exit 1 |

  The wrapper's Docker checks were run under macOS bash 3.2 in a copy cut off before
  psql. They resolved IP `172.18.0.12` and cleared injected `PGHOSTADDR`/`PGSERVICE`;
  a missing container and an unpublished port were refused with exit 2. The wrapper's
  full write path was not run again.

## Original staged changes in this checkout (not E3)

These existed before E3 and are excluded from every E3 commit unless separately
approved. E3 commits use explicit pathspecs.

Staged (`git diff --cached --name-status`):

```
A	.kiro/settings/cli.json
A	.scratch/step_d_closeout_report.html
A	semantic-review/2026-09-21-004210-pr-5.md
A	semantic-review/2026-09-30-202843-pr-0.md
A	zerin/zerin.xcodeproj/project.pbxproj
A	zerin/zerin.xcodeproj/project.xcworkspace/contents.xcworkspacedata
A	zerin/zerin.xcodeproj/project.xcworkspace/xcuserdata/lawand.xcuserdatad/UserInterfaceState.xcuserstate
A	zerin/zerin.xcodeproj/xcuserdata/lawand.xcuserdatad/xcschemes/xcschememanagement.plist
A	zerin/zerin/Assets.xcassets/AccentColor.colorset/Contents.json
A	zerin/zerin/Assets.xcassets/AppIcon.appiconset/Contents.json
A	zerin/zerin/Assets.xcassets/Contents.json
A	zerin/zerin/ContentView.swift
A	zerin/zerin/zerinApp.swift
A	zerin/zerinTests/zerinTests.swift
A	zerin/zerinUITests/zerinUITests.swift
A	zerin/zerinUITests/zerinUITestsLaunchTests.swift
```

Unstaged tracked modifications (`git diff --name-status`):

```
M	ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved
M	zerin/zerin.xcodeproj/project.xcworkspace/xcuserdata/lawand.xcuserdatad/UserInterfaceState.xcuserstate
```

The uncommitted `dart_defines.json` currently points `SUPABASE_URL` at a
`trycloudflare.com` address. The capture did not use it; it used
`--dart-define-from-file` with `http://127.0.0.1:54321` and the local anon key from
`supabase status`. The file was left unchanged.

## iOS capture (navigation only)

- Device: iPhone 17 Pro simulator `CFF133B6-F73A-4335-A497-5244B15D1C39`, iOS 26.1
  (23B86). Harness `integration_test/step_e3_demo_live_test.dart`, driver
  `test_driver/step_e3_demo_driver.dart`.
- Read-only by construction. The client is anonymous, and the harness asserts a local
  Supabase host and no current user. `recordProductView` requires a signed-in user, so
  the detail view writes nothing. The only state set is the on-device onboarding flag.
  The device-location service is overridden as unavailable, so no permission prompt
  appears and the map uses its Berlin fallback.
- Each screenshot waits for real content: demo titles in every category, the newest
  demo deal on Home, and `e3d0` listings in the map controller. It also waits until no
  image skeleton is onstage. All 20 hotlinked demo images are precached first, and the
  run fails if any fails to load. German Home is scrolled so the Angebote title sits in
  the upper half, and the harness asserts that. The driver rejects any two
  byte-identical screenshots.
- Earlier screenshots from the interrupted session were discarded. Seven category
  shots there were byte-identical (297,571 bytes) because they were taken before the
  content loaded.

| Run | Time | Outcome |
| --- | --- | --- |
| 1 | 22:16–22:19 | Failed: map wait. The location prompt never resolved. |
| 2 | 22:20–22:22 | Driver rejected it: all 13 captures were blank white, because the leftover location prompt kept the app inactive. Simulator rebooted to clear the prompt; no permission was answered. |
| 3 | 22:24–22:25 | Passed, but hotlinked images had not painted and German Home did not show Angebote. Not used. |
| 4 | 22:29–22:31 | **PASS**: 13/13 checks, 1/1 test, 13 distinct screenshots, 20/20 demo images loaded. |

Database before and after: an exact row count and an MD5 of all rows were taken for
every table in `public`, `auth`, and `storage` (86 tables). The results were identical
before run 1 and after each of runs 1–4; see `capture-db-snapshot.txt`. Query:

```sql
select n.nspname || '.' || c.relname,
  (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', n.nspname, c.relname), false, true, '')))[1]::text,
  (xpath('/row/h/text()', query_to_xml(format('select md5(coalesce(string_agg(x::text, %L order by x::text), %L)) as h from %I.%I x', E'\n', '', n.nspname, c.relname), false, true, '')))[1]::text
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('r', 'p') and n.nspname in ('public', 'auth', 'storage')
order by 1;
```

Screenshots in `ios/` (1206×2622): `step_e3_demo_home_angebote`,
`step_e3_demo_category_{anzuege, goldschmuck, silberschmuck, eheringe,
saiteninstrumente, schlaginstrumente, gewuerze-importwaren, suesswaren}`,
`step_e3_demo_listing_detail`, `step_e3_demo_map`, `step_e3_demo_home_ku`,
`step_e3_demo_home_ar`. The results are in `ios/results.json`.

## Known demo-content gap

The two private demo sellers render as `e3d0-demo-1` and `e3d0-demo-2` (their
person/profile name), not "Mira Kaya" or "Baran Demir" (`sellers.shop_name`, which the
business identities use). Fixing this is a local data write and needs its own
dry-run and approval.
