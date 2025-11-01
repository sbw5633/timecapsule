// lib/widgets/empty_state_widget.dart
// 빈 상태 위젯

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final double iconSize;
  final double fontSize;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.book_outlined,
    this.iconSize = 64.0,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

