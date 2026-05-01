class AppConstants {
  static const String appName = 'SOSSSS Logistics';
  static const String baseUrl = 'https://api.sossss.net/api/logistics/';
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}

class StorageKeys {
  static const String accessToken = 'driver_access_token';
  static const String driverName  = 'driver_name';
  static const String driverPhone = 'driver_phone';
  static const String driverId    = 'driver_id';
}

class AppRoutes {
  static const String splash        = '/';
  static const String login         = '/login';
  static const String home          = '/home';
  static const String activeOffer   = '/active-offer';
  static const String activeDelivery= '/active-delivery';
  static const String pickupOtp     = '/pickup-otp';
  static const String dropOtp       = '/drop-otp';
}
