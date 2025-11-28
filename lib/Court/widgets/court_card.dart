import 'package:flutter/material.dart';
import '../models/court_models.dart';
import '../helpers/court_api_helper.dart'; // Untuk akses baseUrl

class CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;

  const CourtCard({Key? key, required this.court, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle image URL absolute
    String imageUrl = court.imageUrl != null 
        ? "${CourtApiHelper.baseUrl}${court.imageUrl}" 
        : "https://via.placeholder.com/150";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Court
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {}, // Silent error
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sports_tennis, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(court.sportType.toUpperCase()),
                      const Spacer(),
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(court.rating.toString()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Rp ${court.price}/jam", style: const TextStyle(color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(
                    court.location, 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}