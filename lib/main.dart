import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
=======
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/home_page.dart';
import 'package:move_buddy/Sport_Partner/screens/sport_partner_home.dart';
>>>>>>> 5754abf735301fd55bd55ebd40f702ad6e73cf12

// --- DAFTAR KONTAK (IMPORT) YANG HILANG SEBELUMNYA ---
import 'package:move_buddy/Auth_Profile/screens/login_page.dart'; 
import 'package:move_buddy/Auth_Profile/screens/homepage.dart'; // Kita akan buat file ini di Langkah 2
// ------------------------------------------------------

void main() {
<<<<<<< HEAD
  runApp(const MyApp());
=======
  const overrideBaseUrl = String.fromEnvironment('COURT_BASE_URL');
  final request = CookieRequest();
  final courtService = CourtService(
    request: request,
    baseUrl: overrideBaseUrl.isEmpty ? null : overrideBaseUrl,
  );
  runApp(MoveBuddyApp(courtService: courtService));
>>>>>>> 5754abf735301fd55bd55ebd40f702ad6e73cf12
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // Warna Lime sesuai request design html kamu
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
  // Ganti URL sesuai environment (Localhost/Deploy)
  final String baseUrl = "http://127.0.0.1:8000"; 

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$baseUrl/auth/check-session/"); // Pastikan URL di urls.py backend benar

      if (mounted) {
        if (response['loggedIn'] == true) {
          // Ambil nama user dari response backend buat ditampilkan di Home
          String userName = response['user'] ?? "Buddy";
          
          Navigator.pushReplacement(
            context,
<<<<<<< HEAD
            MaterialPageRoute(builder: (context) => HomePage(username: userName)),
=======
            MaterialPageRoute(builder: (context) => const HomePage()),
>>>>>>> 5754abf735301fd55bd55ebd40f702ad6e73cf12
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}