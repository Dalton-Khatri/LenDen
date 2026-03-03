import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double blur;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.color,
    this.blur = 15,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color ?? AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(color: AppTheme.glassBorder, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = AppTheme.glowPurple,
    this.glowRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.4),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}