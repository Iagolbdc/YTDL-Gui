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

  double downloadProgress = 0.0;
  DownloadStatus status = DownloadStatus.pending;

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

enum DownloadStatus {
  pending, // Aguardando
  downloading, // Em andamento
  completed, // Concluído
  failed, // Erro
  cancelled, // Cancelado
}
