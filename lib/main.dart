import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_size/window_size.dart';
import 'app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Configurações específicas para cada plataforma
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings darwinSettings =
      DarwinInitializationSettings();

  // ✅ Configuração para Linux
  const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(
    defaultActionName: 'Abrir',
  );

  final InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
    macOS: darwinSettings,
    linux: linuxSettings, // ✅ Adicionado
  );
  await flutterLocalNotificationsPlugin.initialize(settings);

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    setWindowTitle('YTDL Gui');
    setWindowMinSize(const Size(600, 600));
    setWindowMaxSize(Size(1300, 800));
  }
  runApp(const MyApp());
}
