import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  final String status;
  final double? progress;

  const StatusBar({super.key, required this.status, this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (progress != null) LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text(
          status,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: status.startsWith("✅")
                ? Colors.greenAccent
                : status.startsWith("⚠️") || status.startsWith("❌")
                ? Colors.orange
                : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
