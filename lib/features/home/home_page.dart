import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ytdl_gui/main.dart';

import '../../core/services/binary_service.dart';
import '../../core/services/download_history_service.dart';
import '../../shared/models/video_item.dart';
import '../../shared/models/download_history_item.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/status_bar.dart';
import '../history/history_page.dart';
import '../settings/settings_page.dart';
import '../help/help_page.dart';
import '../about/about_page.dart';

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

  Process? currentProcess;
  bool isCancelling = false;

  Process? currentDownloadProcess;

  int maxConcurrentDownloads = 5;

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

  void cancelDownload() {
    setState(() {
      status = "Cancelando download...";
      isDownloading = false;
    });

    if (currentDownloadProcess != null) {
      currentDownloadProcess!.kill();
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
        final availableHeight = constraints.maxHeight;
        final headerEstimate = 400.0;
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
                  mainAxisSize: MainAxisSize.min,
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
                      progress: isDownloading || isLoadingList
                          ? progress
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isDownloading
                                ? () => cancelDownload()
                                : !videos.isNotEmpty
                                ? null
                                : () => startDownload(audioOnly: true),
                            icon: isDownloading
                                ? const Icon(Icons.close)
                                : const Icon(Icons.music_note),
                            label: isDownloading
                                ? const Text("Cancelar")
                                : const Text("MP3"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDownloading
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isDownloading
                                ? () => cancelDownload()
                                : !videos.isNotEmpty
                                ? null
                                : () => startDownload(audioOnly: false),
                            icon: isDownloading
                                ? const Icon(Icons.close)
                                : const Icon(Icons.movie),
                            label: isDownloading
                                ? const Text("Cancelar")
                                : const Text("MP4"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDownloading
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
            onPressed: isLoadingList
                ? () => cancelLoad()
                : isDownloading
                ? null
                : () => loadVideosFromUrl(urlController.text),
            icon: isLoadingList
                ? const Icon(Icons.close)
                : const Icon(Icons.playlist_add),
            label: isLoadingList
                ? const Text("Cancelar")
                : isLoadingList
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

  void cancelLoad() {
    setState(() {
      isCancelling = true;
      status = "Cancelando...";
    });

    if (currentProcess != null) {
      currentProcess!.kill();
    }
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

  void clearList() {
    setState(() {
      videos.clear();
      status = "Lista limpa.";
    });
  }

  Future<void> loadVideosFromUrl(String url) async {
    if (url.isEmpty) return;

    try {
      setState(() {
        status = "🔍 Carregando detalhes...";
        isLoadingList = true;
        isCancelling = false;
        progress = 0.0;
        videos.clear();
      });

      currentProcess = await Process.start(binaryService.binaryFile!.path, [
        "--flat-playlist",
        "-J",
        url,
      ]);

      List<VideoItem> newVideos = [];

      final lines = <String>[];
      currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            lines.add(line);
          });

      String errorOutput = '';
      currentProcess!.stderr
          .transform(utf8.decoder)
          .listen((line) => errorOutput += line);

      final exitCode = await currentProcess!.exitCode;

      if (isCancelling) {
        if (mounted) {
          setState(() {
            status = "❌ Carregamento cancelado.";
            isLoadingList = false;
            progress = 0.0;
          });
        }
        return;
      }

      if (exitCode != 0 || lines.isEmpty) {
        final errorMsg = errorOutput.isNotEmpty
            ? errorOutput
            : 'Processo falhou';
        setState(() {
          status =
              "❌ Erro: ${errorMsg.length > 60 ? '${errorMsg.substring(0, 60)}...' : errorMsg}";
          isLoadingList = false;
          progress = 0.0;
        });
        return;
      }

      final data = jsonDecode(lines.join('\n'));
      if (data is Map<String, dynamic>) {
        if (data.containsKey("entries")) {
          final entries =
              (data["entries"] as List?)
                  ?.whereType<Map<String, dynamic>>()
                  .where((entry) {
                    final title =
                        entry["title"]?.toString().toLowerCase() ?? "";
                    return !title.contains("deleted video") &&
                        !title.contains("private video") &&
                        title != "private" &&
                        title != "deleted";
                  })
                  .toList() ??
              [];

          final total = entries.length;
          for (int i = 0; i < entries.length; i++) {
            if (!isLoadingList) break;

            final item = entries[i];
            newVideos.add(_mapEntryToVideoItem(item));

            if (mounted) {
              setState(() {
                status = "🔍 Carregando: ${i + 1}/$total";
                progress = (i + 1) / total;
              });
            }
          }
        } else {
          final title = (data["title"]?.toString().toLowerCase() ?? "");
          if (!title.contains("deleted") && !title.contains("private")) {
            newVideos = [_mapEntryToVideoItem(data)];
            if (mounted) {
              setState(() {
                status = "✅ 1 vídeo carregado";
                progress = 1.0;
              });
            }
          }
        }
      }

      for (final v in newVideos) {
        if (v.thumbnail.isNotEmpty) {
          _thumbnailCache[v.id] = v.thumbnail;
        }
      }

      if (mounted) {
        setState(() {
          videos = newVideos;
          selectAll = true;
          status = "✅ ${newVideos.length} vídeo(s) carregado(s)";
          isLoadingList = false;
          progress = 1.0;
        });
      }
    } catch (e) {
      if (isCancelling) {
        setState(() {
          status = "❌ Carregamento cancelado.";
          isLoadingList = false;
          progress = 0.0;
        });
      } else {
        setState(() {
          status = "Erro: $e";
          isLoadingList = false;
          progress = 0.0;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    } finally {
      currentProcess = null;
    }
  }

  VideoItem _mapEntryToVideoItem(Map<String, dynamic> data) {
    final id = data["id"]?.toString() ?? "";
    final title = data["title"]?.toString() ?? "Sem título";
    final webpageUrl =
        data["webpage_url"]?.toString() ?? "https://youtube.com/watch?v=$id";

    String thumbnail = "";
    if (id.isNotEmpty) {
      thumbnail = "https://img.youtube.com/vi/$id/maxresdefault.jpg";
      if (!_thumbnailCache.containsKey(id)) {
        _thumbnailCache[id] = thumbnail;
      }
    }

    final duration = _formatDuration(data["duration"] ?? 0);

    return VideoItem(
      id: id,
      title: title,
      url: webpageUrl,
      thumbnail: thumbnail,
      duration: duration,
      selected: true,
      downloaded: false,
      error: null,
      isLoadingDetails: false,
    );
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null || seconds <= 0) return "--:--";
    final dur = Duration(seconds: (seconds as num).toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final mins = dur.inMinutes;
    final secs = dur.inSeconds.remainder(60);
    return "${twoDigits(mins)}:${twoDigits(secs)}";
  }

  Future<void> _showNotification(String title, String body) async {
    if (!showNotifications) return;

    const notificationDetails = NotificationDetails(
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

    final pending = Queue<VideoItem>.from(selectedVideos);
    final activeProcesses = <Process>[];

    Future<void> downloadVideo(VideoItem video) async {
      if (!isDownloading) return;

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

      final process = await Process.start(binaryService.binaryFile!.path, args);
      activeProcesses.add(process);

      var lastPercent = 0.0;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final match = RegExp(r"(\d+\.\d+)%").firstMatch(line);
            if (match != null) {
              final percent = double.tryParse(match.group(1)!) ?? 0.0;
              final progressValue = percent / 100.0;

              if (mounted) {
                setState(() {
                  video.downloadProgress = progressValue;
                  video.status = DownloadStatus.downloading;
                });
              }

              if ((percent - lastPercent).abs() > 0.5) {
                lastPercent = percent;
                setState(() {
                  progress = (completed + percent / 100) / totalVideos;
                });
              }
            }
          });

      final exitCode = await process.exitCode;
      activeProcesses.remove(process);

      if (!isDownloading) return;

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

        if (mounted) {
          setState(() {
            status = "✅ ${video.title} concluído";
            video.downloaded = true;
            video.status = DownloadStatus.completed;
            video.downloadProgress = 1.0;
          });
        }

        if (showNotifications) {
          _showNotification("Download Concluído", "${video.title}.");
        }
      } else {
        if (mounted) {
          setState(() {
            video.error = "Erro $exitCode";
            status = "⚠️ Falha: ${video.title}";
            video.status = isDownloading
                ? DownloadStatus.failed
                : DownloadStatus.cancelled;
          });
        }

        if (showNotifications) {
          _showNotification(
            "Falha no Download",
            "Não foi possível baixar: ${video.title}",
          );
        }
      }

      completed++;
    }

    final workers = <Future>[];
    for (int i = 0; i < maxConcurrentDownloads; i++) {
      workers.add(
        Future.doWhile(() async {
          if (!isDownloading || pending.isEmpty) return false;

          final video = pending.removeFirst();
          await downloadVideo(video);
          return true;
        }),
      );
    }

    await Future.wait(workers);

    if (mounted && isDownloading) {
      setState(() {
        status = "✅ Todos os downloads concluídos!";
        isDownloading = false;
        progress = 1.0;
      });

      if (showNotifications) {
        _showNotification(
          "Todos os Downloads Concluídos!",
          "$totalVideos arquivos foram baixados com sucesso.",
        );
      }
    }

    loadRecentDownloads();
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
