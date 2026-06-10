import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/dashboard_data.dart';

class UserService {
  static const _key = 'dashboard_user_info';

  static Future<void> saveUser(UserInfo user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      '_id': user.id,
      'nom': user.nom,
      'prenom': user.prenom,
      'email': user.email,
      'telephone': user.telephone,
      'position': {'lat': user.lat, 'lng': user.lng},
    }));
  }

  static Future<UserInfo?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    return UserInfo.fromJson(jsonDecode(data));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
