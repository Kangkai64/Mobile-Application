import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) async {
    await initialize();
    return _prefs!.setString(key, value);
    
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    await initialize();
    return _prefs!.setStringList(key, value);
  }

  static List<String> getStringList(String key) {
    return _prefs?.getStringList(key) ?? <String>[];
  }

  static Future<bool> remove(String key) async {
    await initialize();
    return _prefs!.remove(key);
  }
}


