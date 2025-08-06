// lib/features/history/history_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/download_history_item.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<DownloadHistoryItem> history = [];
  List<DownloadHistoryItem> filteredHistory = [];
  String filter = 'todos'; // 'todos', 'mp3', 'mp4'
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('download_history') ?? [];

    final loadedHistory = jsonList.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      print("\n var historicoCompleto: $data");
      return DownloadHistoryItem(
        title: data['title'],
        url: data['url'],
        type: data['type'],
        date: DateTime.parse(data['date']),
        filePath: data['filePath'],
      );
    }).toList();

    setState(() {
      history = loadedHistory;
      _filterHistory();
      isLoading = false;
    });
  }

  void _filterHistory() {
    var result = history;

    if (filter == 'mp3') {
      result = result.where((item) => item.type == 'MP3').toList();
    } else if (filter == 'mp4') {
      result = result.where((item) => item.type == 'MP4').toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (item) =>
                item.title.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      filteredHistory = result;
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Limpar Histórico"),
        content: const Text(
          "Tem certeza que deseja limpar todo o histórico de downloads?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('download_history');
              setState(() {
                history.clear();
                filteredHistory.clear();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Histórico limpo!")));
            },
            child: const Text("Limpar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openFileLocation(BuildContext context, String path) async {
    final file = File(path);
    final parentDir = file.parent;

    if (await parentDir.exists()) {
      if (await file.exists()) {
        // ✅ Arquivo existe: abre selecionando
        if (Platform.isWindows) {
          await Process.start("explorer", ["/select,", path]);
        } else if (Platform.isLinux) {
          await Process.start("xdg-open", [parentDir.path]);
        } else if (Platform.isMacOS) {
          await Process.start("open", ["-R", path]);
        }
      } else {
        // ❌ Arquivo não existe, mas pasta sim
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arquivo foi movido ou excluído."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // ❌ Pasta não existe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pasta de destino não encontrada."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openFile(BuildContext context, String path) async {
    final file = File(path);
    if (await file.exists()) {
      if (Platform.isWindows) {
        await Process.start(path, []);
      } else if (Platform.isLinux || Platform.isMacOS) {
        await Process.start("xdg-open", [path]);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Arquivo não encontrado")));
    }
  }

  Future<void> _copyPathToClipboard(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Caminho copiado!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Downloads"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: history.isEmpty ? null : _clearHistory,
            tooltip: "Limpar histórico",
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Campo de busca
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Buscar por título...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                    _filterHistory();
                  },
                ),
                const SizedBox(height: 8),
                // Filtros
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterChip(
                      label: const Text("Todos"),
                      selected: filter == 'todos',
                      onSelected: (_) {
                        setState(() {
                          filter = 'todos';
                        });
                        _filterHistory();
                      },
                    ),
                    FilterChip(
                      label: const Row(
                        children: [
                          Icon(Icons.music_note, size: 14),
                          SizedBox(width: 4),
                          Text("MP3"),
                        ],
                      ),
                      selected: filter == 'mp3',
                      onSelected: (_) {
                        setState(() {
                          filter = 'mp3';
                        });
                        _filterHistory();
                      },
                    ),
                    FilterChip(
                      label: const Row(
                        children: [
                          Icon(Icons.movie, size: 14),
                          SizedBox(width: 4),
                          Text("MP4"),
                        ],
                      ),
                      selected: filter == 'mp4',
                      onSelected: (_) {
                        setState(() {
                          filter = 'mp4';
                        });
                        _filterHistory();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de downloads
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final fileExists = File(item.filePath).existsSync();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onLongPress: () {
                            _showItemActions(context, item);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Ícone
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: item.type == 'MP3'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item.type == 'MP3'
                                        ? Icons.music_note
                                        : Icons.movie,
                                    color: item.type == 'MP3'
                                        ? Colors.green
                                        : Colors.blue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Informações
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            item.type,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: item.type == 'MP3'
                                                  ? Colors.green
                                                  : Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${item.date.day}/${item.date.month}/${item.date.year}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!fileExists)
                                        const Text(
                                          "⚠️ Arquivo não encontrado",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Ações
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.folder_open, size: 16),
                                          SizedBox(width: 8),
                                          Text("Localizar pasta"),
                                        ],
                                      ),
                                      onTap: () => _openFileLocation(
                                        context,
                                        item.filePath,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.play_arrow, size: 16),
                                          SizedBox(width: 8),
                                          Text("Abrir arquivo"),
                                        ],
                                      ),
                                      onTap: () =>
                                          _openFile(context, item.filePath),
                                    ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.copy, size: 16),
                                          SizedBox(width: 8),
                                          Text("Copiar caminho"),
                                        ],
                                      ),
                                      onTap: () =>
                                          _copyPathToClipboard(item.filePath),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Nenhum download ainda",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Seus arquivos baixados aparecerão aqui.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          if (history.isNotEmpty && filteredHistory.isEmpty)
            const SizedBox(height: 16),
          if (history.isNotEmpty && filteredHistory.isEmpty)
            const Text(
              "Nenhum item com esse filtro.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  void _showItemActions(BuildContext context, DownloadHistoryItem item) {
    final fileExists = File(item.filePath).existsSync();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text("Localizar na pasta"),
              onTap: () {
                Navigator.pop(ctx);
                _openFileLocation(context, item.filePath);
              },
            ),
            if (fileExists)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text("Abrir arquivo"),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFile(context, item.filePath);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Copiar caminho do arquivo"),
              onTap: () {
                Navigator.pop(ctx);
                _copyPathToClipboard(item.filePath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                "Remover do histórico",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final prefs = await SharedPreferences.getInstance();
                final jsonList = prefs.getStringList('download_history') ?? [];
                final updatedList = jsonList.where((json) {
                  final data = jsonDecode(json) as Map<String, dynamic>;
                  return data['filePath'] != item.filePath;
                }).toList();
                await prefs.setStringList('download_history', updatedList);
                setState(() {
                  history.remove(item);
                  filteredHistory.remove(item);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Item removido do histórico")),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Cancelar"),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
