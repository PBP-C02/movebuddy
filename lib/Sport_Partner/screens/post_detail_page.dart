import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:Movebuddy/Sport_Partner/models/partner_post.dart';
import 'package:Movebuddy/Sport_Partner/constants.dart';
import 'package:Movebuddy/Sport_Partner/screens/edit_post_page.dart';

class PostDetailPage extends StatefulWidget {
  final PartnerPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late bool isJoined;
  late int currentParticipants;
  late PartnerPost currentPost;

  @override
  void initState() {
    super.initState();
    currentPost = widget.post;
    isJoined = widget.post.isParticipant;
    currentParticipants = widget.post.totalParticipants;
  }

  // --- Logic Functions ---
  Future<void> _toggleParticipation(CookieRequest request) async {
    // Creator dilarang keras ikut logic ini, meski tombol disembunyikan
    if (currentPost.isCreator) return;

    String urlType = isJoined ? 'leave' : 'join';
    // Gunakan try-catch untuk handle error koneksi
    try {
      final response = await request.post(
        '$baseUrl/post/${currentPost.postId}/$urlType/',
        {},
      );

      if (context.mounted) {
        if (response['success']) {
          setState(() {
            isJoined = !isJoined;
            // Update jumlah partisipan realtime dari response server
            if (response['total_participants'] != null) {
              currentParticipants = response['total_participants'];
            } else {
              // Fallback manual jika server pelit data
              currentParticipants += isJoined ? 1 : -1;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deletePost(CookieRequest request) async {
    try {
      final response = await request.post(
        '$baseUrl/post/${currentPost.postId}/delete-json/',
        {},
      );

      if (context.mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post berhasil dihapus")),
          );
          // Kembali ke halaman list dengan sinyal refresh (true)
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isCreator = currentPost.isCreator;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Activity"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // LOGIKA KRITIS: Action button HANYA muncul jika isCreator == true
          if (isCreator) ...[
            IconButton(
              tooltip: "Edit Post",
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                // Navigasi ke Edit Page
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPostPage(post: currentPost),
                  ),
                );

                // Jika edit sukses (result == true), kita tutup halaman detail ini
                // agar user kembali ke list dan data ter-refresh.
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            IconButton(
              tooltip: "Hapus Post",
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Hapus Post?"),
                  content: const Text(
                    "Tindakan ini tidak dapat dibatalkan. Post akan hilang permanen.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        deletePost(request); // Eksekusi hapus
                      },
                      child: const Text(
                        "Hapus",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tag Kategori & Info Creator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84CC16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentPost.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  isCreator ? "You (Creator)" : "By ${currentPost.creatorName}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Judul
            Text(
              currentPost.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // 3. Kotak Info Detail
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.calendar_month_rounded,
                    "Tanggal",
                    "${currentPost.tanggal.day}-${currentPost.tanggal.month}-${currentPost.tanggal.year}",
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.access_time_filled_rounded,
                    "Waktu",
                    "${currentPost.jamMulai} - ${currentPost.jamSelesai}",
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.location_on_rounded,
                    "Lokasi",
                    currentPost.lokasi,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.groups_rounded,
                    "Partisipan",
                    "$currentParticipants Orang",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Deskripsi
            const Text(
              "Deskripsi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currentPost.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),

      // LOGIKA KRITIS: BottomNavigationBar bernilai NULL jika user adalah Creator.
      // Creator TIDAK BISA melihat tombol join.
      bottomNavigationBar: !isCreator
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined
                        ? Colors.redAccent
                        : const Color(0xFF84CC16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () => _toggleParticipation(request),
                  child: Text(
                    isJoined
                        ? "BATAL GABUNG (LEAVE)"
                        : "GABUNG SEKARANG (JOIN)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFCCB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF65A30D), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          // Gunakan Expanded agar text panjang tidak overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
