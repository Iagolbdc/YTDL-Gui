import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final Function(String audioQuality, String videoQuality, String? savePath)
  onSettingsChanged;

  const SettingsPage({super.key, required this.onSettingsChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String audioQuality = "Média (192kbps)";
  String videoQuality = "720p";
  String? savePath;

  bool autoUpdate = true;
  bool showNotifications = true;
  bool useFastDownload = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      audioQuality = prefs.getString('audio_quality') ?? "Alta (320kbps)";
      videoQuality = prefs.getString('video_quality') ?? "720p";
      savePath = prefs.getString('save_path');
      autoUpdate = prefs.getBool('auto_update') ?? true;
      showNotifications = prefs.getBool('show_notifications') ?? true;
      useFastDownload = prefs.getBool('use_fast_download') ?? false;
    });

    widget.onSettingsChanged(audioQuality, videoQuality, savePath);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_quality', audioQuality);
    await prefs.setString('video_quality', videoQuality);
    if (savePath != null) {
      await prefs.setString('save_path', savePath!);
    }
    await prefs.setBool('auto_update', autoUpdate);
    await prefs.setBool('show_notifications', showNotifications);
    await prefs.setBool('use_fast_download', useFastDownload);

    widget.onSettingsChanged(audioQuality, videoQuality, savePath);
  }

  Future<void> _pickFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      setState(() {
        savePath = dir;
      });
      await _saveSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pasta alterada: ${dir.split('/').last}")),
      );
    }
  }

  Future<void> _openSavePath() async {
    if (savePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma pasta selecionada")),
      );
      return;
    }

    final directory = Directory(savePath!);
    if (await directory.exists()) {
      if (Platform.isWindows) {
        await Process.start('explorer', [savePath!]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [savePath!]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [savePath!]);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pasta não encontrada no disco")),
      );
    }
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      audioQuality = "Alta (320kbps)";
      videoQuality = "720p";
      savePath = null;
      autoUpdate = true;
      showNotifications = true;
      useFastDownload = false;
    });

    widget.onSettingsChanged(audioQuality, videoQuality, savePath);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configurações resetadas para o padrão")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🎧 Qualidade de Áudio",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Formato"),
                    subtitle: const Text("MP3"),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: audioQuality,
                    decoration: const InputDecoration(
                      labelText: "Qualidade",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Alta (320kbps)",
                        child: Text("Alta - 320kbps"),
                      ),
                      DropdownMenuItem(
                        value: "Média (192kbps)",
                        child: Text("Média - 192kbps"),
                      ),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        audioQuality = value!;
                      });
                      await _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🎬 Qualidade de Vídeo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Formato"),
                    subtitle: const Text("MP4"),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: videoQuality,
                    decoration: const InputDecoration(
                      labelText: "Resolução",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "720p", child: Text("720p HD")),
                      DropdownMenuItem(
                        value: "1080p",
                        child: Text("1080p Full HD"),
                      ),
                      DropdownMenuItem(
                        value: "Melhor",
                        child: Text("Melhor disponível"),
                      ),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        videoQuality = value!;
                      });
                      await _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📁 Pasta de Downloads",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (savePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Atual: ${savePath!.split('/').last}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFolder,
                          icon: const Icon(Icons.folder_open),
                          label: Text(
                            savePath == null
                                ? "Escolher Pasta"
                                : "Alterar Pasta",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: savePath == null ? null : _openSavePath,
                        tooltip: "Abrir pasta",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🔁 Atualizações",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: autoUpdate,
                    onChanged: (value) async {
                      setState(() {
                        autoUpdate = value;
                      });
                      await _saveSettings();
                    },
                    title: const Text("Atualização Automática"),
                    subtitle: const Text(
                      "Verifica e atualiza o yt-dlp ao iniciar",
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "✨ Experiência do Usuário",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: showNotifications,
                    onChanged: (value) async {
                      setState(() {
                        showNotifications = value;
                      });
                      await _saveSettings();
                    },
                    title: const Text("Mostrar Notificações"),
                    subtitle: const Text(
                      "Exibe mensagens ao concluir downloads",
                    ),
                  ),
                  SwitchListTile(
                    value: useFastDownload,
                    onChanged: (value) async {
                      setState(() {
                        useFastDownload = value;
                      });
                      await _saveSettings();
                    },
                    title: const Text("Modo Rápido"),
                    subtitle: const Text(
                      "Pula alguns detalhes para carregar mais rápido",
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Resetar Configurações?"),
                    content: const Text(
                      "Isso vai restaurar todos os valores para o padrão.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _resetSettings();
                        },
                        child: const Text(
                          "Resetar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.settings_backup_restore),
              label: const Text("Resetar para Padrão"),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
