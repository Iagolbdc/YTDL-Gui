class DownloadHistoryItem {
  final String title;
  final String url;
  final String type;
  final DateTime date;
  final String filePath;

  DownloadHistoryItem({
    required this.title,
    required this.url,
    required this.type,
    required this.date,
    required this.filePath,
  });
}
