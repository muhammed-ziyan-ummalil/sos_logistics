# soslogistics_flutter — CLAUDE.md

Flutter mobile app for Logistics: Drivers and Vehicle Owners.
Package: `sossss_logistics`
API base: `https://api.sossss.net/api/logistics/` (legacy) + `https://api.sossss.net/api/logistics/v2/` (current)

## Stack
- Flutter SDK ^3.5.4
- State: `flutter_bloc ^9.1.1`
- HTTP: `dio ^5.8.0+1` + `pretty_dio_logger`
- Storage: `flutter_secure_storage ^9.2.2` (JWT tokens — encrypted), `shared_preferences ^2.5.3` (non-sensitive metadata)
- UI: `flutter_screenutil ^5.9.3`, `google_fonts ^6.2.1`
- Firebase: REMOVED — needs flutterfire configure with real Firebase project before re-adding

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
    firebase_notification_service.dart  — stub, Firebase not configured
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
- Firebase fully removed — `firebase_options.dart` is a stub placeholder
- Both legacy API (`/api/logistics/`) and v2 (`/api/logistics/v2/`) used — v2 is the active one
- Owners get a temp password on driver creation — `TempPasswordSheet` shows it once
- `must_reset_password=1` blocks all routes until driver resets via `/api/logistics/v2/auth/reset-password`
- User may have both `driver` and `owner` roles — `v2_selected_role` tracks which mode they're operating in
