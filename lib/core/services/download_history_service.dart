import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/download_history_item.dart';

class DownloadHistoryService {
  static const key = 'download_history';

  Future<List<DownloadHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    return jsonList.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return DownloadHistoryItem(
        title: data['title'],
        url: data['url'],
        type: data['type'],
        date: DateTime.parse(data['date']),
        filePath: data['filePath'],
      );
    }).toList();
  }

  Future<void> saveToHistory(DownloadHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'title': item.title,
      'url': item.url,
      'type': item.type,
      'date': item.date.toIso8601String(),
      'filePath': item.filePath,
    });
    final history = prefs.getStringList(key) ?? [];
    history.insert(0, json);
    if (history.length > 50) history.removeRange(50, history.length);
    await prefs.setStringList(key, history);
  }
}
