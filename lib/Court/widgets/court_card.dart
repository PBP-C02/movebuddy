import 'package:flutter/material.dart';
import '../models/court_models.dart';
import '../helpers/court_api_helper.dart'; // Untuk akses baseUrl

class CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;

  const CourtCard({super.key, required this.court, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = CourtApiHelper.resolveImageUrl(
      court.imageUrl,
      placeholder: "https://via.placeholder.com/150",
    );

    final distanceText =
        court.distanceKm != null ? "${court.distanceKm!.toStringAsFixed(1)} km" : "Tidak diketahui";
    final statusColor = court.isAvailableToday ? const Color(0xFFDFF5E0) : const Color(0xFFFFE6E3);
    final statusTextColor = court.isAvailableToday ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(22),
        shadowColor: Colors.black.withValues(alpha: 0.08),
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
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 40)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        court.isAvailableToday ? "Tersedia" : "Penuh",
                        style: TextStyle(
                          color: statusTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      court.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.sports_tennis, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          court.sportType,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(court.rating.toStringAsFixed(2)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      court.location,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Jarak: $distanceText",
                      style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Rp ${court.price.toStringAsFixed(0)} /jam",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2E2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onTap,
                        child: const Text(
                          "Lihat Detail & Booking",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
    );
  }
}
