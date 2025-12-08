import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Coach/models/coach_entry.dart';
import 'package:move_buddy/Coach/screens/coach_update_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachDetailPage extends StatefulWidget {
  final Coach coach;
  final bool canEdit;

  const CoachDetailPage({
    super.key,
    required this.coach,
    this.canEdit = false,
  });

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage> {
  static const String _baseUrl = String.fromEnvironment(
    'COACH_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  late Coach coach;
  late CookieRequest _request;
  bool _isActionBusy = false;
  bool _didInitRequest = false;

  @override
  void initState() {
    super.initState();
    coach = widget.coach;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitRequest) {
      _request = context.read<CookieRequest>();
      _didInitRequest = true;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
      ),
    );
  }

  Future<void> _performAction(
    String path, {
    required VoidCallback onSuccess,
  }) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);
    try {
      final url = '$_baseUrl$path';
      final response = await _request.post(url, {});
      final success = response is Map && response['success'] == true;
      final message = (response is Map ? response['message'] : '')?.toString() ?? '';
      if (success) {
        onSuccess();
        _showSnack(message.isNotEmpty ? message : 'Berhasil');
      } else {
        _showSnack(
          message.isNotEmpty ? message : 'Gagal memproses aksi',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isActionBusy = false);
      }
    }
  }

  Future<void> _markAvailable() async {
    await _performAction(
      '/coach/mark-available/${coach.id}/',
      onSuccess: () {
        setState(() {
          coach = coach.copyWith(isBooked: false);
        });
      },
    );
  }

  Future<void> _markUnavailable() async {
    await _performAction(
      '/coach/mark-unavailable/${coach.id}/',
      onSuccess: () {
        setState(() {
          coach = coach.copyWith(isBooked: true);
        });
      },
    );
  }

  Future<void> _deleteCoach() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus coach?'),
        content: const Text(
          'Tindakan ini tidak bisa dibatalkan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _performAction(
      '/coach/delete-coach/${coach.id}/',
      onSuccess: () {
        Navigator.pop(context, true);
      },
    );
  }

  String _formatPrice(int price) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return price.toString().replaceAllMapped(formatter, (m) => '${m[1]}.');
  }

  String _formatDate(DateTime date) {
    final formatted = DateFormat('EEEE, dd MMMM yyyy').format(date);
    return formatted.toUpperCase();
  }

  String _formatTimeRange(String start, String end) {
    return '$start - $end';
  }

  String _buildWhatsappLink(String phone, String explicit) {
    if (explicit.isNotEmpty) return explicit;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    var normalized = digits;
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    } else if (!normalized.startsWith('62') &&
        !normalized.startsWith('60') &&
        !normalized.startsWith('+')) {
      normalized = '62$normalized';
    }
    normalized = normalized.replaceFirst('+', '');
    return 'https://wa.me/$normalized';
  }

  bool _hasValue(String? value) {
    final v = (value ?? '').trim();
    return v.isNotEmpty && v.toLowerCase() != 'null';
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternal(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link.')),
      );
    }
  }

  Future<void> _openUpdate() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CoachUpdatePage(coach: coach),
      ),
    );
    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.canEdit || coach.isOwner;
    final availabilityColor =
        coach.isBooked ? Colors.red.shade100 : Colors.green.shade100;
    final availabilityTextColor =
        coach.isBooked ? Colors.red.shade800 : Colors.green.shade800;
    final categoryLabel = coach.categoryDisplay ?? coach.category;

    final instagramLink = _hasValue(coach.instagramLink)
        ? coach.instagramLink.trim()
        : '';
    final mapsLink = _hasValue(coach.mapsLink) ? coach.mapsLink.trim() : '';
    final phoneRaw =
        _hasValue(coach.userPhone) ? coach.userPhone.trim() : coach.formattedPhone;
    final phone = _hasValue(phoneRaw) ? phoneRaw!.trim() : '';
    final whatsappLink = _buildWhatsappLink(
      phone,
      _hasValue(coach.whatsappLink) ? coach.whatsappLink.trim() : '',
    );

    String contactUrl;
    String contactLabel;
    if (whatsappLink.isNotEmpty) {
      contactUrl = whatsappLink;
      contactLabel = 'Book via WhatsApp';
    } else if (instagramLink.isNotEmpty) {
      contactUrl = instagramLink;
      contactLabel = 'View Instagram';
    } else if (mapsLink.isNotEmpty) {
      contactUrl = mapsLink;
      contactLabel = 'Buka Google Maps';
    } else if (phone.isNotEmpty) {
      final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      contactUrl = 'tel:$sanitized';
      contactLabel = 'Call';
    } else {
      contactUrl = '';
      contactLabel = 'Contact not available';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Coach Detail',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openUpdate();
                } else if (value == 'delete') {
                  _deleteCoach();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/coach/bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.8)),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0.4, sigmaY: 0.4),
                  child: Container(
                    color: Colors.white.withOpacity(0.02),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.grey.shade200,
                        height: 220,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: coach.imageUrl != null &&
                                      coach.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      coach.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey.shade300,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.image, size: 48),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade300,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image, size: 48),
                                    ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChip(
                                    label: coach.isBooked ? 'Booked' : 'Available',
                                    color: availabilityColor,
                                    textColor: availabilityTextColor,
                                    icon: coach.isBooked
                                        ? Icons.lock_clock
                                        : Icons.event_available,
                                  ),
                                  _buildChip(
                                    label: categoryLabel.toUpperCase(),
                                    color: Colors.white.withOpacity(0.9),
                                    textColor: Colors.grey.shade800,
                                  ),
                                  _buildChip(
                                    label: coach.rating.toStringAsFixed(1),
                                    color: Colors.orange.shade50,
                                    textColor: Colors.orange.shade800,
                                    icon: Icons.star,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      coach.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${coach.location.toUpperCase()} | ${_formatDate(coach.date)} | ${_formatTimeRange(coach.startTime, coach.endTime)}',
                      style: TextStyle(
                        letterSpacing: 0.8,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('DESCRIPTION'),
                    _sectionCard(
                      child: Text(
                        coach.description.isEmpty
                            ? 'No description provided.'
                            : coach.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('ADDRESS'),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coach.address,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: mapsLink.isEmpty
                                  ? null
                                  : () => _launchExternal(mapsLink),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Open in Google Maps'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1F2937),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('SCHEDULE'),
                    _sectionCard(
                      child: Column(
                        children: [
                          _infoRow(
                            label: 'Date',
                            value: _formatDate(coach.date),
                          ),
                          const Divider(height: 18),
                          _infoRow(
                            label: 'Time',
                            value: _formatTimeRange(
                              coach.startTime,
                              coach.endTime,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('COACH INFORMATION'),
                    _sectionCard(
                      child: Column(
                        children: [
                          _infoRow(label: 'Name', value: coach.userName),
                          const Divider(height: 18),
                          _infoRow(
                            label: 'Phone',
                            value: phone.isEmpty ? 'Not provided' : phone,
                            onTap: phone.isEmpty
                                ? null
                                : () {
                                    final sanitized = phone.replaceAll(
                                      RegExp(r'[^0-9+]'),
                                      '',
                                    );
                                    _launchExternal('tel:$sanitized');
                                  },
                          ),
                          const Divider(height: 18),
                          _infoRow(
                            label: 'Rating',
                            value: coach.rating.toStringAsFixed(1),
                          ),
                          const Divider(height: 18),
                          _infoRow(
                            label: 'Instagram',
                            value: instagramLink.isEmpty
                                ? 'Not provided'
                                : 'View Instagram',
                            onTap: instagramLink.isEmpty
                                ? null
                                : () => _launchExternal(
                                      instagramLink,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price per session'.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Rp ${_formatPrice(coach.price)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!isOwner)
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BOOKING',
                              style: TextStyle(
                                letterSpacing: 1,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hubungi langsung untuk mengamankan jadwalmu.',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: contactUrl.isEmpty
                                    ? null
                                    : () => _launchExternal(contactUrl),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  contactUrl.isEmpty
                                      ? 'Contact not available'
                                      : contactLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MANAGE COACH',
                              style: TextStyle(
                                letterSpacing: 1,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _manageButton(
                              label: 'Mark Available',
                              border: Colors.green.shade400,
                              text: Colors.green.shade800,
                              onPressed: _isActionBusy ? null : _markAvailable,
                            ),
                            const SizedBox(height: 10),
                            _manageButton(
                              label: 'Mark Unavailable',
                              border: Colors.orange.shade400,
                              text: Colors.orange.shade800,
                              onPressed: _isActionBusy ? null : _markUnavailable,
                            ),
                            const SizedBox(height: 10),
                            _manageButton(
                              label: 'Delete Coach',
                              border: Colors.red.shade400,
                              text: Colors.red.shade700,
                              onPressed: _isActionBusy ? null : _deleteCoach,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isActionBusy ? null : _openUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'EDIT COACH',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: TextStyle(
          letterSpacing: 1.2,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _manageButton({
    required String label,
    required Color border,
    required Color text,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: text.withOpacity(0.05),
          side: BorderSide(color: border, width: 1.3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              value,
              style: TextStyle(
                color: onTap == null ? const Color(0xFF111827) : Colors.blue,
                fontWeight: FontWeight.w700,
                decoration:
                    onTap == null ? TextDecoration.none : TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
