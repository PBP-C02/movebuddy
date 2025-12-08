import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/court_models.dart';
import '../helpers/court_api_helper.dart';
import '../widgets/court_card.dart';
import 'court_detail_screen.dart';
import 'court_form_screen.dart';

class CourtListScreen extends StatefulWidget {
  const CourtListScreen({super.key});

  @override
  State<CourtListScreen> createState() => _CourtListScreenState();
}

class _CourtListScreenState extends State<CourtListScreen> {
  // State Filter & Search
  String _searchQuery = "";
  String _selectedSport = "";
  String _sortOption = "";
  bool _onlyAvailable = false;
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final double _minRating = 0;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  Timer? _debounce;
  
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
  final List<Map<String, String>> _sortOptions = const [
    {"value": "", "label": "Default"},
    {"value": "price_asc", "label": "Harga Termurah"},
    {"value": "price_desc", "label": "Harga Termahal"},
    {"value": "rating_desc", "label": "Rating Tertinggi"},
    {"value": "name_asc", "label": "Nama A-Z"},
    {"value": "name_desc", "label": "Nama Z-A"},
    {"value": "distance", "label": "Terdekat (butuh lat/lng)"},
  ];

  late Future<List<Court>> _courtsFuture;
  bool _isInit = true; // Flag untuk inisialisasi pertama kali

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Ambil request sekali saat widget pertama kali dimuat
      final request = context.read<CookieRequest>();
      _refreshData(request);
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _refreshData(CookieRequest request) {
    setState(() {
      _courtsFuture = CourtApiHelper(request).fetchCourts(
        query: _searchQuery,
        sport: _selectedSport,
        sort: _sortOption,
        minPrice: _minPriceController.text.trim(),
        maxPrice: _maxPriceController.text.trim(),
        minRating: _minRating > 0 ? _minRating.toString() : "",
        latitude: _latController.text.trim(),
        longitude: _lngController.text.trim(),
      );
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        // Ambil request terbaru dari context saat search dieksekusi
        final request = context.read<CookieRequest>();
        _refreshData(request);
      }
    });
  }

  void _navigateToAddCourt() async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CourtFormScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lapangan berhasil ditambahkan!")),
      );
      _refreshData(context.read<CookieRequest>());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita tetap watch request untuk jaga-jaga jika status auth berubah
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Courts",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterCard(request),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _refreshData(request),
                child: FutureBuilder<List<Court>>(
                  future: _courtsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  "Terjadi kesalahan: ${snapshot.error}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _refreshData(request),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E2E2E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Coba Lagi"),
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text("Tidak ada lapangan ditemukan.")),
                        ],
                      );
                    }

                    var courts = snapshot.data!;
                    if (_onlyAvailable) {
                      courts = courts.where((c) => c.isAvailableToday).toList();
                    }

                    if (courts.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 80),
                          Center(child: Text("Tidak ada lapangan sesuai filter.")),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: courts.length,
                      itemBuilder: (context, index) {
                        return CourtCard(
                          court: courts[index],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourtDetailScreen(courtId: courts[index].id),
                              ),
                            );
                            if (mounted) _refreshData(request);
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

  Widget _buildFilterCard(CookieRequest request) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search courts or locations...",
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
                label: const Text("Search"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _sportFilters.map((sport) {
              final selected = _selectedSport == sport["value"];
              return ChoiceChip(
                label: Text(sport["label"] ?? ""),
                selected: selected,
                selectedColor: const Color(0xFF8BC34A).withValues(alpha: 0.2),
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
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _onlyAvailable = !_onlyAvailable);
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _onlyAvailable,
                        onChanged: (val) {
                          setState(() => _onlyAvailable = val ?? false);
                        },
                        activeColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Show only available courts",
                        style: TextStyle(fontWeight: FontWeight.w600),
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
              ElevatedButton(
                onPressed: _navigateToAddCourt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("+ Add Court"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
