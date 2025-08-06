import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BinaryService {
  File? binaryFile;

  Future<void> init() async {
    final path = await _getBinaryPath();
    binaryFile = File(path);
  }

  // ✅ Agora é Future<String> — resolve o diretório de forma assíncrona
  Future<String> _getBinaryPath() async {
    final dir = await getApplicationSupportDirectory(); // ✅ Assíncrono
    final binName = Platform.isWindows ? "yt-dlp.exe" : "yt-dlp";
    return "${dir.path}/$binName";
  }

  Future<String?> getLocalVersion() async {
    if (binaryFile == null || !await binaryFile!.exists()) return null;
    try {
      final result = await Process.run(binaryFile!.path, ["--version"]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<Map<String, String>?> getLatestRelease() async {
    const api = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest";
    try {
      final res = await http
          .get(Uri.parse(api))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final version = (data["tag_name"] as String).replaceFirst("v", "");
      for (final asset in data["assets"]) {
        final name = asset["name"] as String;
        if (Platform.isWindows && name.endsWith(".exe")) {
          return {"version": version, "url": asset["browser_download_url"]};
        } else if (!Platform.isWindows && name == "yt-dlp") {
          return {"version": version, "url": asset["browser_download_url"]};
        }
      }
    } catch (e) {
      print("Erro ao buscar release: $e"); // Para depuração
    }
    return null;
  }

  Future<bool> downloadBinary(String url) async {
    if (binaryFile == null) return false;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return false;
      await binaryFile!.writeAsBytes(res.bodyBytes);

      if (!Platform.isWindows) {
        final result = await Process.run("chmod", ["+x", binaryFile!.path]);
        if (result.exitCode != 0) return false;
      }
      return true;
    } catch (e) {
      print("Erro ao baixar binário: $e");
      return false;
    }
  }
}
