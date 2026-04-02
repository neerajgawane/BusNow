import 'package:flutter/material.dart';

class CrowdBadge extends StatelessWidget {
  final String level;
  const CrowdBadge({super.key, required this.level});

  Color get color => switch (level) {
    'empty' => Colors.green,
    'moderate' => const Color(0xFFF9A825),
    'full' => Colors.orange,
    'overcrowded' => Colors.red,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
