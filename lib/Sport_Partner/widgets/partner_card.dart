import 'package:flutter/material.dart';
import 'package:move_buddy/Sport_Partner/models/partner_post.dart';

class PartnerCard extends StatelessWidget {
  final PartnerPost post;
  final VoidCallback onTap;

  const PartnerCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Chip & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84CC16), // Lime Color
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info: Date & Time
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "${post.tanggal.year}-${post.tanggal.month}-${post.tanggal.day}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "${post.jamMulai} - ${post.jamSelesai}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info: Location
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.lokasi,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description Snippet
              Text(
                post.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
              
              const SizedBox(height: 12),
              
              // Footer: Participants Count
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF84CC16)),
                  const SizedBox(width: 4),
                  Text(
                    "${post.totalParticipants} orang bergabung",
                    style: const TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84CC16),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}