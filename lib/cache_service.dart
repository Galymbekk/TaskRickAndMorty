import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheService {
  Future<Box> _getBox() async {
    return await Hive.openBox('characters_cache');
  }
  
  Future<void> savePage(int page, Map<String, dynamic> data) async {
    final box = await _getBox();
    final jsonString = jsonEncode(data);
    await box.put('page_$page', jsonString);
  }
  
  Future<Map<String, dynamic>?> getPage(int page) async {
    final box = await _getBox();
    final jsonString = box.get('page_$page');
    if (jsonString == null) {
      return null;
    }
    return jsonDecode(jsonString);
  }
}