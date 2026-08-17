# Zerin Project Status

This is the single source of truth for implementation and acceptance status. Update it at the end of every phase.

Last audited: 2026-08-17, against `master` at `0818f3a` plus the current Phase A worktree. Sources checked: typed router, routed screens, repositories, tests, all Supabase migrations, environment setup, and current simulator/Supabase availability.

Status rule: `✅ done` means the complete line was exercised on a simulator or browser with real Supabase data. `🟡 partial` means a live-verified slice works but named scope is still missing. `❌ not started` also covers code or SQL that exists but has not passed that live acceptance bar.

## Backend (SQL)

- ❌ User profiles and auth-user bootstrap - schema/trigger exist; not simulator/browser verified with real Supabase data.
- ❌ Saved German delivery/billing addresses - schema and RLS exist; no routed Flutter workflow or live verification.
- ❌ Business store accounts and public store identity - base seller/private-detail schema exists; no complete store workflow or live verification.
- ❌ Per-store online-payment and contact-to-order modes - required fields/constraints are absent.
- ❌ Store phone/WhatsApp, map location, opening hours, and open/closed state - required schema is absent.
- ❌ Follow stores - follow relationship/schema is absent.
- ❌ Localized two-level category catalog - seeded/admin-editable SQL and client reads exist, but Kurdish columns are absent and live acceptance is pending.
- ❌ Brand catalog - schema and admin RLS exist; no client/admin workflow or live verification.
- ❌ Product catalog, images, stock, condition, VAT, shipping, and status lifecycle - schema exists; end-to-end CRUD/browse acceptance is pending.
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
- ❌ Scheduled localized `ad_campaigns` - uncommitted migration and Home reader exist; migration is not applied/accepted and admin CRUD is absent.
- ❌ Deterministic demo stores/products/images for catalog acceptance - uncommitted seed exists; local Supabase is currently unavailable and the seed is not live verified.
- ❌ RLS and protected storage buckets - broad policies exist for marketplace data/media/documents; full role matrix has not been exercised end to end.
- ❌ Kurdish database locale support - Flutter has `ku`, but `public.app_language` and older localized category/legal structures support only `de/en/ar/tr`.

## Flutter screens

- ❌ Five-tab navigation (`Home · Categories · Stores · Cart · Account`) - shell is routed, but it still shows legacy Sell with a center FAB and has no Stores tab.
- ❌ Onboarding - three-page screen and persistence exist, but copy still promotes selling/private flow and no live acceptance is recorded.
- ❌ Email registration, sign-in, sign-out, and session restoration - Supabase repository/UI exist; not live verified.
- ❌ Apple and Google sign-in - client calls exist; provider configuration/callback acceptance is unverified.
- ❌ Home catalog - current worktree has campaigns, category rail, new arrivals, deals, stores, loading/error states, and real-data repositories; simulator acceptance is pending.
- ❌ Categories browse - real-data root grid exists; selection, subcategories, products, search, and live acceptance are missing.
- ❌ Search/results/filter/sort experience - not routed or implemented in Flutter.
- ❌ Product detail - current worktree renders core catalog data/store identity; gallery, favorites, reviews, sharing, stock, fulfillment actions, and live acceptance are missing.
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
- ❌ Five app locales (`de`, `en`, `ar`, `tr`, `ku`) - generated app strings and custom Kurdish framework delegates exist; full-screen symmetry and live RTL/Kurdish acceptance are pending.
- ❌ Loading/empty/error/offline states on every screen - shared components and several states exist; coverage is incomplete and offline behavior is not verified.
- ❌ Dark mode, RTL, accessibility, and minimum 44 px targets across every screen - foundations/tests exist; full routed-app acceptance is pending.

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

- ❌ Supabase runtime integration - compile-time URL/key wiring and repositories exist, but local/remote live acceptance is not currently available.
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

- ❌ Locked Zerin brand tokens and bundled typography - palette/fonts/token tests exist, but the complete app has not been visually accepted on simulator/browser.
- ❌ Final app icon and launch assets - launcher configuration/placeholder assets exist; final generated icon set and launch review are incomplete.
- ❌ Environment setup and no-key graceful degradation - tracked docs/template exist; configured and unconfigured builds are not both accepted.
- ❌ Migration replay and deployed-schema parity - replay fixes exist, but the current local Supabase stack is unavailable and the newest catalog migration is unapplied.
- ❌ Automated quality gate - unit/widget tests exist for selected areas; no documented passing full `flutter analyze` + `flutter test` + integration suite for the current worktree.
- ❌ Real-data simulator/browser acceptance suite - no durable end-to-end acceptance suite or current passing run exists.
- ❌ Production German legal content and operator/company data - delivery mechanism exists; final content/data is not established.
- ❌ Privacy/security review - RLS is extensive, but role-matrix, secret handling, deletion/export workers, and abuse testing are incomplete.
- ❌ Accessibility/localization QA - five locales are present, but every route has not been checked for overflow, semantics, RTL, Kurdish dates, and dark mode.
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
- Local Supabase is not running (`supabase status` cannot find `supabase_db_flutterapp`) and no simulator/browser device is currently available, so no feature qualified for ✅ in this snapshot.
