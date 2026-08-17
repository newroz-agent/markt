# Zerin Project Status

This is the single source of truth for implementation and acceptance status. Update it at the end of every phase.

Last audited: 2026-08-17, against the current Phase A step 1 worktree after initial ledger commit `0cc510d`. Sources checked: typed router, routed screens, repositories, tests, all Supabase migrations, the linked remote Supabase project, and Flutter web browser acceptance with real data in German/dark and Arabic/light.

Status rule: `✅ done` means the complete line was exercised on a simulator or browser with real Supabase data. `🟡 partial` means a live-verified slice works but named scope is still missing. `❌ not started` also covers code or SQL that exists but has not passed that live acceptance bar.

## Backend (SQL)

- ❌ User profiles and auth-user bootstrap - schema/trigger exist; not simulator/browser verified with real Supabase data.
- ❌ Saved German delivery/billing addresses - schema and RLS exist; no routed Flutter workflow or live verification.
- 🟡 Business store accounts and public store identity - three approved stores and their public identity render from live Supabase data; application, ownership, private details, and management workflows are not accepted.
- ❌ Per-store online-payment and contact-to-order modes - required fields/constraints are absent.
- ❌ Store phone/WhatsApp, map location, opening hours, and open/closed state - required schema is absent.
- ❌ Follow stores - follow relationship/schema is absent.
- 🟡 Localized two-level category catalog - 51 active categories and 11 roots were read from live Supabase and the root catalog rendered in German and Arabic; second-level drilldown is missing and Kurdish columns are absent.
- ❌ Brand catalog - schema and admin RLS exist; no client/admin workflow or live verification.
- 🟡 Product catalog, images, stock, condition, VAT, shipping, and status lifecycle - 30 active products with images, prices, VAT, condition, and shipping data were read and rendered live; CRUD and lifecycle transitions are not accepted.
- ❌ Favorites and price snapshots - schema/triggers exist; no routed persistence flow or live verification.
- ❌ Multi-store cart - schema exists; the Flutter cart is still an empty placeholder.
- ❌ Orders and per-store order items - schema/lifecycle SQL exists; routed buyer/seller workflows are absent.
- ❌ Shipping methods, pickup, checkout sessions, and inventory reservations - SQL exists; no live checkout integration.
- ❌ Payment records, allocations, idempotency, and provider-event handling - SQL exists; no server payment implementation or live verification.
- ❌ Stripe Connect commission model - Stripe account/payment columns and `platform_fee_cents` exist, but Express onboarding, destination charges, and configurable default/per-store basis points are absent.
- ❌ German 14-day withdrawal and return workflow - SQL exists; no routed end-to-end UI or live verification.
- ❌ Invoices and protected invoice documents - SQL/storage policies exist; generation and client delivery are not implemented.
- ❌ Product/store reviews, rating aggregates, and review media - SQL/storage policies exist; no routed review workflow or live verification.
- ❌ Buyer-store chat, read state, unread counts, and realtime publication - SQL exists; no Flutter chat workflow or live verification.
- ❌ In-app notifications and user channel preferences - SQL plus settings client exist; notification inbox/delivery is not live verified.
- ❌ Search, suggestions, filters, sorting, radius, recent views, and search history - SQL RPCs exist; no routed search/results experience.
- ❌ Store application, verification documents, and status history - SQL exists; no partner onboarding/admin workflow.
- ❌ Seller dashboard metrics, payouts, and balance ledger - SQL exists; no dashboard or Stripe payout reconciliation.
- ❌ Private-seller compatibility - legacy private-seller auto-approval SQL remains even though the locked app scope is business stores only.
- ❌ Reports and moderation state for stores/products/reviews/content - schema and guard functions exist; no moderation UI or live workflow.
- ❌ Legal documents (`Impressum`, `AGB`, privacy, withdrawal) - published-document SQL and client reader exist; production rows are not live accepted.
- ❌ Consent history, data export, account deletion, and deletion cancellation - SQL/RPCs and client screens exist; export worker/deletion processor and live acceptance are pending.
- ❌ Consent-gated analytics events - SQL/RPC exists; no analytics client or operational pipeline.
- ❌ Legacy `banners` placements - table exists but has no current client/admin ownership path.
- 🟡 Scheduled localized `ad_campaigns` - the migration is applied remotely and three scheduled campaigns render from live data in German and Arabic; deep-link handling and admin CRUD are absent.
- ✅ Deterministic demo stores/products/images for catalog acceptance - three stores and 30 products with images are applied in the linked Supabase project and verified in the browser.
- 🟡 RLS and protected storage buckets - anonymous catalog/category/campaign reads were exercised successfully against the linked project; the full role and protected-document matrix is not accepted.
- ❌ Kurdish database locale support - Flutter has `ku`, but `public.app_language` and older localized category/legal structures support only `de/en/ar/tr`.

## Flutter screens

- ❌ Five-tab navigation (`Home · Categories · Stores · Cart · Account`) - shell is routed, but it still shows legacy Sell with a center FAB and has no Stores tab.
- ❌ Onboarding - three-page screen and persistence exist, but copy still promotes selling/private flow and no live acceptance is recorded.
- ❌ Email registration, sign-in, sign-out, and session restoration - Supabase repository/UI exist; not live verified.
- ❌ Apple and Google sign-in - client calls exist; provider configuration/callback acceptance is unverified.
- ✅ Home live catalog feed - campaigns, category rail, new arrivals, deals, popular stores, and product navigation were browser-verified with real Supabase data in German/dark and Arabic/light.
- 🟡 Categories browse - the real-data root grid was browser-verified; selection, subcategories, category products, and search are missing.
- ❌ Search/results/filter/sort experience - not routed or implemented in Flutter.
- 🟡 Product detail - live product image, VAT-inclusive price, condition, shipping, description, and store identity were browser-verified; gallery, favorites, reviews, sharing, stock, and fulfillment actions are missing.
- ❌ Per-store Buy/Cart versus WhatsApp/Call actions - not implemented.
- ❌ Cart - routed tab is an empty placeholder.
- ❌ Checkout - static screen code exists but is not routed or connected to cart, Supabase, addresses, shipping, or payment.
- ❌ Order confirmation - static screen code exists but is not routed from a real checkout.
- ❌ Orders list/detail, tracking, invoices, cancellation, and returns - static screen code exists but is not routed or backed by repositories.
- ❌ Stores browse tab - no screen or route exists.
- ❌ Store profile with cover/logo/about/location/directions/hours/rating/follow - no screen or route exists.
- ❌ Favorites screen and persistent favorite actions - no routed screen; Home favorite state is local-only.
- ❌ Buyer-store chat/inbox - no screens or routes exist.
- ❌ Notification center - no inbox screen; only preference switches are routed.
- ❌ Account hub - language/theme/auth/legal/privacy tiles work in code, but orders, favorites, addresses, partner-store entry, and live acceptance are missing.
- ❌ `Partnershop werden` onboarding - absent from Account and router.
- ❌ Seller dashboard/catalog/order/payout management - no screens or routes exist.
- ❌ Privacy and DSGVO controls - routed export/delete/cancel/settings UI exists; not live verified with authenticated Supabase data.
- ❌ German legal documents within two taps - routes/readers exist from Account; production data and simulator acceptance are pending.
- 🟡 Five app locales (`de`, `en`, `ar`, `tr`, `ku`) - generated strings and Kurdish delegates exist, and Home was live-verified in German and Arabic RTL; Turkish, Kurdish, English, and full-route symmetry are not accepted.
- ❌ Loading/empty/error/offline states on every screen - shared components and several states exist; coverage is incomplete and offline behavior is not verified.
- 🟡 Dark mode, RTL, accessibility, and minimum 44 px targets across every screen - Home was browser-verified in German/dark and Arabic/light RTL; full routed-app accessibility and sizing acceptance is pending.

## Admin panel

- ❌ Admin application, authentication, and role-gated routing - no admin frontend exists in the repository.
- ❌ Admin overview/dashboard and operational metrics - not started.
- ❌ Category and brand CRUD/reordering/localization - SQL admin policies exist; admin UI is absent.
- ❌ Product catalog CRUD and inventory management - admin UI is absent.
- ❌ Store application review, document verification, approve/reject/suspend - SQL states exist; admin UI is absent.
- ❌ Product, store, review, chat/content, and report moderation - SQL primitives exist; queues/actions/audit UI are absent.
- ❌ Order, refund, return, dispute, and invoice operations - admin UI/server operations are absent.
- ❌ `ad_campaigns` scheduling/preview/CRUD - SQL draft exists; admin UI is absent.
- ❌ Legacy banner management and migration to `ad_campaigns` - not started.
- ❌ Legal-document publishing/versioning/localization - SQL exists; admin editor/publish workflow is absent.
- ❌ User, consent, export, and deletion-request operations - SQL exists; admin workflow/workers are absent.
- ❌ Commission defaults, per-store overrides, Stripe account health, and payout reconciliation - not started.
- ❌ Notification broadcast/outbox operations and analytics reporting - SQL exists; admin UI/workers are absent.

## Integrations (Stripe, FCM, AI)

- 🟡 Supabase runtime integration - configured Flutter web reads live campaigns, categories, stores, and products from the linked project; auth, writes, realtime, storage uploads, and the remaining repositories are not accepted.
- ❌ Stripe Connect Express onboarding and account refresh links - not implemented.
- ❌ Stripe destination-charge checkout with configurable commission - not implemented.
- ❌ Cards, PayPal, Klarna, Apple Pay, and Google Pay - `flutter_stripe` is installed and SQL enums exist; client/server payment flows are not wired.
- ❌ Stripe webhooks, refunds, disputes, payout updates, and idempotent reconciliation - database helper SQL exists; Edge Functions/webhook deployment is absent.
- ❌ FCM/APNs token registration and push delivery - token/outbox SQL exists; Firebase configuration, client registration, and delivery worker are absent.
- ❌ Apple/Google OAuth production configuration and deep-link callback validation - app-side calls exist; console/provider setup is unverified.
- ❌ WhatsApp, phone, and Maps deep links - dependency support exists, but store data/actions are not implemented.
- ❌ AI-assisted catalog creation/enrichment - no AI SDK, server function, prompt, or UI exists.
- ❌ AI moderation/fraud/counterfeit assistance - no AI integration exists; only manual SQL moderation states exist.

## Launch prep

- 🟡 Locked Zerin brand tokens and bundled typography - Home and catalog surfaces were visually accepted in German/dark and Arabic/light; the complete routed app is not accepted.
- ❌ Final app icon and launch assets - launcher configuration/placeholder assets exist; final generated icon set and launch review are incomplete.
- 🟡 Environment setup and no-key graceful degradation - tracked docs/template and a configured web release build are accepted; the unconfigured build path is not browser-verified.
- 🟡 Migration replay and deployed-schema parity - the linked remote project reports the current migration set including the Home catalog migration; local replay is unavailable because the local Supabase stack is down.
- 🟡 Automated quality gate - `flutter analyze` is clean and all 45 unit/widget tests pass for this worktree; no integration suite exists.
- 🟡 Real-data simulator/browser acceptance suite - current Home, Categories, and Product Detail browser runs pass against linked Supabase data; the checks are manual and not a durable automated suite.
- ❌ Production German legal content and operator/company data - delivery mechanism exists; final content/data is not established.
- ❌ Privacy/security review - RLS is extensive, but role-matrix, secret handling, deletion/export workers, and abuse testing are incomplete.
- 🟡 Accessibility/localization QA - German/dark and Arabic/light RTL Home were checked without visible overflow or overlap; every route, Kurdish dates, semantics, and assistive technology remain unaccepted.
- ❌ Performance/offline QA - image caching and graceful repositories exist; cold-start, scrolling, network loss, and recovery are not accepted.
- ❌ Crash/error monitoring and operational alerting - not implemented.
- ❌ Store release builds, signing, metadata, screenshots, privacy declarations, and review submission - not started.
- ❌ Production Supabase, Stripe, OAuth, push, domains/deep links, and admin deployment - not configured or launched.

## Known gaps / tech debt

- `banners` and `ad_campaigns` overlap; choose one canonical placement model, migrate data, and remove the duplicate read/admin paths.
- `prepare_seller_write()` auto-approves private sellers, which conflicts with the locked business-store-only app and should be removed or quarantined as future compatibility.
- Stripe is represented in packages/columns/enums only; no publishable-key initialization, Connect onboarding, destination charge, commission configuration, Edge Function, or webhook is wired.
- The shell still has the removed Sell tab/center FAB and no Stores tab; onboarding also retains seller/private-marketplace language.
- Store fulfilment capability fields, contact details, opening hours, directions data, and store follows are missing from SQL.
- `public.app_language`, category columns, and legal-document locale constraints do not include Kurdish even though Flutter exposes `ku`.
- Root categories are fetched, but category selection/search/results are not connected; Home favorites are ephemeral.
- Checkout/order/return screens are static fixtures outside the router and have no repositories.
- Admin RLS policies are not an admin panel; there is no admin frontend, audit workflow, or operational worker layer.
- The latest Home/demo-catalog migration adds remote image URL columns alongside storage paths; ownership, migration, and production asset policy need consolidation.
- Local Supabase is not running and no iOS simulator runtime is installed; current live acceptance uses the linked remote Supabase project and Flutter web in headless Chrome.
