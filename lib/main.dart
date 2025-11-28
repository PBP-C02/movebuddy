// lib/main.dart
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // PENTING
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/home_page.dart'; // Sesuaikan path
import 'package:move_buddy/Court/services/court_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Inisialisasi CookieRequest Global (Dompet Bersama)
        Provider<CookieRequest>(create: (_) => CookieRequest()),

        // 2. Inject ke CourtService
        ProxyProvider<CookieRequest, CourtService>(
          update: (_, request, __) => CourtService(request: request),
        ),
      ],
      child: MaterialApp(
        title: 'Move Buddy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
          useMaterial3: true,
        ),
        home: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // FIX URL: Samakan dengan yang ada di CourtService dan LoginPage!
  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    // Beri jeda sedikit agar Provider siap
    Future.delayed(Duration.zero, () {
      checkSession();
    });
  }

  Future<void> checkSession() async {
    final request = context.read<CookieRequest>();
    try {
      // Cek apakah user punya session aktif di server
      // Ganti URL ini ke endpoint yang valid di djangomu, misal get profile
      // Kalau belum ada endpoint check-session, biarkan dia gagal ke catch (Login Page)
      final response = await request.get(
        "$baseUrl/auth_profile/check-session/",
      );

      if (mounted) {
        // Jika server bilang OK, atau request.loggedIn sudah true
        if (request.loggedIn ||
            (response is Map && response['status'] == true)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Jika tidak, lempar ke Login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      // Error koneksi dll -> Login Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
