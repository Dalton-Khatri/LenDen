import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Solid rounded card — no frosted glass, no blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double blur; // kept for API compat, ignored
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
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppTheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ??
              Border.all(color: AppTheme.cardBorder, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Simple wrapper — no glow shadow.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = AppTheme.accent,
    this.glowRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}