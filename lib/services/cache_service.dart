import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheService {
  Future<Directory> _getCacheDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> _getCacheFile() async {
    final dir = await _getCacheDirectory();
    return File('${dir.path}/selected_parents_cache.json');
  }

  Future<void> saveSelectedParents(List<Map<String, dynamic>> selectedParents) async {
    final file = await _getCacheFile();
    String jsonData = jsonEncode(selectedParents);
    await file.writeAsString(jsonData);
  }

  Future<List<Map<String, dynamic>>> loadSelectedParents() async {
    try {
      final file = await _getCacheFile();
      String jsonData = await file.readAsString();
      List<dynamic> jsonList = jsonDecode(jsonData);
      return jsonList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }
}
