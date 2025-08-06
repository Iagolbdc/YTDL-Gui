part of '../home_page.dart';

class DownloadControls extends StatelessWidget {
  final VoidCallback onAudioDownload;
  final VoidCallback onVideoDownload;
  final bool isDownloading;
  final bool hasVideos;

  const DownloadControls({
    super.key,
    required this.onAudioDownload,
    required this.onVideoDownload,
    required this.isDownloading,
    required this.hasVideos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDownloading || !hasVideos ? null : onAudioDownload,
            icon: const Icon(Icons.music_note),
            label: const Text("MP3 (Áudio)"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDownloading || !hasVideos ? null : onVideoDownload,
            icon: const Icon(Icons.movie),
            label: const Text("MP4 (Vídeo)"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ),
      ],
    );
  }
}
