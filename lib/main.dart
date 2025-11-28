import 'dart:io'; // Perlu untuk deteksi Platform.isAndroid
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 

import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/home_page.dart';

// Import screen Court untuk memastikan path terbaca (opsional, untuk routing nanti)
// Pastikan path import ini sesuai dengan folder 'court' yang baru dibuat
// import 'package:move_buddy/court/screens/court_list_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Inisialisasi CookieRequest Global untuk Autentikasi
        Provider<CookieRequest>(create: (_) => CookieRequest()),
        
        // Catatan: CourtService dihapus karena modul Court yang baru 
        // menggunakan CourtApiHelper mandiri di setiap screen 
        // agar lebih sederhana dan tidak bergantung pada Provider injection.
      ],
      child: MaterialApp(
        title: 'Move Buddy',
        debugShowCheckedModeBanner: false, // Menghilangkan banner debug
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
          useMaterial3: true,
          // Menambahkan konfigurasi AppBar default agar konsisten
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF84CC16),
            foregroundColor: Colors.white,
          ),
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
  // Variabel baseUrl akan di-set secara dinamis di initState
  String baseUrl = "";

  @override
  void initState() {
    super.initState();
    _initUrl();
    
    // Beri jeda sedikit agar Provider siap
    Future.delayed(Duration.zero, () {
      checkSession();
    });
  }

  void _initUrl() {
    // Logika penentuan URL Backend
      baseUrl = "http://127.0.0.1:8000";

  }

  Future<void> checkSession() async {
    final request = context.read<CookieRequest>();
    try {
      // Endpoint cek session (sesuaikan dengan endpoint Django Anda yang mengembalikan status login)
      // Biasanya endpoint user profile atau check-auth khusus
      final response = await request.get("$baseUrl/auth_profile/check-session/");

      if (mounted) {
        // Cek logika respon dari Django
        // Asumsi: jika request.loggedIn true (library state) atau respon server OK
        if (request.loggedIn || (response is Map && response['status'] == true)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Jika belum login / sesi habis
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      // Jika terjadi error koneksi atau server down, arahkan ke Login Page
      // agar user bisa mencoba login ulang (atau tampilkan error screen)
      if (mounted) {
        debugPrint("Error check session: $e");
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Memuat sesi...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}