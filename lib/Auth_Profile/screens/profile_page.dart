import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Auth_Profile/screens/login_page.dart';
import 'package:move_buddy/Coach/screens/coach_entry_list.dart';
import 'package:move_buddy/Court/screens/court_list_screen.dart';
import 'package:move_buddy/Event/screens/event_list_page.dart';
import 'package:move_buddy/Sport_Partner/screens/sport_partner_home.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Keep trailing slash and append paths without a leading slash.
  final String baseUrl = 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/';
  final Color _accentGreen = const Color(0xFFC7EFA0);
  final Color _textDark = const Color(0xFF2F2F2F);

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _kelaminController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();

  bool _isEditing = false;
  bool _loading = true;
  bool _saving = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _kelaminController.dispose();
    _tanggalController.dispose();
    _nomorHpController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.get('${baseUrl}profile/api/');
      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        _namaController.text = (data['nama'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _kelaminController.text = _genderDisplay((data['kelamin'] ?? '').toString());
        _tanggalController.text = (data['tanggal_lahir'] ?? '').toString();
        _nomorHpController.text = (data['nomor_handphone'] ?? '').toString();
      } else {
        _showSnack(response['message'] ?? 'Gagal memuat profil');
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal memuat profil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _genderDisplay(String code) {
    switch (code.toUpperCase()) {
      case 'L':
        return 'Laki-laki';
      case 'P':
        return 'Perempuan';
      default:
        return code;
    }
  }

  String? _genderCode(String input) {
    final text = input.trim().toLowerCase();
    if (text.startsWith('l')) return 'L';
    if (text.startsWith('p')) return 'P';
    return null;
  }

  Future<void> _submitUpdate() async {
    if (_saving) return;
    if (_loading) return;

    final genderCode = _genderCode(_kelaminController.text);
    if (genderCode == null) {
      _showSnack('Jenis kelamin harus Laki-laki atau Perempuan');
      return;
    }

    if (_namaController.text.trim().isEmpty ||
        _tanggalController.text.trim().isEmpty ||
        _nomorHpController.text.trim().isEmpty) {
      _showSnack('Semua field kecuali email harus diisi');
      return;
    }

    setState(() => _saving = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.postJson(
        '${baseUrl}profile/api/',
        {
          'nama': _namaController.text.trim(),
          'kelamin': genderCode,
          'tanggal_lahir': _tanggalController.text.trim(),
          'nomor_handphone': _nomorHpController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        _showSnack('Profil berhasil diperbarui');
        setState(() => _isEditing = false);
        _fetchProfile();
      } else {
        _showSnack(response['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal memperbarui profil: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    final request = context.read<CookieRequest>();

    try {
      await request.postJson("${baseUrl}logout/", {});
    } catch (_) {
      // Ignore logout errors; still redirect
    } finally {
      if (!mounted) return;
      setState(() => _loggingOut = false);
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              image: DecorationImage(
                image: const AssetImage('assets/coach/bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.86),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        elevation: 12,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text(
                                  _isEditing ? 'Edit Profile' : 'Profile Kamu',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              _buildTextField(
                                label: 'Nama',
                                controller: _namaController,
                                enabled: _isEditing,
                              ),
                              _buildTextField(
                                label: 'Email',
                                controller: _emailController,
                                enabled: false,
                              ),
                              _buildTextField(
                                label: 'Jenis Kelamin',
                                controller: _kelaminController,
                                enabled: _isEditing,
                                hint: 'Laki-laki / Perempuan',
                              ),
                              _buildTextField(
                                label: 'Tanggal Lahir',
                                controller: _tanggalController,
                                enabled: _isEditing,
                                hint: 'YYYY-MM-DD',
                              ),
                              _buildTextField(
                                label: 'Nomor Handphone',
                                controller: _nomorHpController,
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 12),
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accentGreen,
                                      foregroundColor: _textDark,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _saving
                                        ? null
                                        : _loading
                                            ? null
                                            : _isEditing
                                                ? _submitUpdate
                                                : () => setState(() => _isEditing = true),
                                    child: _saving
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black54,
                                            ),
                                          )
                                        : Text(
                                            _isEditing
                                                ? 'Submit Perubahan'
                                                : 'Edit Profile',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled && !_loading,
            readOnly: !enabled,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: enabled ? const Color(0xFF8AA73B) : Colors.grey.shade300,
                  width: 1.4,
                ),
              ),
            ),
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.grey.shade600,
              fontSize: 14,
            ),
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
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.home, color: Colors.white),
              splashRadius: 26,
              tooltip: 'Home',
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
                      onTap: () {
                        Navigator.pop(context);
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    _menuTile(
                      label: 'Profile',
                      textStyle: textStyle,
                      onTap: () => Navigator.pop(context),
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
