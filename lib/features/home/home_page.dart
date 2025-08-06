// lib/features/home/home_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader/main.dart';

// Services
import '../../core/services/binary_service.dart';
import '../../core/services/download_history_service.dart';

// Models
import '../../shared/models/video_item.dart';
import '../../shared/models/download_history_item.dart';

// Widgets
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/status_bar.dart';
import '../history/history_page.dart';
import '../settings/settings_page.dart';
import '../help/help_page.dart';
import '../about/about_page.dart';

// Widgets locais
part 'widgets/video_list.dart';
part 'widgets/download_controls.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final urlController = TextEditingController();
  String? savePath;
  String status = "Inicializando...";
  double progress = 0.0;
  bool isDownloading = false;
  bool showNotifications = true;
  bool useFastDownload = false;

  late BinaryService binaryService;
  late DownloadHistoryService historyService;

  List<VideoItem> videos = [];
  List<DownloadHistoryItem> recentDownloads = [];
  bool isLoadingList = false;
  bool selectAll = true;
  final _thumbnailCache = <String, String>{};

  String audioQuality = "Alta (320kbps)";
  String videoQuality = "720p";

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    binaryService = BinaryService();
    historyService = DownloadHistoryService();
    _loadSavedSettings();
    loadRecentDownloads();
    _loadAppSettings();
    _initApp();
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      showNotifications = prefs.getBool('show_notifications') ?? true;
      useFastDownload = prefs.getBool('use_fast_download') ?? false;
    });
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedPath = prefs.getString('save_path');
    if (savedPath != null) {
      final dir = Directory(savedPath);
      if (await dir.exists()) {
        setState(() {
          savePath = savedPath;
        });
      } else {
        // Pasta foi movida ou excluída
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Pasta de downloads não encontrada. Escolha uma nova.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // ✅ Carrega outras configurações
    final savedAudioQuality = prefs.getString('audio_quality');
    final savedVideoQuality = prefs.getString('video_quality');

    if (savedAudioQuality != null) {
      setState(() {
        audioQuality = savedAudioQuality;
      });
    }
    if (savedVideoQuality != null) {
      setState(() {
        videoQuality = savedVideoQuality;
      });
    }
  }

  Future<void> _initApp() async {
    if (!mounted) return;

    setState(() => status = "🔧 Preparando yt-dlp...");

    await binaryService.init();
    final localVer = await binaryService.getLocalVersion();

    if (localVer != null) {
      if (mounted) {
        setState(() => status = "✅ yt-dlp pronto ($localVer)");
      }
      return;
    }

    setState(() => status = "⬇️ Baixando yt-dlp...");
    final latest = await binaryService.getLatestRelease();
    if (latest != null && await binaryService.downloadBinary(latest["url"]!)) {
      final newVer = await binaryService.getLocalVersion();
      if (mounted) {
        setState(
          () => status = newVer != null
              ? "✅ yt-dlp v$newVer instalado!"
              : "✅ Binário baixado!",
        );
      }
    } else {
      if (mounted) {
        setState(() => status = "❌ Falha ao baixar yt-dlp");
      }
    }
  }

  Future<void> loadRecentDownloads() async {
    final history = await historyService.loadHistory();
    setState(() {
      recentDownloads = history.take(5).toList();
    });
  }

  Widget _getPage() {
    switch (_currentIndex) {
      case 0:
        return _buildMainPage();
      case 1:
        return HistoryPage();
      case 2:
        return SettingsPage(
          onSettingsChanged:
              (String audioQuality, String videoQuality, String? savePath) {
                setState(() {
                  this.audioQuality = audioQuality;
                  this.videoQuality = videoQuality;
                  this.savePath = savePath;
                });
              },
        );
      case 3:
        return HelpPage();
      case 4:
        return AboutPage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMainPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Altura mínima para a lista de vídeos
        final availableHeight = constraints.maxHeight;
        final headerEstimate = 400.0; // Estimativa do que está acima da lista
        final listHeight = (availableHeight - headerEstimate).clamp(
          150.0,
          400.0,
        );

        return Scaffold(
          floatingActionButton: constraints.maxWidth > 800
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.history),
                  label: const Text("Histórico"),
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                )
              : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // ✅ Evita que o Column tente preencher tudo
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: urlController,
                      label: "Cole a URL do YouTube",
                      hint: "https://youtube.com/watch?v=... ou playlist",
                      prefixIcon: Icons.link,
                      onClear: () => urlController.clear(),
                    ),
                    const SizedBox(height: 16),
                    if (constraints.maxWidth > 600) _buildQuickStats(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    if (constraints.maxWidth > 600 &&
                        recentDownloads.isNotEmpty)
                      _buildRecentDownloads(),
                    const SizedBox(height: 16),
                    if (videos.isNotEmpty)
                      SizedBox(
                        height: listHeight,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: VideoList(
                              videos: videos,
                              selectAll: selectAll,
                              onSelectAll: (val) {
                                setState(() {
                                  selectAll = val ?? false;
                                  videos.forEach((v) => v.selected = selectAll);
                                });
                              },
                              onToggleSelected: (v) {
                                setState(() {
                                  v.selected = !v.selected;
                                  selectAll = videos.every((v) => v.selected);
                                });
                              },
                              onClear: clearList,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    StatusBar(
                      status: status,
                      progress: isDownloading ? progress : null,
                    ),
                    const SizedBox(height: 16),
                    // Botões de download
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isDownloading || !videos.isNotEmpty
                                ? null
                                : () => startDownload(audioOnly: true),
                            icon: const Icon(Icons.music_note),
                            label: const Text("MP3"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isDownloading || !videos.isNotEmpty
                                ? null
                                : () => startDownload(audioOnly: false),
                            icon: const Icon(Icons.movie),
                            label: const Text("MP4"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Espaço final
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.purpleAccent],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.download_done, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "YouTube Downloader",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                status.contains("pronto") ? "Pronto para baixar" : status,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _initApp(),
          tooltip: "Verificar yt-dlp",
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(Icons.video_library, "Vídeos", videos.length.toString()),
          _buildStat(
            Icons.audiotrack,
            "Áudios",
            recentDownloads.where((d) => d.type == "MP3").length.toString(),
          ),
          _buildStat(
            Icons.folder,
            "Pasta",
            savePath?.split('/').last ?? "Nenhuma",
          ),
          _buildStat(Icons.cloud_done, "Online", "Sim"),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoadingList || isDownloading
                ? null
                : () => loadVideosFromUrl(urlController.text),
            icon: const Icon(Icons.playlist_add),
            label: isLoadingList
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Carregar Vídeos"),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () async {
            final dir = await FilePicker.platform.getDirectoryPath();
            if (dir != null && mounted) {
              setState(() => savePath = dir);
            }
          },
          icon: const Icon(Icons.folder_open),
          label: const Text("Pasta"),
        ),
      ],
    );
  }

  Widget _buildRecentDownloads() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recentes",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentDownloads.length,
              itemBuilder: (context, index) {
                final item = recentDownloads[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  width: 180,
                  decoration: BoxDecoration(
                    color: item.type == "MP3"
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type,
                        style: TextStyle(
                          fontSize: 10,
                          color: item.type == "MP3"
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title.length > 20
                            ? "${item.title.substring(0, 20)}..."
                            : item.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.date.hour}:${item.date.minute}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // === FUNÇÕES DE NEGÓCIO ===

  void clearList() {
    setState(() {
      videos.clear();
      status = "Lista limpa.";
    });
  }

  Future<void> loadVideosFromUrl(String url) async {
    if (url.isEmpty || !url.contains("youtube.com")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("URL inválida. Insira uma URL do YouTube."),
        ),
      );
      return;
    }

    if (binaryService.binaryFile == null ||
        !await binaryService.binaryFile!.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Binário yt-dlp não encontrado. Tente novamente."),
        ),
      );
      return;
    }

    setState(() {
      isLoadingList = true;
      videos.clear();
      status = "Carregando vídeos...";
    });

    try {
      final process = await Process.run(binaryService.binaryFile!.path, [
        "--flat-playlist",
        "-J",
        url,
      ]);

      if (process.exitCode != 0) {
        setState(() {
          status = "❌ Erro: ${process.stderr.toString().substring(0, 60)}...";
          isLoadingList = false;
        });
        return;
      }

      final data = jsonDecode(process.stdout);
      List<VideoItem> newVideos = [];

      if (data is Map && data.containsKey("entries")) {
        final entries = (data["entries"] as List).cast<Map<String, dynamic>>();
        newVideos = entries
            .map(
              (e) => VideoItem(
                id: e["id"] ?? "",
                title: e["title"] ?? "Sem título",
                url: e["url"] ?? "https://youtube.com/watch?v=${e["id"]}",
              ),
            )
            .toList();
      } else {
        newVideos = [
          VideoItem(
            id: data["id"] ?? "",
            title: data["title"] ?? "Sem título",
            url:
                data["webpage_url"] ??
                "https://youtube.com/watch?v=${data["id"]}",
          ),
        ];
      }

      setState(() {
        videos = newVideos;
        status = "✅ ${videos.length} vídeo(s). Buscando detalhes...";
      });

      final chunks = _chunkList(videos, 5);
      for (final chunk in chunks) {
        await Future.wait(chunk.map((v) => fetchDetails(v)));
      }

      setState(() {
        status = "✅ Pronto para baixar (${videos.length} vídeos)";
        isLoadingList = false;
        selectAll = true;
      });
    } catch (e) {
      setState(() {
        status = "Erro ao carregar: $e";
        isLoadingList = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, (i + chunkSize).clamp(0, list.length)));
    }
    return chunks;
  }

  Future<void> _showNotification(String title, String body) async {
    if (!showNotifications) return; // Respeita a configuração do usuário

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_downloads',
        'Downloads',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().microsecond,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> fetchDetails(VideoItem video) async {
    if (_thumbnailCache.containsKey(video.id)) {
      setState(() {
        video.thumbnail = _thumbnailCache[video.id]!;
        video.isLoadingDetails = false;
      });
      return;
    }

    setState(() => video.isLoadingDetails = true);
    try {
      final process = await Process.run(binaryService.binaryFile!.path, [
        "--no-playlist",
        "-J",
        video.url,
      ]);

      if (process.exitCode == 0) {
        final data = jsonDecode(process.stdout);
        final thumb = data["thumbnail"] ?? "";
        final duration = _formatDuration(data["duration"]);
        _thumbnailCache[video.id] = thumb;

        if (mounted) {
          setState(() {
            video.thumbnail = thumb;
            video.duration = duration;
            video.isLoadingDetails = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          video.isLoadingDetails = false;
        });
      }
    }
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null || seconds <= 0) return "--:--";
    final dur = Duration(seconds: seconds as int);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final mins = dur.inMinutes;
    final secs = dur.inSeconds.remainder(60);
    return "${twoDigits(mins)}:${twoDigits(secs)}";
  }

  Future<void> startDownload({required bool audioOnly}) async {
    _loadAppSettings();
    final selectedVideos = videos.where((v) => v.selected).toList();
    if (selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione ao menos um vídeo.")),
      );
      return;
    }
    if (savePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escolha uma pasta de destino.")),
      );
      return;
    }

    setState(() {
      isDownloading = true;
      progress = 0.0;
      status = "Iniciando downloads...";
    });

    final totalVideos = selectedVideos.length;
    var completed = 0;

    for (final video in selectedVideos) {
      final args = <String>[
        video.url,
        "-o",
        "$savePath/%(title)s.%(ext)s",
        "--no-playlist",
        "--quiet",
        "--no-warnings",
      ];

      if (audioOnly) {
        final quality = audioQuality == "Alta (320kbps)" ? "320k" : "192k";
        args.insertAll(1, [
          "-x",
          "--audio-format",
          "mp3",
          "--audio-quality",
          quality,
        ]);
      } else {
        final format = videoQuality == "720p"
            ? "bestvideo[height<=720]+bestaudio"
            : videoQuality == "1080p"
            ? "bestvideo[height<=1080]+bestaudio"
            : "best";
        args.insertAll(1, ["-f", format]);
      }

      setState(() => status = "Baixando: ${video.title}");
      final process = await Process.start(binaryService.binaryFile!.path, args);
      var lastPercent = 0.0;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final match = RegExp(r"(\d+\.\d+)%").firstMatch(line);
            if (match != null) {
              final percent = double.tryParse(match.group(1)!) ?? 0.0;
              if ((percent - lastPercent).abs() > 0.5) {
                lastPercent = percent;
                setState(() {
                  progress = (completed + percent / 100) / totalVideos;
                });
              }
            }
          });

      final exitCode = await process.exitCode;
      completed++;

      if (exitCode == 0) {
        final filePath =
            "$savePath/${video.title}.${audioOnly ? 'mp3' : 'mp4'}";
        await historyService.saveToHistory(
          DownloadHistoryItem(
            title: video.title.length > 60
                ? "${video.title.substring(0, 60)}..."
                : video.title,
            url: video.url,
            type: audioOnly ? "MP3" : "MP4",
            date: DateTime.now(),
            filePath: filePath,
          ),
        );

        setState(() {
          video.downloaded = true;
          status = "✅ ${video.title} concluído";
        });

        // ✅ Notificação condicional
        if (showNotifications) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("✅ ${video.title} baixado!")));

          // ✅ Adicione a notificação do sistema
          _showNotification("Download Concluído", "${video.title}.");
        }
      } else {
        setState(() {
          video.error = "Erro $exitCode";
          status = "⚠️ Falha: ${video.title}";
        });

        // ✅ Notificação de erro (opcional)
        if (showNotifications) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Falha ao baixar: ${video.title}")),
          );

          _showNotification(
            "Falha no Download",
            "Não foi possível baixar: ${video.title}",
          );
        }
      }
    }

    setState(() {
      status = "✅ Todos os downloads concluídos!";
      isDownloading = false;
      progress = 1.0;
    });

    // ✅ Notificação final condicional
    if (showNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $totalVideos arquivos baixados!")),
      );

      _showNotification(
        "Todos os Downloads Concluídos!",
        "$totalVideos arquivos foram baixados com sucesso.",
      );
    }

    loadRecentDownloads(); // Atualiza os recentes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            'Início',
            'Histórico',
            'Configurações',
            'Ajuda',
            'Sobre',
          ][_currentIndex],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.download_done,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "YouTube Downloader",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Baixe seus vídeos",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            ...List.generate(
              5,
              (i) => ListTile(
                leading: [
                  const Icon(Icons.home),
                  const Icon(Icons.history),
                  const Icon(Icons.settings),
                  const Icon(Icons.help),
                  const Icon(Icons.info),
                ][i],
                title: Text(
                  ['Início', 'Histórico', 'Configurações', 'Ajuda', 'Sobre'][i],
                ),
                selected: _currentIndex == i,
                onTap: () {
                  loadRecentDownloads();
                  setState(() => _currentIndex = i);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
      body: _getPage(),
    );
  }
}
