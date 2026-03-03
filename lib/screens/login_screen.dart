import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';

class LoginScreen extends StatefulWidget {
  final FirebaseService service;
  const LoginScreen({super.key, required this.service});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepPurple,
      body: PurpleBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentPurple.withOpacity(0.7),
                        AppTheme.glowPurple.withOpacity(0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.glowPurple.withOpacity(0.5),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💸', style: TextStyle(fontSize: 54)),
                  ),
                )
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.elasticOut),

                const SizedBox(height: 28),

                // App name
                Text(
                  'LenDen',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppTheme.softPurple, AppTheme.lightPurple],
                      ).createShader(const Rect.fromLTWH(0, 0, 220, 60)),
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Paisa Saathi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms),

                const Spacer(flex: 2),

                // Single CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Get Started',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                Text(
                  'Free • No account needed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await widget.service.signInAnonymously();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Try again.',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }
}