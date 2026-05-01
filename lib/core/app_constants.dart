class AppConstants {
  static const String appName    = 'SOSSSS Logistics';
  static const String baseUrl    = 'https://api.sossss.net/api/logistics/';
  static const String v2BaseUrl  = 'https://api.sossss.net/api/logistics/v2/';
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}

class StorageKeys {
  // Legacy
  static const String accessToken      = 'driver_access_token';
  static const String driverName       = 'driver_name';
  static const String driverPhone      = 'driver_phone';
  static const String driverId         = 'driver_id';
  static const String ownerAccessToken = 'owner_access_token';
  static const String ownerName        = 'owner_name';
  static const String ownerPhone       = 'owner_phone';
  static const String ownerId          = 'owner_id';
  static const String userRole         = 'user_role';
  // V2
  static const String v2Token        = 'v2_access_token';
  static const String v2UserId       = 'v2_user_id';
  static const String v2UserName     = 'v2_user_name';
  static const String v2UserPhone    = 'v2_user_phone';
  static const String v2Roles        = 'v2_roles';
  static const String v2MustReset    = 'v2_must_reset';
  static const String v2OwnerId      = 'v2_owner_id';
  static const String v2OwnerStatus  = 'v2_owner_status';
  static const String v2DriverId     = 'v2_driver_id';
  static const String v2DriverStatus = 'v2_driver_status';
  static const String v2SelectedRole = 'v2_selected_role';
}

class UserRole {
  static const String driver = 'driver';
  static const String owner  = 'owner';
}

class AppRoutes {
  // Legacy
  static const String splash         = '/';
  static const String roleSelection  = '/role-selection';
  static const String login          = '/login';
  static const String home           = '/home';
  static const String ownerHome      = '/owner-home';
  static const String activeOffer    = '/active-offer';
  static const String activeDelivery = '/active-delivery';
  static const String pickupOtp      = '/pickup-otp';
  static const String dropOtp        = '/drop-otp';
  // V2
  static const String v2PasswordReset  = '/v2/password-reset';
  static const String v2NotAnOwner     = '/v2/not-an-owner';
  static const String v2NotADriver     = '/v2/not-a-driver';
  static const String v2OwnerRegister  = '/v2/owner/register';
  static const String v2OwnerPending   = '/v2/owner/pending';
  static const String v2OwnerDashboard = '/v2/owner/dashboard';
  static const String v2DriverDisabled = '/v2/driver/disabled';
  static const String v2AddDriver      = '/v2/owner/add-driver';
  static const String v2DriverList     = '/v2/owner/drivers';
  static const String v2VehicleList    = '/v2/owner/vehicles';
}
