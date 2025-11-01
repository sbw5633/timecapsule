// lib/screens/our_story_detail_screen.dart
// 우리 이야기 상세 화면입니다.

import 'package:flutter/material.dart';
import '../models/our_story_model.dart';
import '../utils/constants.dart';
import '../widgets/common_detail_layout.dart';

class OurStoryDetailScreen extends StatelessWidget {
  final OurStoryModel story;

  const OurStoryDetailScreen({
    super.key,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우리 이야기'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: CommonDetailLayout(
        title: '우리 이야기',
        authorName: story.authorName,
        authorProfileImageUrl: story.authorProfileImageUrl,
        date: story.storyDate,
        contentTitle: story.title,
        content: story.content,
        imageUrls: story.imageUrls,
      ),
    );
  }
}
