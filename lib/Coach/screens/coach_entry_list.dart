import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:move_buddy/Coach/models/coach_entry.dart';
import 'package:move_buddy/Coach/widgets/coach_entry_card.dart';

class CoachEntryListPage extends StatefulWidget {
  const CoachEntryListPage({super.key});

  @override
  State<CoachEntryListPage> createState() => _CoachEntryListPageState();
}

class _CoachEntryListPageState extends State<CoachEntryListPage> {
  bool showOnlyAvailable = false;
  late Future<List<Coach>> _coachFuture;

  @override
  void initState() {
    super.initState();
    _coachFuture = _fetchCoaches();
  }

  Future<List<Coach>> _fetchCoaches() async {
    // Ubah URL ini sesuai endpoint Django kalian.
    final url = Uri.parse('http://localhost:8000/coach/json/');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data coach (${response.statusCode})');
    }

    return coachFromJson(utf8.decode(response.bodyBytes));
  }

  Future<void> _refresh() async {
    setState(() {
      _coachFuture = _fetchCoaches();
    });
    await _coachFuture;
  }

  void _showCoachDetail(Coach coach) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  coach.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  coach.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kontak & Link',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (coach.instagramLink.isNotEmpty)
                  _InfoRow(
                    icon: Icons.link,
                    label: 'Instagram',
                    value: coach.instagramLink,
                  ),
                if (coach.mapsLink.isNotEmpty)
                  _InfoRow(
                    icon: Icons.map_outlined,
                    label: 'Lokasi',
                    value: coach.mapsLink,
                  ),
                if (coach.instagramLink.isEmpty && coach.mapsLink.isEmpty)
                  Text(
                    'Belum ada link tambahan.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Coach',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  showOnlyAvailable
                      ? 'Hanya menampilkan yang tersedia'
                      : 'Semua jadwal coach',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
            Switch(
              value: showOnlyAvailable,
              activeColor: Colors.green,
              onChanged: (value) {
                setState(() {
                  showOnlyAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Coach'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Coach>>(
          future: _coachFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildFilterBar(),
                  const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildFilterBar(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 42,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat data coach.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Periksa koneksi atau URL endpoint, lalu coba lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final coaches = snapshot.data ?? [];
            final filtered = showOnlyAvailable
                ? coaches.where((coach) => !coach.isBooked).toList()
                : coaches;

            if (filtered.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildFilterBar(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 42,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada coach yang bisa ditampilkan.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba nonaktifkan filter atau tarik untuk refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterBar();
                }
                final coach = filtered[index - 1];
                return CoachEntryCard(
                  coach: coach,
                  onTap: () => _showCoachDetail(coach),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
