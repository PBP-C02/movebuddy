import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/home_page.dart';
import 'package:move_buddy/Sport_Partner/screens/sport_partner_home.dart';

import 'court/screens/courts_list_screen.dart';
import 'court/services/court_service.dart';

void main() {
  const overrideBaseUrl = String.fromEnvironment('COURT_BASE_URL');
  final request = CookieRequest();
  final courtService = CourtService(
    request: request,
    baseUrl: overrideBaseUrl.isEmpty ? null : overrideBaseUrl,
  );
  runApp(MoveBuddyApp(courtService: courtService));
}

class MoveBuddyApp extends StatelessWidget {
  const MoveBuddyApp({super.key, required this.courtService});

  final CourtService courtService;

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'Move Buddy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
          useMaterial3: true,
        ),
        // UBAH DI SINI: Arahkan ke RootPage, bukan LoginPage/SportPartnerPage
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
  // Ganti dengan URL backend Anda
  final String baseUrl = "http://127.0.0.1:8000"; 

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final request = context.read<CookieRequest>();
    
    try {
      // Tanya ke server: "Saya masih login gak?"
      // Browser otomatis kirim cookie session lama di sini
      final response = await request.get("$baseUrl/check-session/");

      if (mounted) {
        if (response['loggedIn'] == true) {
          // Kalau masih login, langsung ke halaman utama
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Kalau tidak, tendang ke login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      // Jika error koneksi, default ke login page
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
    // Tampilkan loading saat sedang mengecek session
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}