import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Sport_Partner/models/partner_post.dart';
import 'package:move_buddy/Sport_Partner/screens/create_post_form.dart';
import 'package:move_buddy/Sport_Partner/screens/post_detail_page.dart';

class SportPartnerPage extends StatefulWidget {
  const SportPartnerPage({super.key});

  @override
  State<SportPartnerPage> createState() => _SportPartnerPageState();
}

class _SportPartnerPageState extends State<SportPartnerPage> {
  Future<List<PartnerPost>> fetchPosts(CookieRequest request) async {
    // Ganti URL sesuai endpoint JSON yang Anda buat
    final response = await request.get('http://127.0.0.1:8000/sport_partner/json/'); 
    
    // Mapping manual jika format JSON dari Django tidak persis sama dengan model
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
      appBar: AppBar(
        title: const Text('Find Your Sport Partner'),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
          if (result == true) {
            setState(() {});
          } 
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: fetchPosts(request),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (!snapshot.hasData) {
              return const Center(
                child: Text("Belum ada aktivitas olahraga."),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (_, index) {
                  PartnerPost post = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailPage(post: post),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Chip(label: Text(post.category.toUpperCase())),
                            const SizedBox(height: 8),
                            Text("Lokasi: ${post.lokasi}"),
                            Text("Jadwal: ${post.tanggal.toIso8601String().substring(0, 10)} | ${post.jamMulai} - ${post.jamSelesai}"),
                            const SizedBox(height: 8),
                            Text(
                              post.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}