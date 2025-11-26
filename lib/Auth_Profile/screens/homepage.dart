import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';

// --- IMPORT HALAMAN FITUR (Pastikan path ini sesuai folder kamu) ---
import 'package:move_buddy/Sport_Partner/screens/sport_partner_home.dart';
import 'package:move_buddy/Event/screens/event_list_page.dart';
import 'package:move_buddy/Court/screens/courts_list_screen.dart';
import 'package:move_buddy/Coach/screens/coach_entry_list.dart';

class HomePage extends StatelessWidget {
  final String username;
  const HomePage({super.key, required this.username});

  // Ganti URL sesuai environment (Localhost / Deploy)
  final String baseUrl = "http://127.0.0.1:8000";

  Future<void> handleLogout(BuildContext context, CookieRequest request) async {
    try {
      final response = await request.logout("$baseUrl/auth/logout/");
      if (context.mounted) {
        if (response['status']) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal logout")),
          );
        }
      }
    } catch (e) {
      // Fallback jika error koneksi
      if (context.mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, $username!",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        "Let's get moving today.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () => handleLogout(context, request),
                    tooltip: "Logout",
                  )
                ],
              ),
              
              const SizedBox(height: 30),

              // 2. Menu Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, // 2 Kolom
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    // TOMBOL 1: SPORT PARTNER
                    _buildMenuCard(
                      context,
                      title: "Find Partner",
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF84CC16), // Lime Green
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SportPartnerPage()),
                        );
                      },
                    ),

                    // TOMBOL 2: EVENT
                    _buildMenuCard(
                      context,
                      title: "Join Events",
                      icon: Icons.emoji_events_rounded,
                      color: Colors.orange,
                      onTap: () {
                        // NAVIGASI KE EVENT
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EventListPage()),
                        );
                      },
                    ),

                    // TOMBOL 3: COURT
                    _buildMenuCard(
                      context,
                      title: "Book Court",
                      icon: Icons.stadium_rounded,
                      color: Colors.blueAccent,
                      onTap: () {
                        // NAVIGASI KE COURT
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CourtsListScreen()),
                        );
                      },
                    ),

                    // TOMBOL 4: COACH
                    _buildMenuCard(
                      context,
                      title: "Find Coach",
                      icon: Icons.sports_kabaddi_rounded,
                      color: Colors.purpleAccent,
                      onTap: () {
                        // NAVIGASI KE COACH
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CoachEntryListPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Card
  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}