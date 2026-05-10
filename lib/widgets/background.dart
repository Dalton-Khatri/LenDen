import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Simple dark background — no animated orbs, no gradients.
class PurpleBackground extends StatelessWidget {
  final Widget child;
  const PurpleBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: child,
    );
  }
}