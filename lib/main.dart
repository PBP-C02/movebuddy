import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// Import halaman Sport Partner kamu.
// Pastikan path ini sesuai dengan struktur folder di gambar kamu.
import 'package:move_buddy/Sport_Partner/screens/sport_partner_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // KITA BUNGKUS APLIKASI DENGAN PROVIDER
    // Ini seperti memasang instalasi listrik utama di rumah
    // agar semua ruangan (screen) bisa mengakses 'request'.
    return Provider(
      create: (_) {
        CookieRequest request = CookieRequest();
        return request;
      },
      child: MaterialApp(
        title: 'Move Buddy',
        theme: ThemeData(
          // Mengambil warna Lime/Hijau sesuai tema HTML kamu sebelumnya
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)), 
          useMaterial3: true,
        ),
        // ARUBAH DI SINI:
        // Jangan arahkan ke MyHomePage lagi.
        // Arahkan langsung ke SportPartnerPage.
        home: const SportPartnerPage(),
      ),
    );
  }
}