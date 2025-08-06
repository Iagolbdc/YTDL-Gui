import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppPaths {
  static Future<String> getBinaryPath() async {
    final dir = await getApplicationSupportDirectory();
    final binName = Platform.isWindows ? "yt-dlp.exe" : "yt-dlp";
    return "${dir.path}/$binName";
  }
}
