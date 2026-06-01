import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._init();
  ProfileService._init();

  static const _kName = 'profile_name';
  static const _kEmail = 'profile_email';
  static const _kAge = 'profile_age';
  static const _kWeight = 'profile_weight';
  static const _kHeight = 'profile_height';
  static const _kHydrationMl = 'hydration_ml';
  static const _kHydrationDate = 'hydration_date';
  static const _kHydrationGoal = 'hydration_goal_ml';

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> getProfile() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name': p.getString(_kName) ?? 'Sarah Doe',
      'email': p.getString(_kEmail) ?? 'sarah.doe@example.com',
      'age': p.getString(_kAge) ?? '32',
      'weight': p.getString(_kWeight) ?? '65',
      'height': p.getString(_kHeight) ?? '170',
    };
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String age,
    required String weight,
    required String height,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kEmail, email);
    await p.setString(_kAge, age);
    await p.setString(_kWeight, weight);
    await p.setString(_kHeight, height);
  }

  Future<void> clearProfile() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kName);
    await p.remove(_kEmail);
    await p.remove(_kAge);
    await p.remove(_kWeight);
    await p.remove(_kHeight);
    await p.remove(_kHydrationMl);
    await p.remove(_kHydrationDate);
    await p.remove(_kHydrationGoal);
  }

  // ── Hydration ─────────────────────────────────────────────────────────────

  Future<int> getTodayHydration() async {
    final p = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = p.getString(_kHydrationDate) ?? '';
    if (savedDate != today) {
      await p.setInt(_kHydrationMl, 0);
      await p.setString(_kHydrationDate, today);
      return 0;
    }
    return p.getInt(_kHydrationMl) ?? 0;
  }

  Future<int> addHydration(int ml) async {
    final p = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await p.setString(_kHydrationDate, today);
    final current = p.getInt(_kHydrationMl) ?? 0;
    final newVal = (current + ml).clamp(0, 10000);
    await p.setInt(_kHydrationMl, newVal);
    return newVal;
  }

  Future<void> resetHydration() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kHydrationMl, 0);
  }

  Future<int> getHydrationGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kHydrationGoal) ?? 2500;
  }

  Future<void> setHydrationGoal(int ml) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kHydrationGoal, ml);
  }
}
