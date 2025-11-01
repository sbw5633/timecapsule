// lib/screens/story_detail_screen.dart
// 스토리 상세 화면입니다.

import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../widgets/common_detail_layout.dart';
import '../utils/constants.dart';

class StoryDetailScreen extends StatelessWidget {
  final StoryModel story;

  const StoryDetailScreen({
    super.key,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스토리 상세'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: CommonDetailLayout(
        title: '스토리 상세',
        authorName: story.authorName,
        authorProfileImageUrl: story.authorProfileImageUrl.isNotEmpty ? story.authorProfileImageUrl : null,
        date: story.storyDate.toDate(),
        contentTitle: story.title,
        content: story.content,
        imageUrls: story.imageUrls,
        videoUrls: story.videoUrls,
      ),
    );
  }
}
