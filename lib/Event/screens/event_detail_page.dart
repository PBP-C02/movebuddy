import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/models/event_entry.dart';
import 'package:move_buddy/Event/utils/event_helpers.dart';
import 'package:move_buddy/Event/screens/edit_event_form.dart';
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
        selectedScheduleId = null; // clear old selection after refresh
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
    if (event?.isOrganizer == true) {
      _showSnackBar('You cannot join your own event', isError: true);
      return;
    }

    if ((event?.status.toLowerCase() ?? '') != 'available') {
      _showSnackBar('Event is currently unavailable', isError: true);
      return;
    }

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

  Future<void> toggleAvailability(CookieRequest request) async {
    if (event == null) return;
    
    final bool newAvailability = event!.status != 'available';
    
    try {
      final response = await request.postJson(
        '$baseUrl/event/json/${widget.eventId}/toggle-availability/',
        '{"is_available": $newAvailability}',
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

  Future<void> deleteEvent(CookieRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await request.post('$baseUrl/event/json/${widget.eventId}/delete/', {});

      if (mounted) {
        if (response['success']) {
          _showSnackBar(response['message']);
          Navigator.pop(context, true); // Go back to event list
        } else {
          _showSnackBar(response['message'], isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
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
                  _buildMetaOverview(),
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
    final request = context.read<CookieRequest>();
    
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
      actions: event!.isOrganizer ? [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventForm(event: event!),
                ),
              );
              if (result == true) fetchEventDetail();
            } else if (value == 'toggle') {
              toggleAvailability(request);
            } else if (value == 'delete') {
              deleteEvent(request);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Text('Edit Event'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    event!.status == 'available' ? Icons.block : Icons.check_circle,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Text(event!.status == 'available' ? 'Mark Unavailable' : 'Mark Available'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete Event', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ] : null,
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

  Widget _buildMetaOverview() {
    final isAvailable = event!.status.toLowerCase() == 'available';
    final statusLabel = isAvailable ? 'Available' : 'Unavailable';
    final ratingValue = EventHelpers.formatRating(double.tryParse(event!.rating) ?? 0);
    final createdDate = EventHelpers.formatDateShort(event!.createdAt);
    final categoryLabel = event!.category.isNotEmpty ? event!.category : 'Uncategorized';

    return _buildCard(
      'Event Snapshot',
      Icons.insights,
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.person_outline,
                  label: 'Organizer',
                  value: event!.organizerName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: categoryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.flag_outlined,
                  label: 'Status',
                  value: statusLabel,
                  accent: isAvailable ? const Color(0xFF10B981) : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created',
                  value: createdDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.location_city_outlined,
                  label: 'City',
                  value: event!.city,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.star_rate_rounded,
                  label: 'Rating',
                  value: '$ratingValue / 5',
                  accent: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.sports_soccer,
                  label: 'Sport',
                  value: EventHelpers.getSportDisplayName(event!.sportType),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaTile(
                  icon: Icons.payments_outlined,
                  label: 'Entry Fee',
                  value: EventHelpers.formatPrice(double.tryParse(event!.entryPrice) ?? 0),
                  accent: const Color(0xFF84CC16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedules() {
    final isOrganizer = event!.isOrganizer;
    final isEventAvailable = event!.status.toLowerCase() == 'available';

    return _buildCard(
      'Available Dates',
      Icons.calendar_today,
      Column(
        children: event!.schedules!.map((schedule) {
          final isSelected = selectedScheduleId == schedule.id;
          final isRegistered = event!.userSchedules?.contains(schedule.id) ?? false;
          final canSelect = !isOrganizer && isEventAvailable && !isRegistered;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: canSelect ? () => setState(() => selectedScheduleId = schedule.id) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOrganizer
                      ? const Color(0xFFF1F5F9)
                      : isRegistered
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : isSelected
                              ? const Color(0xFF84CC16).withOpacity(0.1)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOrganizer
                        ? const Color(0xFFE2E8F0)
                        : isRegistered
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
                        color: isOrganizer
                            ? const Color(0xFF475569)
                            : isRegistered
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
                    ] else if (isOrganizer) ...[
                      const Spacer(),
                      Text(
                        'Organizer view',
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
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
    final isOrganizer = event!.isOrganizer;
    final isEventAvailable = event!.status.toLowerCase() == 'available';
    final hasSchedules = event!.schedules != null && event!.schedules!.isNotEmpty;
    final hasRegistration = event!.userSchedules != null && event!.userSchedules!.isNotEmpty;

    if (isOrganizer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You are the organizer. Manage availability below.',
            style: TextStyle(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEventAvailable ? Colors.red : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => toggleAvailability(request),
              child: Text(
                isEventAvailable ? 'MARK UNAVAILABLE' : 'MARK AVAILABLE',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventForm(event: event!),
                  ),
                );
                if (result == true) fetchEventDetail();
              },
              child: const Text('EDIT EVENT'),
            ),
          ),
        ],
      );
    }

    if (hasRegistration) {
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

    if (!isEventAvailable) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2E8F0),
            foregroundColor: const Color(0xFF94A3B8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: null,
          child: const Text('EVENT UNAVAILABLE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      );
    }

    if (hasSchedules) {
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

  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
    Color? accent,
  }) {
    final Color iconColor = accent ?? const Color(0xFF0F172A);
    final Color borderColor = accent?.withOpacity(0.4) ?? const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: (accent ?? const Color(0xFF84CC16)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
