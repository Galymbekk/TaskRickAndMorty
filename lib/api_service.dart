import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

class ApiService {
  final String baseUrl = 'https://rickandmortyapi.com/api';
   final CacheService _cacheService = CacheService();
  
  Future<Map<String, dynamic>> getCharacters(int page) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/character?page=$page'),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await _cacheService.savePage(page, data);
          return data;
        } else {
          throw Exception('ошибка API: ${response.statusCode}');
        }
      } catch (e) {
        final cachedData = await _cacheService.getPage(page);
        if (cachedData != null) {
          return cachedData;
        }
        throw Exception('Не мог найти кэширование и нет интернета');
      }
    }
}