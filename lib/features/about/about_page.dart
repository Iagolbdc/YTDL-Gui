import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_done, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              "YouTube Downloader",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Versão 1.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text(
              "Feito com Flutter e yt-dlp.\nBaixe vídeos e áudios do YouTube facilmente.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            const Text(
              "© 2025 - Todos os direitos reservados",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Desenvolvido com ❤️ para você",
              style: TextStyle(fontSize: 12, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
