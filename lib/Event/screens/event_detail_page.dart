import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/models/event_entry.dart';
import 'package:move_buddy/Event/utils/event_helpers.dart';
import 'package:move_buddy/Sport_Partner/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;
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
        backgroundColor: isError ? Colors.red : const Color(0xFF84CC16),
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
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF84CC16))),
      );
    }

    if (event == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: Text('Event not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (event!.description.isNotEmpty) _buildDescription(),
                  if (event!.description.isNotEmpty) const SizedBox(height: 16),
                  _buildLocation(),
                  const SizedBox(height: 16),
                  if (event!.activities.isNotEmpty) _buildActivities(),
                  if (event!.activities.isNotEmpty) const SizedBox(height: 16),
                  if (event!.schedules != null && event!.schedules!.isNotEmpty) _buildSchedules(),
                  if (event!.schedules != null && event!.schedules!.isNotEmpty) const SizedBox(height: 24),
                  _buildActionButton(request),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF84CC16),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: event!.photoUrl.isNotEmpty
            ? Image.network(event!.photoUrl, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder())
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(EventHelpers.getSportIcon(event!.sportType), style: const TextStyle(fontSize: 80)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(EventHelpers.getSportIcon(event!.sportType), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                EventHelpers.getSportDisplayName(event!.sportType),
                const Color(0xFF84CC16),
              ),
              _buildBadge(
                event!.status == 'available' ? 'AVAILABLE' : 'FULL',
                event!.status == 'available' ? const Color(0xFF10B981) : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, event!.city),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.star, '${EventHelpers.formatRating(double.parse(event!.rating))} / 5.0'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFF84CC16), size: 24),
              const SizedBox(width: 8),
              Text(
                EventHelpers.formatPrice(double.parse(event!.entryPrice)),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF84CC16),
                ),
              ),
              const Text(
                ' entry fee',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return _buildCard(
      'Description',
      Icons.description,
      Text(event!.description, style: const TextStyle(fontSize: 15, height: 1.5)),
    );
  }

  Widget _buildLocation() {
    return _buildCard(
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
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivities() {
    final activities = event!.activities.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return _buildCard(
      'Activities & Facilities',
      Icons.sports_basketball,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: activities.map((activity) {
          return Chip(
            label: Text(activity),
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSchedules() {
    return _buildCard(
      'Available Dates',
      Icons.calendar_today,
      Column(
        children: event!.schedules!.map((schedule) {
          final isSelected = selectedScheduleId == schedule.id;
          final isRegistered = event!.userSchedules?.contains(schedule.id) ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: isRegistered ? null : () => setState(() => selectedScheduleId = schedule.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRegistered
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : isSelected
                          ? const Color(0xFF84CC16).withOpacity(0.1)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRegistered
                        ? const Color(0xFF10B981)
                        : isSelected
                            ? const Color(0xFF84CC16)
                            : const Color(0xFFE2E8F0),
                    width: 2,
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
                          ? const Color(0xFF10B981)
                          : isSelected
                              ? const Color(0xFF84CC16)
                              : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      EventHelpers.formatDateShort(schedule.date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isRegistered
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isRegistered) ...[
                      const Spacer(),
                      const Text(
                        'Registered',
                        style: TextStyle(
                          color: Color(0xFF10B981),
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
            elevation: 0,
          ),
          onPressed: () => cancelEvent(request),
          child: const Text('CANCEL REGISTRATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      );
    }

    if (event!.schedules != null && event!.schedules!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF84CC16),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => joinEvent(request),
          child: const Text('JOIN EVENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildCard(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF84CC16), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
}