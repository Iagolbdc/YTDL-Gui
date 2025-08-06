part of '../home_page.dart';

class VideoList extends StatelessWidget {
  final List<VideoItem> videos;
  final bool selectAll;
  final ValueChanged<bool?> onSelectAll;
  final ValueChanged<VideoItem> onToggleSelected;
  final VoidCallback onClear;

  const VideoList({
    super.key,
    required this.videos,
    required this.selectAll,
    required this.onSelectAll,
    required this.onToggleSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(value: selectAll, onChanged: onSelectAll),
            const Text("Selecionar todos", style: TextStyle(fontSize: 16)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text("Limpar", style: TextStyle(fontSize: 14)),
              onPressed: onClear,
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CheckboxListTile(
                  dense: true,
                  activeColor: Colors.blueAccent,
                  value: v.selected,
                  onChanged: (_) => onToggleSelected(v),
                  title: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: v.thumbnail.isNotEmpty
                                ? Image.network(
                                    v.thumbnail,
                                    width: 90,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 90,
                                      height: 50,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 90,
                                    height: 50,
                                    color: Colors.grey[700],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                          ),
                          if (v.isLoadingDetails)
                            Container(
                              width: 90,
                              height: 50,
                              color: Colors.black54,
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (v.downloaded)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                color: Colors.green.withOpacity(0.8),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  v.duration,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
