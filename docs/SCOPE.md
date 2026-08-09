# Zêrîn — Locked Scope Contract

**Model:** Multi-store marketplace with in-app payment. **Stores are the sellers; the app is the broker.**

This file is ground truth for all agents. Do not contradict it.

---

## 1. Commerce
- Cart, checkout, orders are **kept**.
- **Stripe Connect (Express accounts)**: each store is paid directly (destination charges).
- Platform takes a **configurable commission per order** (basis points; per-store override, else platform default).
- German payment methods: **cards, PayPal, Klarna, Apple Pay, Google Pay**.
- Checkout final button: **"Zahlungspflichtig bestellen"**. All prices **inkl. MwSt.** (19% standard / 7% reduced). Shipping disclosed before payment.

## 2. Per-store fulfilment flexibility
Each store independently enables:
- **(a) online payment** — cart/checkout/Stripe path
- **(b) "contact to order"** — WhatsApp deep link + phone call
- **or both**

Product detail renders **only the action buttons its store supports**. A store with neither enabled cannot have active products.

## 3. Store profile pages
Logo, cover image, description, location + **directions (Maps deep link)**, **opening hours** (per weekday, with open/closed now), rating, **follow store**.

## 4. Localization — 5 locales
`de` (**default**), `en`, `ar` (RTL), `tr`, **`ku` (Kurdish Kurmanji, Latin script, LTR)**.
All keys translated **symmetrically** across all 5 ARB files.

> **Critical constraint:** Flutter ships **no** `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` for `ku` (verified against Flutter 3.44.6). Kurdish requires **custom delegates** that reuse English framework strings while our ARB supplies every app-facing string. Never add `ku` to supported locales without these delegates — it throws at runtime.

## 5. Navigation
Bottom tabs (exactly 5, no center FAB): **Home · Categories · Stores · Cart · Account**
- Store onboarding lives in **Account → "Partnershop werden"** ("Become a partner store").
- The old `Sell` tab and the private-seller quick-listing flow are **removed** from the app. `seller_kind` stays in the schema for future use, but the app treats **seller = store (business)**.

## 6. German legal
`Impressum`, `AGB`, `Datenschutzerklärung`, `Widerrufsbelehrung` in Account, reachable within 2 taps. 14-day Widerrufsrecht flow. DSGVO: consent, data export, account deletion.

---

## Existing codebase facts (verified — do not re-derive)

- Package name: `zerin_marketplace`. Imports MUST be `package:zerin_marketplace/...` (lint `always_use_package_imports`).
- Flutter 3.44.6 / Dart 3.12.2.
- **Design system exists** — `lib/core/theme/theme.dart` exports `AppColors, AppSpacing, AppRadius, AppElevation, AppMotion, AppSizes, AppDurations`, typography + theme extensions. **Never hardcode colors, sizes, durations, or radii.**
- **Widgets exist** — `lib/core/widgets/widgets.dart` exports `AppButton, AppTextField, AppChip, AppBottomSheet, AppDialog, AppSkeleton(Box), AppSnackBar, AppState (empty/error/offline), CategoryCard, ProductCard, PressScale`. **Reuse; do not duplicate.**
- **Localization** — `lib/l10n/l10n.dart` gives `context.l10n`. ARB dir `lib/l10n/`, template `app_de.arb`, `required-resource-attributes: true` (every key needs an `@key` entry with a `description` in the template), `use-named-parameters: true`. 145 keys currently, symmetric across de/en/ar/tr.
- **Router** — `lib/app/router/app_router.dart`, typed `go_router` via `@TypedGoRoute` + `go_router_builder`. Generated extensions provide `.go(context)` / `.push(context)` / `.location`. Existing routes: `/`, `/onboarding`, `/auth`, `/legal/:document`.
- **Auth** — `AuthRepository` interface + `SupabaseAuthRepository` + `UnconfiguredAuthRepository` fallback. `authRepositoryProvider` in `lib/features/auth/presentation/controllers/auth_controller.dart`.
- **DB is largely built already** — `supabase/migrations/` has 36 tables, 25 enums, 57 functions, 121 RLS policies, 3 storage buckets (`product-images`, `avatars`, `chat-media`). **Read the existing migrations before writing SQL. Extend; never recreate or drop existing objects.**
  - `sellers` already has: `id, user_id, kind, status, shop_name, slug, bio, avatar_path, banner_path, city, response_time_minutes, rating_average, rating_count, approved_at, rejection_reason`.
- Existing screens named `*_foundation_screen.dart` are **placeholders** to be replaced.
- Codegen: `dart run build_runner build --delete-conflicting-outputs`. Riverpod generator v2 (`@riverpod`), freezed 2.x, json_serializable 6.x.
- Config via `--dart-define`, read in `lib/core/config/app_environment.dart`. **The app must run and be demoable with NO keys set** (graceful degradation), and go live when keys are provided.

## Style rules (enforced by `analysis_options.yaml`)
`always_use_package_imports`, `prefer_single_quotes`, `require_trailing_commas`, `sort_constructors_first`, `prefer_final_locals`, `directives_ordering`, `unawaited_futures`, `avoid_redundant_argument_values`, strict casts/inference/raw-types.

Every screen ships **loading (skeleton) / empty / error / offline** states, ≥44px touch targets, semantic labels, and is verified in **dark mode and RTL**.
