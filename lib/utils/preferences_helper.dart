// lib/utils/preferences_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _keyHasSeenReferral = 'has_seen_referral_screen';

  static Future<bool> hasSeenReferralScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenReferral) ?? false;
  }

  static Future<void> markReferralScreenAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenReferral, true);
  }

  // Optional: Logout / fresh install ke liye reset karna chaho to
  static Future<void> resetReferralFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasSeenReferral);
  }
}