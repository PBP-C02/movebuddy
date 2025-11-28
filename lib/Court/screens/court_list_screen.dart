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
  Timer? _debounce;
  
  final List<String> _sportTypes = [
    '', 'tennis', 'basketball', 'soccer', 'badminton', 
    'volleyball', 'paddle', 'futsal', 'table_tennis'
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
    super.dispose();
  }

  void _refreshData(CookieRequest request) {
    setState(() {
      _courtsFuture = CourtApiHelper(request).fetchCourts(
        query: _searchQuery,
        sport: _selectedSport,
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