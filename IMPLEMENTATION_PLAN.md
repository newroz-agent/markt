# DÛKAN — Implementation Plan (Phase 0)

Created: 2026-09-07 · Based on live audit of this worktree (branch `master`, HEAD `8161b52`, 22 modified + 6 new files from Phase 1 chat, all green).

Legend: ✅ complete · 🟡 partial · 🔴 missing · ⚠️ broken · 🟦 infrastructure only

---

## 0. Audit Summary (source of truth: code + tests, not filenames)

### Worktree
- Branch `master`, HEAD `8161b52 wip: chat slice, category products, unified listing moderation`.
- Uncommitted: Phase 1 chat slice (22 files, +1160/−458) + new chat migrations/tests. Consistent, buildable.
- Two agent worktrees (`.kilo/worktrees/*`) at same commit, clean.
- Generated files fresh: `build_runner`, `go_router_builder`, `gen-l10n` all in sync.

### Build status (verified this session)
- `flutter pub get` ✅ · `flutter analyze` ✅ 0 issues · `flutter test` ✅ 111/111 ·
- `flutter run --dart-define-from-file=dart_defines.json` ✅ launches on iPhone 17 Pro simulator.
- Blockers: **none**. No new env vars needed.

### Feature matrix
| Feature | Status | Notes |
|---|---|---|
| Auth | ✅ | Email + Apple/Google, guards |
| Home feed | ✅ | Live campaigns/categories/rails; "nearby/map/recently viewed" sections 🔴 |
| Categories | 🟡 | 51 cats/11 roots live; subcategory drilldown works; search + ku columns missing |
| Product detail | 🟡 | Live core; gallery/reviews/share/report/similar missing; CTA = chat ✅ |
| Chat + Inbox (Phase 1) | ✅ | Realtime, unread badges, product card, system msg, read tracking, idempotent send |
| Sellers (browse/profile) | 🔴 | No screens/routes |
| Sell flow | 🔴 | Placeholder screen only; SQL unified+moderation done |
| Favorites | 🟦 | SQL complete, zero Dart |
| Search | 🟦 | SQL RPCs exist, no UI |
| Map | 🔴 | Only dormant lat/lng columns |
| Cart/Checkout/Orders/Payments | 🟦 legacy | SQL + static screens + `flutter_stripe` dep; **zero wired Dart** |
| Notifications | 🟦 | SQL + prefs UI; no center/FCM |
| Admin/moderation | 🔴 UI | SQL live-verified; no admin frontend |
| Subscriptions | 🔴 | Intentionally deferred (Apple IAP later) |

### Supabase matrix (12 migrations)
- Core: profiles ✅, sellers ✅, products ✅ (+FTS, lat/lng), categories ✅ (de/en/ar/tr, no ku), product_images ✅ — all RLS+indexes+triggers, used by UI.
- Messaging: chats/messages ✅ hardened by `20260907000100` (RPC-only chat writes, read_at-only message updates, atomic German system message + product card seeding) + `20260907000200` (`get_chat_inbox` projection with buyer name/avatar, earliest-product pin, unread counts). **⚠️ NOT yet applied to the linked remote project — required manual step.**
- Moderation: unified listing `pending_review` flow ✅ live-verified; private auto-approval removed.
- Legacy commerce: orders/payments/Stripe columns/enums — 🟦 isolated, unused by any active flow; **do not delete, document only**.
- Favorites/reports/notifications/social-promotion: 🟦/🔴 per matrix above.

### Routing (type-safe go_router)
Existing: `/`, `/onboarding`, `/auth`, `/legal/:document`, `/privacy`, `/notifications`, `/products/:productId`, `/categories/:categoryId`, `/inbox`, `/chat/:chatId`.
Missing: `/map`, `/search`, `/favorites`, `/sellers/:sellerId`, `/admin`.

### Localization
de (primary, template), ku (first-class), en, ar, tr. All chat keys present in all 5 ARBs. Gaps: Kurdish absent from DB locale structures; full-route locale symmetry unaccepted.

### Design system
✅ Coherent and reused (petrol/gold tokens, Bricolage/Figtree/IBM Plex Arabic, M3, dark, RTL, AppButton/AppTextField/empty/error states). Extend, never fork.

### Chat (Phase 1) — final state
Complete flow verified in code + 111 tests: tap-driven contact-seller → auth guard → RPC get-or-create (atomic, no duplicates, no `chatId: ""`) → server-seeded German system message + `kind: product` card → real chatId navigation → realtime (no polling) → read tracking → pagination → idempotent retry. Both previously reported build errors (`icon` param, empty chatId) are fixed.

---

## 1. Non-negotiables honored by this plan
Germany-only · unified seller model · everything `pending_review` · no auto-approval · chat-only contact · no product payments/checkout/Stripe activation · subscriptions separate (Apple IAP, later) · city-only public location, privacy enforced server-side · map = city + radius (5/10/20/30/50/100 km + "Überall") · map/list synchronized · server-side geo filtering · Kurdish first-class · realtime chat, no polling · reuse-first.

---

## 2. Phase plan and task breakdown

### PHASE 1 — Finish chat foundation ✅ (code done)
1. Apply `20260907000100_chat_phase1.sql` + `20260907000200_chat_inbox.sql` to linked project. *(manual)*
2. System message wording: implemented text is „…Kommunikation und Zahlung…"; master spec says „…Kommunikation und die Zahlungsabsprachen…". Update the seed text in a small follow-up migration before/with the remote push so newly created chats use the final wording. *(existing chats are not backfilled by design)*
3. Live simulator acceptance: product → Verkäufer kontaktieren → chat → send → realtime receive → badge; de/dark + ar/RTL pass.
4. Update `docs/STATUS.md`.

### PHASE 2 — Categories & subcategories
- Extend seed migration to target 8-root structure (§14 incl. Kultur & Tradition) with parent-child (3rd level optional), add `ku` columns, keep admin-manageable.
- Subcategory navigation UI, condition/sort filters on grid, map view hook (Phase 9).
- Reuse: `categories` table, `CategoryProductsRoute`, existing chips/grid.

### PHASE 3 — Product detail finalization
- Image gallery, favorite toggle (Phase 6 store), share, report (Phase 10), seller card → seller profile, similar listings (same category RPC), more-from-seller.
- CTA stays "Verkäufer kontaktieren".

### PHASE 4 — Seller profiles
- `/sellers/:sellerId`: store/private variants, verification badge only when backed by state, listings grid.
- Reuse `sellers` public identity columns; optional public business contact later.

### PHASE 5 — Search + filters
- Wire existing SQL FTS/RPCs; suggestions, recent searches, pagination, empty states.
- Filters: Preis, Kategorie, Unterkategorie, Zustand, Gewerblich/Privat, Stadt, Entfernung.
- Results: Liste/Grid/Karte toggle sharing one query-state controller.

### PHASE 6 — Favorites + recently viewed
- Favorites screen + toggles over existing `favorites` tables; unavailable-state handling.
- "Zuletzt angesehen": local persistence + server backup, remove/clear.

### PHASE 7 — Unified sell flow
- 11-step flow (§35) over `prepare_seller_write`/products; city-only public location; postal internal; draft → `pending_review`.
- Photos to storage bucket; required-field validation; preview; submit.

### PHASE 8 — Moderation/Admin
- Admin queue (approve/reject+reason/block), seller notifications ("Dein Angebot wurde abgelehnt./freigeschaltet.") via `notifications` tables.
- Contact-data flagging in descriptions (configurable, no silent deletion).

### PHASE 9 — MAP (core)
- Package decision (evaluate `google_maps_flutter` vs `flutter_map`+`maplibre` for iOS perf/cluster/styling/licensing; document choice).
- SQL: PostGIS or geodesic RPCs `find_listings_near_location` / `find_listings_in_viewport`; city-level/privacy-safe coords for private sellers enforced server-side; Germany-only filter; approved-only.
- `/map`: Standort suchen, radius chips (5/10/20/30/50/100 km, Überall), Mein Standort (optional permission), price markers, clustering, draggable preview → existing product detail, "Dieses Gebiet durchsuchen" (debounced, explicit), Karte/Liste state persistence.
- Acceptance per §60 checklist + screenshots.

### PHASE 10 — Trust & safety (reports/block UI)
### PHASE 11 — Notifications center (+FCM later, non-blocking)
### PHASE 12 — Social promotion (submit → review → approved)
### PHASE 13 — Apple IAP entitlement (€25/mo + annual; separate from marketplace)

---

## 3. What to reuse (do not rebuild)
Supabase client/bootstrap, clean-architecture feature layers, Riverpod codegen, chat slice end-to-end, categories/products repos + screens, design tokens & core widgets, go_router typed routes, l10n toolchain, all moderation SQL, favorites/reports/notification SQL.

## 4. Intentionally deferred
Stripe/checkout/orders/payments (legacy, isolated) · FCM push · Apple IAP · social promotions · admin frontend beyond moderation · multi-country.

## 5. Manual steps required now
1. `supabase db push` (or apply both `2026090700*.sql`) to the linked remote project.
2. None other — no new env vars.
