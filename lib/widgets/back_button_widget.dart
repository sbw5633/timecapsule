// lib/widgets/back_button_widget.dart
// 뒤로가기 버튼 위젯

import 'package:flutter/material.dart';

class BackButtonWidget extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const BackButtonWidget({
    super.key,
    required this.title,
    required this.onBack,
  });

  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 8.0;
  static const double _fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

