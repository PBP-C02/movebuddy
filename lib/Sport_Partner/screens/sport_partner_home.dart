import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Sport_Partner/models/partner_post.dart';
import 'package:move_buddy/Sport_Partner/screens/create_post_form.dart';
import 'package:move_buddy/Sport_Partner/screens/post_detail_page.dart';
import 'package:move_buddy/Sport_Partner/widgets/partner_card.dart'; // Import Widget Baru
import 'package:move_buddy/Sport_Partner/constants.dart'; // Pastikan constants ada untuk baseUrl

class SportPartnerPage extends StatefulWidget {
  const SportPartnerPage({super.key});

  @override
  State<SportPartnerPage> createState() => _SportPartnerPageState();
}

class _SportPartnerPageState extends State<SportPartnerPage> {
  
  Future<List<PartnerPost>> fetchPosts(CookieRequest request) async {
    // Gunakan baseUrl dari constants.dart jika ada, atau hardcode untuk testing
    final response = await request.get('$baseUrl/sport_partner/json/'); 
    
    List<PartnerPost> listPosts = [];
    for (var d in response) {
      if (d != null) {
        listPosts.add(PartnerPost.fromJson(d));
      }
    }
    return listPosts;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      // App Bar transparan agar background terlihat jika diinginkan, atau solid lime
      appBar: AppBar(
        title: const Text(
          'Find Your Partner', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: const Color(0xFF84CC16), // Lime Color
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF84CC16),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          // LAYER 1: Background Image Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[100], // Placeholder warna background
            // Nanti kalau mau pakai gambar, uncomment ini:
            /*
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_pattern.png'),
                fit: BoxFit.cover,
                opacity: 0.1, 
              ),
            ),
            */
          ),

          // LAYER 2: List Content
          FutureBuilder(
            future: fetchPosts(request),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Belum ada aktivitas olahraga.\nBuat sekarang!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 80), // Padding bawah biar ga ketutup FAB
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, index) {
                      PartnerPost post = snapshot.data![index];
                      // Panggil Widget Card yang sudah kita buat
                      return PartnerCard(
                        post: post,
                        onTap: () async {
                           final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(post: post),
                            ),
                          );
                          // Jika kembali dari detail (misal habis delete), refresh list
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}