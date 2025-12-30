import 'package:shared_preferences/shared_preferences.dart';

class PreferenceManager {
  static const String _sevaUserIdKey = 'sevaUserId';
  static const String _sevaEmailIdKey = 'emailId';

  static Future<SharedPreferences> get _instance async {
    return SharedPreferences.getInstance();
  }

  static Future<String?> get loggedInUserId async {
    final preferences = await _instance;
    return preferences.getString(_sevaUserIdKey);
  }

  static Future<String?> get loggedInUserEmail async {
    final preferences = await _instance;
    return preferences.getString(_sevaEmailIdKey);
  }

  static Future<bool> setLoggedInUser({
    required String userId,
    required String emailId,
  }) async {
    final preferences = await _instance;
    final a = await preferences.setString(_sevaUserIdKey, userId);
    final b = await preferences.setString(_sevaEmailIdKey, emailId);
    return a && b;
  }

  static Future<bool> logout() async {
    final preferences = await _instance;
    // Remove both the stored logged-in user id and the saved email on
    // explicit logout so the app does not auto-login using a saved email.
    // If callers want to preserve the saved email for convenience they
    // should use a different API.
    final removedId = await preferences.remove(_sevaUserIdKey);
    final removedEmail = await preferences.remove(_sevaEmailIdKey);
    return removedId || removedEmail;
  }
}
