class Constant {
  static const String appName = "Nexstream TV";
  static const String appPackageName = "com.nexstream.prjkt";
  static const String appVersion = "1.0.0";

  // Backend API Configuration (Connecting to same Laravel backend)
  static const String baseUrl = "https://nexstream.biz.id/api/";
  static const String apiToken = "v25dcFLxPGg0MIGu7jkSDIJQTEEDqcZx";

  // Device & Auth
  static String deviceId = "";
  static String? userId;
  static String? userName;
  static String? userEmail;
  static String? userImage;
  static bool isUserLogin = false;

  // TV Video Types
  static const int videoTypeMovie = 1;
  static const int videoTypeTVShow = 2;
  static const int videoTypeCategory = 3;
  static const int videoTypeLanguage = 4;
  static const int videoTypeShorts = 8;
  static const int videoTypeAll = 9;

  // TV Key SharedPreferences
  static const String keyUserId = "tv_user_id";
  static const String keyUserName = "tv_user_name";
  static const String keyUserEmail = "tv_user_email";
  static const String keyUserImage = "tv_user_image";
  static const String keyDeviceId = "tv_device_id";
}
