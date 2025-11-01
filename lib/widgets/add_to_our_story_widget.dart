// lib/widgets/add_to_our_story_widget.dart
// 우리 이야기에 추가하는 체크박스 위젯입니다.

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AddToOurStoryWidget extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final String? label;

  const AddToOurStoryWidget({
    super.key,
    this.initialValue = false,
    required this.onChanged,
    this.label,
  });

  @override
  State<AddToOurStoryWidget> createState() => _AddToOurStoryWidgetState();
}

class _AddToOurStoryWidgetState extends State<AddToOurStoryWidget> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isChecked ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 체크박스
          GestureDetector(
            onTap: () {
              setState(() {
                _isChecked = !_isChecked;
              });
              widget.onChanged(_isChecked);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _isChecked ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: _isChecked ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _isChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // 라벨
          Expanded(
            child: Text(
              widget.label ?? '우리 이야기에 추가',
              style: TextStyle(
                fontSize: 14,
                color: _isChecked ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _isChecked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          // 아이콘
          Icon(
            Icons.timeline,
            size: 20,
            color: _isChecked ? AppColors.primary : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
