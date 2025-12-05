import 'dart:async'; // Wajib untuk Timer (Debounce)
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Sport_Partner/models/partner_post.dart';
import 'package:move_buddy/Sport_Partner/screens/create_post_form.dart';
import 'package:move_buddy/Sport_Partner/screens/post_detail_page.dart';
import 'package:move_buddy/Sport_Partner/widgets/partner_card.dart';
import 'package:move_buddy/Sport_Partner/constants.dart';

class SportPartnerPage extends StatefulWidget {
  const SportPartnerPage({super.key});

  @override
  State<SportPartnerPage> createState() => _SportPartnerPageState();
}

class _SportPartnerPageState extends State<SportPartnerPage> {
  // --- STATE VARIABLES (Sama persis dengan Court List) ---
  String _searchQuery = "";
  String _selectedSport = "";
  String _sortOption = "";
  bool _onlyAvailable = false; // Misal: hanya yang slotnya masih ada
  
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Filter List (Sama persis)
  final List<Map<String, String>> _sportFilters = const [
    {"value": "", "label": "All"},
    {"value": "tennis", "label": "Tennis"},
    {"value": "basketball", "label": "Basketball"},
    {"value": "soccer", "label": "Soccer"},
    {"value": "badminton", "label": "Badminton"},
    {"value": "volleyball", "label": "Volleyball"},
    {"value": "paddle", "label": "Paddle"},
    {"value": "futsal", "label": "Futsal"},
    {"value": "table_tennis", "label": "Table Tennis"},
  ];

  // Sort Options (Disesuaikan sedikit konteksnya untuk Partner)
  final List<Map<String, String>> _sortOptions = const [
    {"value": "", "label": "Default"},
    {"value": "date_desc", "label": "Terbaru"},
    {"value": "date_asc", "label": "Terlama"},
    {"value": "slots_desc", "label": "Slot Terbanyak"},
    {"value": "name_asc", "label": "Judul A-Z"},
  ];

  late Future<List<PartnerPost>> _postsFuture;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final request = context.read<CookieRequest>();
      _refreshData(request);
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC FETCH DATA (Kritis: Menggunakan Query Params) ---
  void _refreshData(CookieRequest request) {
    setState(() {
      _postsFuture = fetchPosts(request);
    });
  }

  Future<List<PartnerPost>> fetchPosts(CookieRequest request) async {
    // Membangun Query String secara manual agar backend bisa memfilter
    // Pastikan view Django Anda menangani request.GET.get('q'), request.GET.get('sport'), dst.
    String url = '$baseUrl/sport_partner/json/?';
    
    if (_searchQuery.isNotEmpty) url += 'q=$_searchQuery&';
    if (_selectedSport.isNotEmpty) url += 'sport=$_selectedSport&';
    if (_sortOption.isNotEmpty) url += 'sort=$_sortOption&';
    
    // Logic filter client-side (opsional) atau server-side
    // Jika backend belum support filter, kita filter manual di bawah (tidak efisien tapi jalan).
    
    final response = await request.get(url);
    
    List<PartnerPost> listPosts = [];
    for (var d in response) {
      if (d != null) {
        listPosts.add(PartnerPost.fromJson(d));
      }
    }

    // FILTER CLIENT-SIDE (Jaga-jaga jika backend Anda belum siap filter)
    // Sebaiknya ini dilakukan di Backend (Django).
    if (_onlyAvailable) {
      // Asumsi PartnerPost punya field 'participants' dan 'max_participants'
      // listPosts = listPosts.where((p) => p.fields.participants.length < p.fields.maxParticipants).toList();
    }
    
    return listPosts;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        final request = context.read<CookieRequest>();
        _refreshData(request);
      }
    });
  }

  void _navigateToAddPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktivitas berhasil dibuat!")),
      );
      _refreshData(context.read<CookieRequest>());
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9), // Samakan background dengan Court
      appBar: AppBar(
        title: const Text(
          'Find Your Partner', 
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)
        ),
        backgroundColor: const Color(0xFF84CC16),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      // Floating Action Button dihapus karena sudah dipindah ke dalam Filter Card (sesuai request)
      // Jika ingin tetap ada FAB, silakan uncomment. Tapi di CourtList tombol add ada di filter.
      
      body: SafeArea(
        child: Column(
          children: [
            // --- BAGIAN 1: FILTER CARD (Sama Persis) ---
            _buildFilterCard(request),

            // --- BAGIAN 2: LIST CONTENT ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refreshData(request),
                child: FutureBuilder<List<PartnerPost>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                           SizedBox(height: 80),
                           Center(
                            child: Column(
                              children: [
                                Icon(Icons.sports_soccer, size: 60, color: Colors.grey),
                                SizedBox(height: 16),
                                Text("Tidak ada aktivitas ditemukan.", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (_, index) {
                        PartnerPost post = snapshot.data![index];
                        return PartnerCard(
                          post: post,
                          onTap: () async {
                             final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailPage(post: post),
                              ),
                            );
                            if (result == true && mounted) {
                              _refreshData(request);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET FILTER CARD (Copy-Paste Logic dari Court List) ---
  Widget _buildFilterCard(CookieRequest request) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search Bar & Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari teman main...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _refreshData(request),
                icon: const Icon(Icons.search, size: 18),
                label: const Text("Cari"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84CC16), // Sesuaikan warna tema Partner
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Row 2: Filter Chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _sportFilters.map((sport) {
              final selected = _selectedSport == sport["value"];
              return ChoiceChip(
                label: Text(sport["label"] ?? ""),
                selected: selected,
                selectedColor: const Color(0xFF84CC16).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF2E7D32) : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() => _selectedSport = sport["value"] ?? "");
                  _refreshData(request);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Row 3: Checkbox, Sort, Add Button
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _onlyAvailable = !_onlyAvailable);
                    _refreshData(request); // Refresh saat checkbox berubah
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _onlyAvailable,
                        onChanged: (val) {
                          setState(() => _onlyAvailable = val ?? false);
                          _refreshData(request);
                        },
                        activeColor: const Color(0xFF84CC16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          "Available only",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: "Urutkan",
                icon: const Icon(Icons.tune),
                onSelected: (val) {
                  setState(() => _sortOption = val);
                  _refreshData(request);
                },
                itemBuilder: (context) => _sortOptions
                    .map(
                      (opt) => PopupMenuItem(
                        value: opt["value"],
                        child: Text(opt["label"] ?? ""),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(width: 6),
              // Tombol Add dipindah ke sini agar layout konsisten dengan Court List
              ElevatedButton(
                onPressed: _navigateToAddPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84CC16),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("+ Post"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}