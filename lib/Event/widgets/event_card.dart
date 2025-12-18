import 'package:flutter/material.dart';
import '../models/event_entry.dart';
import '../utils/event_helpers.dart';

class EventCard extends StatelessWidget {
  final EventEntry event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(22),
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  String _availabilityLabel(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();
    if (status == 'available') return 'Tersedia';
    if (status == 'unavailable') return 'Tidak tersedia';
    if (status == 'full') return 'Penuh';
    if (status.isEmpty) return '';
    return status;
  }

  Widget _buildImage() {
    final isAvailable = event.status.toLowerCase() == 'available';
    final statusColor =
        isAvailable ? const Color(0xFFDFF5E0) : const Color(0xFFFFE6E3);
    final statusTextColor =
        isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final label = _availabilityLabel(event.status);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPhotoContent(),
          ),
          if (label.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (event.photoUrl.isEmpty) return _buildPlaceholder();

    if (event.photoUrl.startsWith('data:image')) {
      try {
        final data = Uri.parse(event.photoUrl).data;
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
      event.photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          EventHelpers.getSportIcon(event.sportType),
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _chip({
    required Widget leading,
    required String label,
    required Color border,
    required Color foreground,
    Color background = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasOrganizer = event.organizerName.trim().isNotEmpty;
    final hasAddress = event.fullAddress.trim().isNotEmpty;
    final parsedRating = double.tryParse(event.rating) ?? 0;
    final hasRating = parsedRating > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.isRegistered)
            _badge(
              label: 'Sudah dibooking',
              background: const Color(0xFFFFE4E6),
              foreground: const Color(0xFFDC2626),
            )
          else if (event.isOrganizer)
            _badge(
              label: 'Event kamu',
              background: const Color(0xFFE7F5D0),
              foreground: const Color(0xFF3F6212),
            ),
          const SizedBox(height: 10),
          Text(
            event.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasOrganizer) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.organizerName,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _chip(
                leading: Text(
                  EventHelpers.getSportIcon(event.sportType),
                  style: const TextStyle(fontSize: 18),
                ),
                label: EventHelpers.getSportDisplayName(event.sportType),
                border: const Color(0xFFBEEA79),
                foreground: const Color(0xFF1F2937),
                background: const Color(0xFFF2F8E8),
              ),
              _chip(
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                label: event.city.isNotEmpty ? event.city : 'Lokasi belum ada',
                border: const Color(0xFFCBD5E1),
                foreground: const Color(0xFF64748B),
                background: const Color(0xFFF8FAFC),
              ),
              if (hasRating)
                _chip(
                  leading: const Icon(
                    Icons.star,
                    size: 18,
                    color: Color(0xFF92400E),
                  ),
                  label: EventHelpers.formatRating(parsedRating),
                  border: const Color(0xFFFDE68A),
                  foreground: const Color(0xFF92400E),
                  background: const Color(0xFFFFFBEB),
                ),
            ],
          ),
          if (event.schedules != null && event.schedules!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 22,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    EventHelpers.formatDateShort(event.schedules!.first.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (hasAddress) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 22,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.fullAddress,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 18,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Biaya per event',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            EventHelpers.formatPrice(double.tryParse(event.entryPrice) ?? 0),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

}
