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
  const CourtListScreen({Key? key}) : super(key: key);

  @override
  _CourtListScreenState createState() => _CourtListScreenState();
}

class _CourtListScreenState extends State<CourtListScreen> {
  // State Filter & Search
  String _searchQuery = "";
  String _selectedSport = "";
  String _sortOption = "";
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  double _minRating = 0;
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  Timer? _debounce;
  
  final List<String> _sportTypes = [
    '', 'tennis', 'basketball', 'soccer', 'badminton', 
    'volleyball', 'paddle', 'futsal', 'table_tennis'
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
      appBar: AppBar(title: const Text("Daftar Lapangan")),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCourt,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Column(
        children: [
          // --- Filter & Search Bar ---
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Cari nama atau lokasi...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text("Filter: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _selectedSport,
                        underline: Container(), 
                        items: _sportTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.isEmpty ? "Semua Olahraga" : value),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null && newVal != _selectedSport) {
                            setState(() {
                              _selectedSport = newVal;
                            });
                            _refreshData(request);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                            labelText: "Min Harga",
                            prefixText: "Rp ",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _refreshData(request),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _maxPriceController,
                          decoration: const InputDecoration(
                            labelText: "Max Harga",
                            prefixText: "Rp ",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _refreshData(request),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _latController,
                          decoration: const InputDecoration(
                            labelText: "Lat",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          onSubmitted: (_) => _refreshData(request),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _lngController,
                          decoration: const InputDecoration(
                            labelText: "Lng",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          onSubmitted: (_) => _refreshData(request),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Text("Min Rating"),
                          Slider(
                            value: _minRating,
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: _minRating.toStringAsFixed(0),
                            onChanged: (val) {
                              setState(() => _minRating = val);
                            },
                            onChangeEnd: (_) => _refreshData(request),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sortOption,
                        underline: Container(),
                        items: _sortOptions
                            .map((opt) => DropdownMenuItem<String>(
                                  value: opt["value"],
                                  child: Text(opt["label"] ?? ""),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _sortOption = val);
                          _refreshData(request);
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          _minPriceController.clear();
                          _maxPriceController.clear();
                          _latController.clear();
                          _lngController.clear();
                          _minRating = 0;
                          _sortOption = "";
                          _selectedSport = "";
                          _searchQuery = "";
                          _refreshData(request);
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: "Reset filter",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- List Content ---
          Expanded(
            child: FutureBuilder<List<Court>>(
              future: _courtsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        Text("Terjadi kesalahan: ${snapshot.error}", textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _refreshData(request),
                          child: const Text("Coba Lagi"),
                        )
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada lapangan ditemukan."));
                }

                final courts = snapshot.data!;
                return ListView.builder(
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
                        // Refresh data saat kembali dari detail
                        if (mounted) _refreshData(request);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
