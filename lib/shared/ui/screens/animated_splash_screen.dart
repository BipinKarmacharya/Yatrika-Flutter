import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tour_guide/core/theme/app_colors.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSplashScreen({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _pageFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFloatAnimation;
  late Animation<double> _logoGlowAnimation;

  late Animation<double> _titleOpacityAnimation;
  late Animation<Offset> _titleSlideAnimation;

  late Animation<double> _taglineOpacityAnimation;
  late Animation<Offset> _taglineSlideAnimation;

  late Animation<double> _loaderOpacityAnimation;
  late Animation<double> _loaderScaleAnimation;

  late Animation<double> _planeProgressAnimation;
  late Animation<double> _planeVerticalAnimation;
  late Animation<double> _planeRotationAnimation;
  late Animation<double> _planeOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.72,
              end: 1.06,
            ).chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.06,
              end: 0.98,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 20,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.98,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 20,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.06, 0.72, curve: Curves.easeOut),
          ),
        );

    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.20), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    _logoFloatAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -8.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -8.0,
          end: -2.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _logoGlowAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.6,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          ),
        );

    _titleOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.74, curve: Curves.easeIn),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.34, 0.78, curve: Curves.easeOutCubic),
          ),
        );

    _taglineOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.90, curve: Curves.easeIn),
    );

    _taglineSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.50, 0.92, curve: Curves.easeOutCubic),
          ),
        );

    _loaderOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.74, 1.0, curve: Curves.easeIn),
    );

    _loaderScaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.76, 1.0, curve: Curves.easeOut),
      ),
    );

    _planeProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.96, curve: Curves.easeInOut),
      ),
    );

    _planeVerticalAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 10.0,
              end: -8.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -8.0,
              end: 8.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.12, 0.96, curve: Curves.easeInOut),
          ),
        );

    _planeRotationAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: -0.08,
              end: 0.05,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.05,
              end: -0.03,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.12, 0.96, curve: Curves.easeInOut),
          ),
        );

    _planeOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.34, curve: Curves.easeOut),
    );

    _controller.forward();

    Timer(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.child,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = _logoGlowAnimation.value;
          final bgBegin = Alignment.lerp(
            const Alignment(-1.0, -1.0),
            const Alignment(-0.2, -0.5),
            _controller.value,
          )!;
          final bgEnd = Alignment.lerp(
            const Alignment(1.0, 1.0),
            const Alignment(0.4, 1.0),
            _controller.value,
          )!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final planeX =
                  -140 +
                  ((constraints.maxWidth + 280) *
                      _planeProgressAnimation.value);
              final planeY =
                  (constraints.maxHeight * 0.22) +
                  _planeVerticalAnimation.value;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: bgBegin,
                    end: bgEnd,
                    colors: const [
                      Color(0xFFE7F8EF),
                      Colors.white,
                      Color(0xFFF0FAF5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: planeX,
                      top: planeY,
                      child: Opacity(
                        opacity: _planeOpacityAnimation.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 108,
                              height: 4.2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.0),
                                    AppColors.primary.withValues(alpha: 0.12),
                                    AppColors.primary.withValues(alpha: 0.30),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Transform.rotate(
                              angle:
                                  (math.pi / 2) + _planeRotationAnimation.value,
                              child: Icon(
                                Icons.airplanemode_active_rounded,
                                size: 46,
                                color: AppColors.primary.withValues(
                                  alpha: 0.92,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: FadeTransition(
                        opacity: _pageFadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(0, _logoFloatAnimation.value),
                              child: SlideTransition(
                                position: _logoSlideAnimation,
                                child: Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 240 + (24 * glow),
                                        height: 180 + (14 * glow),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppColors.primary.withValues(
                                                alpha: 0.18 + (0.08 * glow),
                                              ),
                                              AppColors.primary.withValues(
                                                alpha: 0.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            42,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(
                                                    alpha: 0.12 + (0.10 * glow),
                                                  ),
                                              blurRadius: 18 + (14 * glow),
                                              spreadRadius: 2 + (3 * glow),
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            42,
                                          ),
                                          child: SizedBox(
                                            width: 236,
                                            height: 184,
                                            child: Image.asset(
                                              'assets/applogo.png',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Image.asset(
                                                      'assets/logo.png',
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _titleOpacityAnimation,
                              child: SlideTransition(
                                position: _titleSlideAnimation,
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Yatri',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'ka',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _taglineOpacityAnimation,
                              child: SlideTransition(
                                position: _taglineSlideAnimation,
                                child: Text(
                                  'Your Journey Begins Here',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),
                            FadeTransition(
                              opacity: _loaderOpacityAnimation,
                              child: ScaleTransition(
                                scale: _loaderScaleAnimation,
                                child: const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
