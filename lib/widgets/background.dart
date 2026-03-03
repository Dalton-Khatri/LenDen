import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PurpleBackground extends StatefulWidget {
  final Widget child;
  const PurpleBackground({super.key, required this.child});

  @override
  State<PurpleBackground> createState() => _PurpleBackgroundState();
}

class _PurpleBackgroundState extends State<PurpleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepPurple,
              Color.lerp(AppTheme.purple1, const Color(0xFF2D1B69),
                  _animation.value)!,
              AppTheme.purple2,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Orb 1
            Positioned(
              top: -100 + (_animation.value * 40),
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentPurple.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Orb 2
            Positioned(
              bottom: 100 - (_animation.value * 30),
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3D0066).withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}