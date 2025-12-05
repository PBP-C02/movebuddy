import 'package:flutter/material.dart';
import 'package:move_buddy/Coach/models/coach_entry.dart';

class CoachEntryCard extends StatelessWidget {
  final Coach coach;
  final VoidCallback? onTap;

  const CoachEntryCard({super.key, required this.coach, this.onTap});

  String _formatPrice(int price) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return price.toString().replaceAllMapped(
      formatter,
      (match) => '${match[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = !coach.isBooked;
    final statusColor =
        isAvailable ? const Color(0xFFDFF5E0) : const Color(0xFFFFE6E3);
    final statusTextColor =
        isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(22),
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: _CoachHeaderImage(imageUrl: coach.imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            isAvailable ? 'Tersedia' : 'Sudah dibooking',
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 18, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              coach.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      coach.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            coach.userName,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPill(
                          icon: Icons.sports_handball,
                          label: coach.category,
                          color: const Color(0xFF8BC34A),
                        ),
                        _buildPill(
                          icon: Icons.place,
                          label: coach.location,
                          color: const Color(0xFF607D8B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.calendar_month,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatDate(coach.date)} | ${coach.startTime} - ${coach.endTime}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            coach.address,
                            style: TextStyle(color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biaya per sesi',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rp ${_formatPrice(coach.price)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E2E2E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Lihat Detail',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachHeaderImage extends StatelessWidget {
  final String? imageUrl;

  const _CoachHeaderImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = Image.network(
        imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text('Belum ada foto', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
