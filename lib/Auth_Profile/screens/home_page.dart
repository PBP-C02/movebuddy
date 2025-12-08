import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Auth_Profile/screens/profile_page.dart';
import 'package:move_buddy/Coach/screens/coach_entry_list.dart';
import 'package:move_buddy/Court/screens/court_list_screen.dart';
import 'package:move_buddy/Event/screens/event_list_page.dart';
import 'package:move_buddy/Sport_Partner/screens/sport_partner_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keep trailing slash and ensure paths are appended without a leading slash.
  final String baseUrl = 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/';
  final Color _accentGreen = const Color(0xFFA2D94D);
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final request = context.read<CookieRequest>();

    try {
      final response = await request.get('${baseUrl}check-session/');
      if (!mounted) return;
      setState(() {
        _fullName = (response['user'] as String?)?.trim();
      });
    } catch (_) {
      // Leave name null on failure; UI will fall back to a generic label.
    }
  }

  Future<void> _logout() async {
    final request = context.read<CookieRequest>();

    try {
      await request.postJson('${baseUrl}logout/', jsonEncode({}));
    } catch (_) {
      // Ignore logout errors, just redirect to login.
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: Colors.black.withOpacity(0.45),
      drawer: _buildSideMenu(context),
      body: Stack(
        children: [
          // Background with a subtle pattern
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              image: DecorationImage(
                image: const AssetImage('assets/coach/bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9),
                  BlendMode.srcATop,
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B0B0B), Color(0xFF161616)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
                splashRadius: 26,
                tooltip: 'Menu',
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MOVE BUDDY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => _loadUserName());
              },
              icon: const Icon(Icons.account_circle, color: Colors.white),
              splashRadius: 26,
              tooltip: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final greetingName =
        (_fullName != null && _fullName!.isNotEmpty) ? _fullName! : 'Move Buddy user';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Hi, $greetingName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
              children: [
                const TextSpan(text: 'Welcome to '),
                TextSpan(
                  text: 'Move Buddy',
                  style: TextStyle(
                    color: _accentGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text:
                      ', your one-stop platform to find courts, partners, coaches, and events for your favorite sports.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildActionCard(
          title: 'Mau nyari teman baru dengan hobby yang sama?',
          buttonLabel: 'Cari Sport Partner',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SportPartnerPage()),
            );
          },
        ),
        _buildActionCard(
          title: 'Lagi berminat ikut event-event olahraga?',
          buttonLabel: 'Cari Event',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventListPage()),
            );
          },
        ),
        _buildActionCard(
          title: 'Butuh coach untuk berlatih secara privat?',
          buttonLabel: 'Cari Coach',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoachEntryListPage()),
            );
          },
        ),
        _buildActionCard(
          title: 'Lagi nyari court yang dapat digunakan untuk aktivitas olahraga?',
          buttonLabel: 'Cari Court',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CourtListScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildSideMenu(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B0B0B), Color(0xFF1C1C1C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _menuTile(
                      label: 'Home',
                      textStyle: textStyle,
                      onTap: () => Navigator.pop(context),
                    ),
                    _menuTile(
                      label: 'Profile',
                      textStyle: textStyle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        ).then((_) => _loadUserName());
                      },
                    ),
                    _menuTile(
                      label: 'Sport Partner',
                      textStyle: textStyle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SportPartnerPage(),
                          ),
                        );
                      },
                    ),
                    _menuTile(
                      label: 'Event',
                      textStyle: textStyle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EventListPage(),
                          ),
                        );
                      },
                    ),
                    _menuTile(
                      label: 'Coach',
                      textStyle: textStyle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoachEntryListPage(),
                          ),
                        );
                      },
                    ),
                    _menuTile(
                      label: 'Court',
                      textStyle: textStyle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CourtListScreen(),
                          ),
                        );
                      },
                    ),
                    _menuTile(
                      label: 'Logout',
                      textStyle: textStyle.copyWith(color: Colors.red),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onTap: () {
                        Navigator.pop(context);
                        _confirmLogout();
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

  Widget _menuTile({
    required String label,
    required TextStyle textStyle,
    VoidCallback? onTap,
    Icon? icon,
  }) {
    return ListTile(
      leading: icon,
      title: Text(label, style: textStyle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minLeadingWidth: 0,
    );
  }
}
