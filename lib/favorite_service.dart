import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  static const String _key = 'favorites';
  
  Future<void> saveFavorites(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(ids);
    await prefs.setString(_key, jsonString);
  }

  Future<List<int>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    return List<int>.from(jsonDecode(jsonString));
  }
}