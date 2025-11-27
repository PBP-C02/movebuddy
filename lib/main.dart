import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/home_page.dart';
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
        Provider<CookieRequest>(create: (_) => CookieRequest()),
        ProxyProvider<CookieRequest, CourtService>(
          update: (_, request, __) => CourtService(request: request),
        ),
      ],
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
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
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
