import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Sport_Partner/models/partner_post.dart';

class PostDetailPage extends StatefulWidget {
  final PartnerPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  // Analogi: Seperti tombol saklar lampu, kita butuh state untuk tahu nyala/mati
  late bool isJoined;
  late int currentParticipants;

  @override
  void initState() {
    super.initState();
    isJoined = widget.post.isParticipant;
    currentParticipants = widget.post.totalParticipants;
  }

  Future<void> toggleParticipation(CookieRequest request) async {
    // Tentukan endpoint join atau leave
    String urlType = isJoined ? 'leave' : 'join';
    final response = await request.post(
      'http://127.0.0.1:8000/sport_partner/post/${widget.post.postId}/$urlType/',
      {},
    );

    if (response['success']) {
      setState(() {
        isJoined = !isJoined;
        currentParticipants = response['total_participants'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.post.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Kategori: ${widget.post.category}"),
            Text("Creator: ${widget.post.creatorName}"),
            const Divider(),
            Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.post.description),
            const SizedBox(height: 20),
            Text("Detail Waktu & Tempat:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Tanggal: ${widget.post.tanggal.toIso8601String().substring(0, 10)}"),
            Text("Jam: ${widget.post.jamMulai} - ${widget.post.jamSelesai}"),
            Text("Lokasi: ${widget.post.lokasi}"),
            const SizedBox(height: 20),
            Text("Partisipan: $currentParticipants orang"),
            const Spacer(),
            
            // Tombol Join/Leave
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => toggleParticipation(request),
                child: Text(
                  isJoined ? "LEAVE ACTIVITY" : "JOIN NOW",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}