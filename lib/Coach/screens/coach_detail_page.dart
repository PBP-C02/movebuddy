import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:Movebuddy/Coach/models/coach_entry.dart';
import 'package:Movebuddy/Coach/screens/coach_update_page.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachDetailPage extends StatefulWidget {
  final Coach coach;
  final bool canEdit;

  const CoachDetailPage({super.key, required this.coach, this.canEdit = false});

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage> {
  static const String _baseUrl = String.fromEnvironment(
    'COACH_BASE_URL',
    defaultValue: 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/coach/',
  );
  static const String _bookPath = String.fromEnvironment(
    'COACH_BOOK_PATH',
    defaultValue: 'book-coach/{id}/',
  );
  static const String _cancelBookingPath = String.fromEnvironment(
    'COACH_CANCEL_PATH',
    defaultValue: 'cancel-booking/{id}/',
  );

  late Coach coach;
  late CookieRequest _request;
  bool _isActionBusy = false;
  bool _isBookingBusy = false;
  bool _didInitRequest = false;
  bool _didChange = false;
  String? _currentUserId;
  String get _normalizedBaseUrl =>
      _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final hasScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final withScheme = hasScheme ? trimmed : 'https://$trimmed';
    final encoded = withScheme.replaceAll(' ', '%20');
    final uri = Uri.tryParse(encoded);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return '';
    }
    return uri.toString();
  }

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
      _currentUserId = _resolveCurrentUserId();
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
      final url = (path.startsWith('http://') || path.startsWith('https://'))
          ? path
          : _buildActionUrl(path);
      final response = await _request.post(url, {});

      final success = response is Map && response['success'] == true;
      final message =
          (response is Map ? response['message'] : '')?.toString() ?? '';
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

  String _buildActionUrl(String path) {
    final base = _normalizedBaseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    if (path.contains('{id}')) {
      return '$base${normalizedPath.replaceAll('{id}', coach.id)}';
    }
    final normalized = normalizedPath.endsWith('/')
        ? normalizedPath
        : '$normalizedPath/';
    return '$base$normalized${coach.id}/';
  }

  Future<void> _toggleBooking() async {
    if (_isBookingBusy) return;
    setState(() => _isBookingBusy = true);

    final currentlyBooked = coach.isBooked;
    final bookedByMe =
        coach.bookedByMe ||
        (coach.participantId != null &&
            _currentUserId != null &&
            coach.participantId == _currentUserId);
    if (currentlyBooked && !bookedByMe) {
      _showSnack('Coach sudah dibooking pengguna lain.', isError: true);
      setState(() => _isBookingBusy = false);
      return;
    }

    final path = bookedByMe ? _cancelBookingPath : _bookPath;
    final payload = <String, String>{};
    final normalizedInstagram = _normalizeUrl(coach.instagramLink);
    if (normalizedInstagram.isNotEmpty) {
      payload['instagram_link'] = normalizedInstagram;
    }
    final normalizedMaps = _normalizeUrl(coach.mapsLink);
    if (normalizedMaps.isNotEmpty) {
      payload['mapsLink'] = normalizedMaps;
    }

    try {
      final url = _buildActionUrl(path);
      final response = await _request.post(url, payload);
      final success = response is Map && response['success'] == true;
      final message =
          (response is Map ? response['message'] : '')?.toString() ?? '';

      if (success) {
        setState(() {
          final nextBooked = bookedByMe ? false : true;
          coach = coach.copyWith(isBooked: nextBooked, bookedByMe: nextBooked);
          _didChange = true;
        });
        _showSnack(
          message.isNotEmpty
              ? message
              : (bookedByMe ? 'Booking dibatalkan' : 'Booking berhasil'),
        );
      } else {
        _showSnack(
          message.isNotEmpty ? message : 'Gagal memproses booking',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBookingBusy = false);
      }
    }
  }

  String? _resolveCurrentUserId() {
    final cookieId = _request.cookies['user_id']?.toString();
    if (cookieId != null && cookieId.isNotEmpty) return cookieId;

    final data = _request.jsonData;
    if (data is Map) {
      for (final key in ['id', 'user_id', 'userId']) {
        final val = data[key];
        if (val != null && val.toString().isNotEmpty) {
          return val.toString();
        }
      }
    }
    return null;
  }

  Future<void> _markAvailable() async {
    await _performAction(
      'mark-available/{id}/',
      onSuccess: () {
        setState(() {
          coach = coach.copyWith(isBooked: false);
        });
      },
    );
  }

  Future<void> _markUnavailable() async {
    await _performAction(
      'mark-unavailable/{id}/',
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
        content: const Text('Tindakan ini tidak bisa dibatalkan. Lanjutkan?'),
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
      'delete-coach/{id}/',
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
      MaterialPageRoute(builder: (_) => CoachUpdatePage(coach: coach)),
    );
    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner =
        widget.canEdit ||
        coach.isOwner ||
        (_currentUserId != null &&
            coach.userId.isNotEmpty &&
            coach.userId == _currentUserId);
    final isBookedByMe = coach.bookedByMe;
    final showBookingSection = !isOwner;
    final availabilityColor = coach.isBooked
        ? Colors.red.shade100
        : Colors.green.shade100;
    final availabilityTextColor = coach.isBooked
        ? Colors.red.shade800
        : Colors.green.shade800;
    final categoryLabel = coach.categoryDisplay ?? coach.category;

    final instagramLink = _hasValue(coach.instagramLink)
        ? _normalizeUrl(coach.instagramLink)
        : '';
    final mapsLink = _hasValue(coach.mapsLink)
        ? _normalizeUrl(coach.mapsLink)
        : '';
    final phoneRaw = _hasValue(coach.userPhone)
        ? coach.userPhone.trim()
        : coach.formattedPhone;
    final phone = _hasValue(phoneRaw) ? phoneRaw!.trim() : '';
    final whatsappLink = _buildWhatsappLink(
      phone,
      _hasValue(coach.whatsappLink) ? coach.whatsappLink.trim() : '',
    );

    final isBooked = coach.isBooked;
    final bookingLabel = isBookedByMe
        ? 'Cancel Booking'
        : isBooked
        ? 'Sudah dibooking'
        : 'Book Coach';
    final bookingColor = isBookedByMe
        ? Colors.red.shade600
        : const Color(0xFF22C55E);
    final showWhatsApp = isBooked && isBookedByMe && whatsappLink.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _didChange);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                            child:
                                coach.imageUrl != null &&
                                    coach.imageUrl!.isNotEmpty
                                ? Image.network(
                                    coach.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey.shade300,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.image,
                                                size: 48,
                                              ),
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
                                  label: coach.isBooked
                                      ? 'Booked'
                                      : 'Available',
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
                        _infoRow(label: 'Date', value: _formatDate(coach.date)),
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
                              : () => _launchExternal(instagramLink),
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
                  if (!isOwner && showBookingSection)
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
                              onPressed:
                                  _isBookingBusy || (!isBookedByMe && isBooked)
                                  ? null
                                  : _toggleBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bookingColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isBookingBusy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      bookingLabel,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          if (showWhatsApp) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _launchExternal(whatsappLink),
                                icon: const Icon(
                                  Icons.chat,
                                  color: Color(0xFF22C55E),
                                ),
                                label: const Text(
                                  'Hubungi via WhatsApp',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1F2937),
                                  side: const BorderSide(
                                    color: Color(0xFF22C55E),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (isOwner)
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
                decoration: onTap == null
                    ? TextDecoration.none
                    : TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
