import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PaisaSaathiApp());
}

class PaisaSaathiApp extends StatelessWidget {
  const PaisaSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    return MaterialApp(
      title: 'Paisa Saathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<User?>(
        stream: service.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.deepPurple,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.glowPurple,
                ),
              ),
            );
          }
          if (snapshot.data != null) {
            return HomeScreen(service: service);
          }
          return LoginScreen(service: service);
        },
      ),
    );
  }
}