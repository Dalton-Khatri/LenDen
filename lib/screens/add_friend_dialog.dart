import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class AddFriendDialog extends StatefulWidget {
  final FirebaseService service;
  const AddFriendDialog({super.key, required this.service});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '👤';
  String? _photoPath;
  bool _loading = false;
  bool _usePhoto = false;
  String? _nameError;

  final List<String> _emojis = [
    '👤', '😊', '🧑', '👩', '👦', '👧',
    '🧔', '👱', '🎓', '🏠', '💼', '🎮',
  ];

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
        _usePhoto = true;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.purple1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Photo',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _photoBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.camera);
                    },
                  ),
                  _photoBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.gallery);
                    },
                  ),
                  if (_photoPath != null)
                    _photoBtn(
                      icon: Icons.delete_rounded,
                      label: 'Remove',
                      color: AppTheme.dangerRed,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _photoPath = null;
                          _usePhoto = false;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? AppTheme.accentPurple).withValues(alpha: 0.15),
              border: Border.all(
                  color:
                      (color ?? AppTheme.glowPurple).withValues(alpha: 0.4)),
            ),
            child:
                Icon(icon, color: color ?? AppTheme.softPurple, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color ?? AppTheme.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Friend',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.softPurple)),
              const SizedBox(height: 20),

              // Avatar preview
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            AppTheme.accentPurple.withValues(alpha: 0.5),
                            AppTheme.glowPurple.withValues(alpha: 0.3),
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.glowPurple
                                    .withValues(alpha: 0.3),
                                blurRadius: 16),
                          ],
                        ),
                        child: ClipOval(
                          child: _usePhoto && _photoPath != null
                              ? Image.file(File(_photoPath!),
                                  fit: BoxFit.cover, width: 80, height: 80)
                              : Center(
                                  child: Text(_selectedEmoji,
                                      style:
                                          const TextStyle(fontSize: 36))),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentPurple,
                            border: Border.all(
                                color: AppTheme.deepPurple, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to add photo',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 16),

              // Emoji picker (hidden when photo selected)
              if (!_usePhoto) ...[
                Text('Or choose avatar',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojis.map((e) {
                    final sel = e == _selectedEmoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = e),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel
                              ? AppTheme.accentPurple.withValues(alpha: 0.4)
                              : AppTheme.glassWhite,
                          border: Border.all(
                              color: sel
                                  ? AppTheme.glowPurple
                                  : AppTheme.glassBorder,
                              width: sel ? 2 : 1),
                        ),
                        child: Center(
                            child: Text(e,
                                style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Name field
              TextField(
                controller: _nameController,
                autofocus: false,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
                style:
                    GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Friend's name",
                  hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textSecondary),
                  errorText: _nameError,
                  filled: true,
                  fillColor: AppTheme.glassWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.glowPurple, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.dangerRed, width: 2),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _usePhoto && _photoPath != null
                        ? ClipOval(
                            child: Image.file(File(_photoPath!),
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover))
                        : Text(_selectedEmoji,
                            style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _addFriend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPurple,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text('Add',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addFriend() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a name');
      return;
    }
    setState(() {
      _loading = true;
      _nameError = null;
    });
    try {
      final error = await widget.service.addFriend(
        name,
        _selectedEmoji,
        photoPath: _usePhoto ? _photoPath : null,
      );
      if (error != null) {
        // Duplicate name
        setState(() {
          _nameError = error;
          _loading = false;
        });
        return;
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _nameError = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}