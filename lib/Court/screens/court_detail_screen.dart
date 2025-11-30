import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import '../models/court_models.dart';
import '../helpers/court_api_helper.dart';
import 'court_booking_screen.dart';
import 'court_form_screen.dart';

class CourtDetailScreen extends StatefulWidget {
  final int courtId;

  const CourtDetailScreen({Key? key, required this.courtId}) : super(key: key);

  @override
  _CourtDetailScreenState createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends State<CourtDetailScreen> {
  late Future<CourtDetail> _detailFuture;
  
  // State Cek Jadwal
  DateTime _selectedDate = DateTime.now();
  bool? _isDateAvailable;
  bool _checkingSchedule = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final request = context.read<CookieRequest>();
      _refreshDetail(request);
      _isInit = false;
    }
  }

  void _refreshDetail(CookieRequest request) {
    setState(() {
      _detailFuture = CourtApiHelper(request).fetchCourtDetail(widget.courtId);
    });
    // Reset status jadwal & Cek default hari ini
    setState(() {
       _isDateAvailable = null;
    });
    _checkAvailability(request); 
  }

  // Cek ketersediaan tanggal
  Future<void> _checkAvailability(CookieRequest request) async {
    if (!mounted) return;
    
    setState(() => _checkingSchedule = true);
    String formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}";
    
    try {
      bool available = await CourtApiHelper(request).checkAvailability(widget.courtId, formattedDate);
      if (mounted) {
        setState(() => _isDateAvailable = available);
        if (!available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tanggal ini sudah dibooking, pilih tanggal lain.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal cek jadwal")));
      }
    } finally {
      if (mounted) {
        setState(() => _checkingSchedule = false);
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final request = context.read<CookieRequest>();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isDateAvailable = null;
      });
      _checkAvailability(request);
    }
  }

  Future<void> _deleteCourt(CookieRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Lapangan?"),
        content: const Text("Data yang dihapus tidak dapat dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CourtApiHelper(request).deleteCourt(widget.courtId);
        if (mounted) {
          Navigator.pop(context); // Keluar dari detail
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lapangan dihapus")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Lapangan"),
        actions: [
          // FutureBuilder untuk akses edit/delete
          FutureBuilder<CourtDetail>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.ownedByUser) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourtFormScreen(court: snapshot.data!.basicInfo),
                        ),
                      );
                      if (result == true) {
                        _refreshDetail(request);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil diperbarui")));
                        }
                      }
                    } else if (value == 'delete') {
                      _deleteCourt(request);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("Edit")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Hapus")])),
                  ],
                );
              }
              return const SizedBox();
            },
          )
        ],
      ),
      body: FutureBuilder<CourtDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
             return const Center(child: Text("Data tidak ditemukan"));
          }

          final detail = snapshot.data!;
          final basic = detail.basicInfo;
          final imageUrl = CourtApiHelper.resolveImageUrl(
            basic.imageUrl,
            placeholder: "https://via.placeholder.com/400x200",
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Image ---
                      Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 250, 
                          width: double.infinity,
                          color: Colors.grey[300], 
                          child: const Icon(Icons.broken_image, size: 50)
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Judul & Harga ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(basic.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                                  child: Text("Rp ${basic.price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // --- Lokasi & Rating ---
                            Row(children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text("${basic.location} - ${basic.address}", style: const TextStyle(color: Colors.grey))),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text("${basic.rating} / 5.0", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ]),
                            const Divider(height: 30),

                            // --- Fasilitas ---
                            const Text("Fasilitas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(basic.facilities.isEmpty ? "-" : basic.facilities),
                            const SizedBox(height: 16),

                            // --- Deskripsi ---
                            const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(detail.description.isEmpty ? "Tidak ada deskripsi." : detail.description),
                            const SizedBox(height: 16),

                            // --- Owner Info ---
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                              child: Row(children: [
                                const Icon(Icons.person, color: Colors.blue),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text("Pemilik:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(detail.ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ]),
                              ]),
                            ),
                            const Divider(height: 40),

                            // --- Booking Section ---
                            const Text("Cek Ketersediaan & Booking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _pickDate(context),
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
                                ),
                                const SizedBox(width: 16),
                                if (_checkingSchedule)
                                  const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _isDateAvailable == true ? Colors.green : (_isDateAvailable == false ? Colors.red : Colors.grey),
                                      borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: Text(
                                      _isDateAvailable == true ? "Tersedia" : (_isDateAvailable == false ? "Penuh" : "Cek Jadwal"),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- Bottom Button ---
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  onPressed: (_isDateAvailable == true) 
                      ? () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => CourtBookingScreen(courtId: widget.courtId, preSelectedDate: _selectedDate))
                          );
                        }
                      : null, 
                  child: const Text("Booking Sekarang", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
