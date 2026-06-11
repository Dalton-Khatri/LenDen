import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class FriendAvatar extends StatelessWidget {
  final Friend friend;
  final double size;

  const FriendAvatar({
    super.key,
    required this.friend,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = friend.photoUrl;
    final isNetwork = photoUrl != null &&
        photoUrl.isNotEmpty &&
        photoUrl.startsWith('http');
    final isLocal = photoUrl != null &&
        photoUrl.isNotEmpty &&
        !photoUrl.startsWith('http') &&
        File(photoUrl).existsSync();

    if (isNetwork) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
      );
    }

    if (isLocal) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(photoUrl)),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withValues(alpha: 0.18),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          friend.emoji,
          style: TextStyle(fontSize: size * 0.46),
        ),
      ),
    );
  }
}