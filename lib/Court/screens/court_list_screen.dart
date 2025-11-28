import 'package:flutter/material.dart';
import '../models/court_models.dart';
import '../helpers/court_api_helper.dart';
import '../widgets/court_card.dart'; // Pastikan widget ini ada (dari jawaban sebelumnya)
import 'court_detail_screen.dart';
import 'court_form_screen.dart';

class CourtListScreen extends StatefulWidget {
  const CourtListScreen({Key? key}) : super(key: key);

  @override
  _CourtListScreenState createState() => _CourtListScreenState();
}

class _CourtListScreenState extends State<CourtListScreen> {
  final CourtApiHelper _api = CourtApiHelper();
  
  // State Filter & Search
  String _searchQuery = "";
  String _selectedSport = "";
  
  final List<String> _sportTypes = [
    '', 'tennis', 'basketball', 'soccer', 'badminton', 
    'volleyball', 'paddle', 'futsal', 'table_tennis'
  ];

  // Future untuk fetch data
  late Future<List<Court>> _courtsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _courtsFuture = _fetchData();
    });
  }

  Future<List<Court>> _fetchData() async {
    final List<dynamic> rawData = await _api.fetchCourts(
      query: _searchQuery,
      sport: _selectedSport,
    );
    return rawData.map((json) => Court.fromJson(json)).toList();
  }

  void _navigateToAddCourt() async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CourtFormScreen()),
    );
    // Jika result true (berhasil add), refresh list
    if (result == true) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lapangan berhasil ditambahkan!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Lapangan")),
      
      // Floating Action Button untuk Add Court
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
                  onChanged: (val) {
                    _searchQuery = val;
                    _refreshData(); // Live search
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text("Filter: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _selectedSport,
                        underline: Container(), // Hapus garis bawah default
                        items: _sportTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.isEmpty ? "Semua Olahraga" : value),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            _selectedSport = newVal;
                            _refreshData();
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
                  return Center(child: Text("Gagal memuat: ${snapshot.error}"));
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
                        // Navigasi ke Detail
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourtDetailScreen(courtId: courts[index].id),
                          ),
                        );
                        // Refresh saat kembali (siapa tahu ada perubahan)
                        _refreshData();
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