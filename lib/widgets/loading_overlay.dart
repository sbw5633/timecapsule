// lib/widgets/loading_overlay.dart
// 로딩 중일 때 표시할 오버레이 위젯입니다.

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LoadingOverlay extends StatefulWidget {
  final String message;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    required this.message,
    required this.isVisible,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _pulseController;
  late Animation<double> _fillAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 아이콘이 차오르는 애니메이션
    _fillController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // 펄스 애니메이션 (깜빡이는 효과)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _fillController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimations();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopAnimations();
    }
  }

  void _stopAnimations() {
    _fillController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _fillController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 막기
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 앱 아이콘 애니메이션
                AnimatedBuilder(
                  animation: Listenable.merge([_fillAnimation, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            // 배경 원
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            // 차오르는 애니메이션
                            ClipPath(
                              clipper: CircleFillClipper(_fillAnimation.value),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: const Icon(
                                  Icons.family_restroom, // 가족 아이콘 (앱 대표 아이콘)
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // 로딩 메시지
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 프로그레스 인디케이터
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 원이 차오르는 클리퍼
class CircleFillClipper extends CustomClipper<Path> {
  final double fillValue;

  CircleFillClipper(this.fillValue);

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 차오르는 높이 계산
    final fillHeight = size.height * fillValue;
    final fillTop = size.height - fillHeight;
    
    if (fillValue <= 0) {
      // 비어있는 상태
      return path;
    } else if (fillValue >= 1) {
      // 가득 찬 상태
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      // 부분적으로 차오른 상태
      final rect = Rect.fromLTWH(0, fillTop, size.width, fillHeight);
      path.addOval(rect);
    }
    
    return path;
  }

  @override
  bool shouldReclip(CircleFillClipper oldClipper) {
    return oldClipper.fillValue != fillValue;
  }
}
