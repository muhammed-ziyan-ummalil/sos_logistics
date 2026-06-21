# soslogistics_flutter — CLAUDE.md

Flutter mobile app for Logistics: Drivers and Vehicle Owners.
Package: `sossss_logistics`
API base: `https://api.sossss.net/api/logistics/` (legacy) + `https://api.sossss.net/api/logistics/v2/` (current)

## Stack
- Flutter SDK ^3.5.4
- State: `flutter_bloc ^9.1.1`
- HTTP: `dio ^5.8.0+1` + `pretty_dio_logger`
- Storage: `flutter_secure_storage ^9.2.2` (JWT tokens — encrypted), `shared_preferences ^2.5.3` (non-sensitive metadata)
- UI: `flutter_screenutil ^5.9.3`, `google_fonts ^6.2.1` (Plus Jakarta Sans)
- Theme: emerald `AppDesignTokens` (light+dark, Material3) in `lib/core/app_theme.dart` — ported from sosfarmer/sosagent (primary `#1F6F5B` light / `#34D399` dark, teal accent `#2DD4BF`). Legacy `AppColors`/`AppLightColors`/`AppTheme.x(context)` kept as back-compat aliases repointed to emerald tokens. Reusable widget library in `lib/widgets/` (barrel `widgets.dart`): SosButton, SosCard, SosAppBar, SosTextField, SosChip, SosBottomNav, SosBottomSheet, LoadingOverlay, SkeletonBox, EmptyState, ErrorState, StatTile, WalletBalanceCard, SosLogoMark. All screens redesigned to this system (UI redesign 2026-06-21, branch `ui-redesign-emerald`).
- Firebase: FCM WIRED (firebase_core/firebase_messaging/flutter_local_notifications). Project `sos-6b1be`, applicationId `com.sossss.logistics`. ⚠️ Needs `google-services.json` via `flutterfire configure --project=sos-6b1be` (Android) — build fails on its absence; `main.dart` init is guarded so the app still runs without it. Token sync: unified `POST /api/auth/update-firebase-token` (writes `persons.firebase_token`) + `firebase_token` passed on `auth/login`; do NOT use the legacy `/api/logistics/auth/update-firebase-token` (driver_users). FCM logic in `lib/services/firebase_notification_service.dart`.
- Maps: `android/app/build.gradle.kts` sets `manifestPlaceholders["GOOGLE_MAPS_API_KEY"]` from a gradle property (empty fallback); places-SDK build fix forces `com.google.android.libraries.places:places:3.5.0` in `android/build.gradle.kts`.

## Folder Structure

```
lib/
  main.dart
  core/
    app_constants.dart  — AppConstants (baseUrl, v2BaseUrl), StorageKeys, UserRole, AppRoutes
    app_theme.dart
    theme_controller.dart
  utility/
    api_service.dart    — HTTP client (legacy v1 API)
    shared_preference.dart
  services/
    firebase_notification_service.dart  — FCM impl (permission, token, onMessage→local notif, token sync)
  widgets/              — shared emerald widget library (barrel: widgets.dart)
  Bloc/
    Auth/               — AuthCubit, DriverAuthCubit, OwnerAuthCubit, PasswordResetCubit
    ActiveDelivery/
    Availability/
    Fleet/              — FleetDashboardCubit, DriverDetailCubit
    History/
    Offer/
    OwnerBankDetails/
    OwnerDrivers/       — AddDriverCubit
    OwnerOnboarding/    — OwnerRegisterCubit
    OwnerProfile/
    OwnerVehicles/
    OwnerWallet/
  Model/
    delivery_model.dart
    driver_model.dart
    earnings_model.dart
  Screens/
    auth/               — login, role_selection, splash, password_reset, not_a_driver, not_an_owner
    delivery/           — active_delivery_screen, otp_entry_sheet
    driver/             — driver_disabled_screen
    history/
    home/               — driver home (offer feed)
    offer/              — offer_screen
    owner/              — owner dashboard, fleet management, account, drivers, vehicles
      register/         — owner_register_screen
      account/          — wallet, analytics, bank details, edit profile, support, about, privacy
      drivers/          — add_driver, drivers_list, driver_detail, temp_password_sheet
      vehicles/         — owner_vehicles_screen
    profile/            — driver profile screen
```

## Auth Flow (v2 JWT)

```
SplashScreen → reads v2_access_token from SharedPreferences
  → if missing → RoleSelectionScreen → LoginScreen
  → if present → decode roles → route to Driver or Owner home
  → if must_reset=true → PasswordResetScreen

LoginScreen POST /api/logistics/v2/auth/login → JWT
  → stores: v2_access_token, v2_userId, v2_roles, v2_OwnerId/v2_DriverId
  → routes by role
```

## Storage Keys

JWT tokens → `flutter_secure_storage` (encrypted). Metadata → `SharedPreferences`.

```dart
// Secure storage (encrypted):
v2Token       = 'v2_access_token'
v2UserId      = 'v2_user_id'
v2Roles       = 'v2_roles'          // JSON-encoded list
v2MustReset   = 'v2_must_reset'
v2OwnerId     = 'v2_owner_id'
v2OwnerStatus = 'v2_owner_status'
v2DriverId    = 'v2_driver_id'
v2DriverStatus= 'v2_driver_status'
v2SelectedRole= 'v2_selected_role'  // when user holds both roles
```

## DB Tables Owned

None. API consumer.

## How to Run Locally

```bash
flutter pub get
# No flutter_secure_storage — SharedPreferences used for all storage
flutter run
```

## Gotchas

- Token stored in plain SharedPreferences (not encrypted) — known trade-off to avoid Keystore blocking startup
- Firebase FCM wired but `firebase_options.dart` + `android/app/google-services.json` are placeholders until `flutterfire configure --project=sos-6b1be` is run; `main.dart` init is guarded so absence does not crash startup
- Both legacy API (`/api/logistics/`) and v2 (`/api/logistics/v2/`) used — v2 is the active one
- Owners get a temp password on driver creation — `TempPasswordSheet` shows it once
- `must_reset_password=1` blocks all routes until driver resets via `/api/logistics/v2/auth/reset-password`
- User may have both `driver` and `owner` roles — `v2_selected_role` tracks which mode they're operating in
