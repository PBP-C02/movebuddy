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
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
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
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Court Detail",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("Edit")]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Hapus")]),
                    ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(22),
                          shadowColor: Colors.black.withOpacity(0.16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.broken_image, size: 50)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: basic.isAvailableToday ? const Color(0xFFDFF5E0) : const Color(0xFFFFE6E3),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      basic.isAvailableToday ? "Available" : "Unavailable",
                                      style: TextStyle(
                                        color: basic.isAvailableToday ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E2E2E),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Price per Hour",
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "IDR ${basic.price.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
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
                              Text(
                                basic.name,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF3FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.sports_tennis, size: 16, color: Color(0xFF5A6CEA)),
                                        const SizedBox(width: 6),
                                        Text(basic.sportType, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 18, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        basic.rating.toStringAsFixed(2),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            basic.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _infoRow(
                                      "Sport Type",
                                      basic.sportType.isEmpty ? "-" : basic.sportType,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _infoRow(
                                      "Rating",
                                      "${basic.rating.toStringAsFixed(2)} / 5",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (basic.distanceKm != null)
                                _infoRow("Distance", "${basic.distanceKm!.toStringAsFixed(1)} km"),
                              const SizedBox(height: 16),
                              const Text("Location", style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              _infoRow("Area", basic.location),
                              const SizedBox(height: 8),
                              _infoRow("Address", basic.address),
                              const SizedBox(height: 16),
                              _infoRow("Description", detail.description.isEmpty ? "Tidak ada deskripsi." : detail.description),
                              const SizedBox(height: 12),
                              const Text("Facilities", style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              if (basic.facilities.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: basic.facilities
                                      .split(',')
                                      .map((f) => f.trim())
                                      .where((f) => f.isNotEmpty)
                                      .map(
                                        (f) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF2F4F7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(f, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ),
                                      )
                                      .toList(),
                                )
                              else
                                const Text("-"),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF8FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: Color(0xFF5A6CEA)),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Court Owner", style: TextStyle(color: Colors.black54, fontSize: 12)),
                                        Text(
                                          detail.ownerName,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          detail.ownerPhone.isEmpty ? "No phone provided" : detail.ownerPhone,
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                "Owner Contact",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              _infoRow("Phone", detail.ownerPhone.isEmpty ? "Tidak tersedia" : detail.ownerPhone),
                              const SizedBox(height: 16),
                              const Text(
                                "Reserve Court",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Select Date", style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _pickDate(context),
                                            icon: const Icon(Icons.calendar_month),
                                            label: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              side: const BorderSide(color: Color(0xFF8BC34A)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: basic.isAvailableToday ? const Color(0xFFDFF5E0) : const Color(0xFFFFE6E3),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE0E3EB)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                basic.isAvailableToday ? "Tersedia" : "Tidak tersedia",
                                                style: TextStyle(
                                                  color: basic.isAvailableToday ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "Status hanya bisa diubah pemilik.",
                                                style: TextStyle(color: Colors.black54, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (detail.ownedByUser) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.edit, color: Color(0xFF5A6CEA)),
                                        label: const Text("Edit Court", style: TextStyle(color: Color(0xFF5A6CEA))),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          side: const BorderSide(color: Color(0xFF5A6CEA)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => CourtFormScreen(court: detail.basicInfo)),
                                          );
                                          if (result == true) {
                                            _refreshDetail(request);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Data berhasil diperbarui")),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        label: const Text("Delete", style: TextStyle(color: Colors.red)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _deleteCourt(request),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E2E2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (basic.isAvailableToday)
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CourtBookingScreen(courtId: widget.courtId, preSelectedDate: _selectedDate),
                                ),
                              );
                            }
                          : null,
                      child: const Text(
                        "Booking Sekarang",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
