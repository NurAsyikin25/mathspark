import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'database/database_helper.dart';
import 'models/profil_siswa.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (Gemini API key dsb.) jika ada
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Catatan dotenv: .env tidak ditemukan atau belum disetel: $e');
  }

  // Cek apakah ProfilSiswa sudah ada di SQLite
  ProfilSiswa? profil;
  try {
    profil = await DatabaseHelper.instance.getProfil();
  } catch (e) {
    debugPrint('Error saat membaca profil dari SQLite: $e');
  }

  final bool hasProfil = profil != null && profil.namaSiswa.trim().isNotEmpty;

  runApp(
    MathSparkApp(
      initialScreen: hasProfil
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
    ),
  );
}

class MathSparkApp extends StatelessWidget {
  final Widget? initialScreen;

  const MathSparkApp({super.key, this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathSpark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5), // Indigo edukatif & teknologi
          primary: const Color(0xFF3F51B5),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: initialScreen ?? const AuthGateScreen(),
    );
  }
}

/// Fallback gate jika initialScreen tidak disediakan langsung
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfilSiswa?>(
      future: DatabaseHelper.instance.getProfil(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final profil = snapshot.data;
        if (profil != null && profil.namaSiswa.trim().isNotEmpty) {
          return const MainNavigationScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
