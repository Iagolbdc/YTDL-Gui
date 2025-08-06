class VideoItem {
  final String id;
  final String title;
  final String url;
  String thumbnail;
  String duration;
  bool selected;
  bool isLoadingDetails;
  bool downloaded;
  String? error;

  VideoItem({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnail = "",
    this.duration = "--:--",
    this.selected = true,
    this.isLoadingDetails = false,
    this.downloaded = false,
    this.error,
  });
}
