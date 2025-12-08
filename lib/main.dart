import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';


import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/home_page.dart';


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
      
      ],
      child: MaterialApp(
        title: 'Move Buddy',
        debugShowCheckedModeBanner: false, 
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84CC16)),
          useMaterial3: true,
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
  String baseUrl = "";

  @override
  void initState() {
    super.initState();
    _initUrl();
    
    Future.delayed(Duration.zero, () {
      checkSession();
    });
  }

  void _initUrl() {
      baseUrl = "https://ari-darrell-movebuddy.pbp.cs.ui.ac.id";

  }

  Future<void> checkSession() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get("$baseUrl/check-session/");

      if (mounted) {
        if (request.loggedIn || (response is Map && response['status'] == true)) {
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