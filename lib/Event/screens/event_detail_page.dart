import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/models/event_entry.dart';
import 'package:move_buddy/Event/utils/event_helpers.dart';
import 'package:move_buddy/Sport_Partner/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  EventEntry? event;
  bool isLoading = true;
  String? selectedScheduleId;

  @override
  void initState() {
    super.initState();
    EventHelpers.ensureLocaleInitialized().then((_) {
      if (mounted) setState(() {});
    });
    fetchEventDetail();
  }

  Future<void> fetchEventDetail() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$baseUrl/event/json/${widget.eventId}/');
      setState(() {
        event = EventEntry.fromJson(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> joinEvent(CookieRequest request) async {
    if (selectedScheduleId == null) {
      _showSnackBar('Please select a date first!', isError: true);
      return;
    }

    try {
      final response = await request.postJson(
        '$baseUrl/event/json/${widget.eventId}/join/',
        '{"schedule_id": "$selectedScheduleId"}',
      );

      if (mounted) {
        if (response['success']) {
          _showSnackBar(response['message']);
          fetchEventDetail();
        } else {
          _showSnackBar(response['message'], isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> cancelEvent(CookieRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: const Text('Are you sure you want to cancel all registrations for this event?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await request.post('$baseUrl/event/json/${widget.eventId}/cancel/', {});

      if (mounted) {
        if (response['success']) {
          _showSnackBar(response['message']);
          fetchEventDetail();
        } else {
          _showSnackBar(response['message'], isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF8BC34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _launchMaps() async {
    if (event?.googleMapsLink != null && event!.googleMapsLink.isNotEmpty) {
      final uri = Uri.parse(event!.googleMapsLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F5F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (event == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F5F9),
        body: Center(child: Text('Event not found')),
      );
    }

    final priceValue = double.tryParse(event!.entryPrice) ?? 0;
    final isAvailable = event!.status.toLowerCase() == 'available';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Event Detail",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeroCard(priceValue, isAvailable),
            const SizedBox(height: 16),
            _buildInfoCard(),
            if (event!.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                'Description',
                Icons.description,
                Text(
                  event!.description,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF0F172A)),
                ),
              ),
            ],
            if (event!.activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                'Activities & Facilities',
                Icons.sports_basketball,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: event!.activities
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .map((activity) => Chip(
                            label: Text(activity),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildLocationCard(),
            if (event!.schedules != null && event!.schedules!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSchedulesCard(),
            ],
            const SizedBox(height: 20),
            _buildActionButton(request),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(double entryPrice, bool isAvailable) {
    final statusColor = isAvailable ? const Color(0xFFDFF5E0) : const Color(0xFFFFE6E3);
    final statusTextColor = isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(22),
      shadowColor: Colors.black.withOpacity(0.16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildEventImage(),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  isAvailable ? "Available" : "Full",
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Entry Fee",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      EventHelpers.formatPrice(entryPrice),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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

  Widget _buildEventImage() {
    if (event == null || event!.photoUrl.isEmpty) return _buildPlaceholder();

    if (event!.photoUrl.startsWith('data:image')) {
      try {
        final data = Uri.parse(event!.photoUrl).data;
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(),
            fit: BoxFit.cover,
          );
        }
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    return Image.network(
      event!.photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          EventHelpers.getSportIcon(event?.sportType ?? ''),
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isOrganizer = event!.isOrganizer;
    final isRegistered = event!.isRegistered;

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 16, color: Color(0xFF5A6CEA)),
                    const SizedBox(width: 6),
                    Text(
                      EventHelpers.getSportDisplayName(event!.sportType),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isRegistered)
                _buildPill("Registered", Colors.blue.withOpacity(0.12), Colors.blue[700]!),
              if (isOrganizer)
                _buildPill("Your Event", Colors.orange.withOpacity(0.15), Colors.orange[800]!),
              const Spacer(),
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                EventHelpers.formatRating(double.tryParse(event!.rating) ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event!.city,
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.account_circle, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                "Organizer: ${event!.organizerName}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildSectionCard(
      'Location',
      Icons.place,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event!.fullAddress, style: const TextStyle(fontSize: 15, height: 1.5)),
          if (event!.googleMapsLink.isNotEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _launchMaps,
              icon: const Icon(Icons.map, size: 18),
              label: const Text('Open in Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E2E2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchedulesCard() {
    return _buildSectionCard(
      'Available Dates',
      Icons.calendar_today,
      Column(
        children: event!.schedules!.map((schedule) {
          final isSelected = selectedScheduleId == schedule.id;
          final isRegistered = event!.userSchedules?.contains(schedule.id) ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: isRegistered ? null : () => setState(() => selectedScheduleId = schedule.id),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isRegistered
                      ? const Color(0xFFDFF5E0)
                      : isSelected
                          ? const Color(0xFFE8F4DB)
                          : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRegistered
                        ? const Color(0xFF2E7D32)
                        : isSelected
                            ? const Color(0xFF8BC34A)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isRegistered
                          ? Icons.check_circle
                          : isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                      color: isRegistered
                          ? const Color(0xFF2E7D32)
                          : isSelected
                              ? const Color(0xFF8BC34A)
                              : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      EventHelpers.formatDateShort(schedule.date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isRegistered
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isRegistered) ...[
                      const Spacer(),
                      const Text(
                        'Registered',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(CookieRequest request) {
    if (event!.userSchedules != null && event!.userSchedules!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => cancelEvent(request),
          child: const Text(
            'Cancel Registration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    if (event!.schedules != null && event!.schedules!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E2E2E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => joinEvent(request),
          child: const Text(
            'Join Event',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8BC34A), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
