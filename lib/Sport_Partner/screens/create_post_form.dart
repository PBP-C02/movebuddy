import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Sport_Partner/constants.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();

  // Variabel untuk menampung isian user (seperti tinta di kertas formulir)
  String _title = "";
  String _description = "";
  String _category = "soccer"; // Default category
  String _lokasi = "";
  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  // Pilihan kategori sesuai models.py Django
  final List<String> _categories = [
    'tennis', 'basketball', 'soccer', 'badminton', 'volleyball',
    'paddle', 'futsal', 'table_tennis', 'jogging'
  ];

  // Helper function untuk format jam (HH:MM) agar sesuai selera Django
  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Aktivitas Baru'),
        backgroundColor: const Color(0xFF84CC16), // Sesuaikan warna tema Anda
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. JUDUL
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Judul Aktivitas",
                  hintText: "Contoh: Main Futsal Bareng",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (String? value) => setState(() => _title = value!),
                validator: (String? value) {
                  if (value == null || value.isEmpty) return "Judul tidak boleh kosong!";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. DESKRIPSI
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Deskripsi",
                  hintText: "Jelaskan detail aktivitas...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
                onChanged: (String? value) => setState(() => _description = value!),
                validator: (String? value) {
                  if (value == null || value.isEmpty) return "Deskripsi tidak boleh kosong!";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. KATEGORI (Dropdown)
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: "Kategori Olahraga",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _categories.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item[0].toUpperCase() + item.substring(1)), // Capitalize
                  );
                }).toList(),
                onChanged: (String? newValue) => setState(() => _category = newValue!),
              ),
              const SizedBox(height: 16),

              // 4. LOKASI
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Lokasi",
                  hintText: "Contoh: GOR Senayan",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (String? value) => setState(() => _lokasi = value!),
                validator: (String? value) {
                  if (value == null || value.isEmpty) return "Lokasi tidak boleh kosong!";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. TANGGAL & WAKTU
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null
                          ? "Pilih Tanggal"
                          : "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}"),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_jamMulai == null ? "Jam Mulai" : formatTime(_jamMulai!)),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _jamMulai = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_filled),
                      label: Text(_jamSelesai == null ? "Jam Selesai" : formatTime(_jamSelesai!)),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _jamSelesai = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Validasi tambahan untuk Tanggal dan Jam
                      if (_selectedDate == null || _jamMulai == null || _jamSelesai == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lengkapi tanggal dan waktu!")),
                        );
                        return;
                      }

                      // Kirim data ke Django (Paket dikirim kurir)
                      // GANTI URL INI DENGAN URL DEPLOY ATAU LOCALHOST ANDA
                      // Jangan lupa / di akhir URL jika di urls.py Anda pakai slash
                      final response = await request.postJson(
                        "$baseUrl/create-post/",
                        jsonEncode(<String, String>{
                          'title': _title,
                          'description': _description,
                          'category': _category,
                          'lokasi': _lokasi,
                          // Format tanggal YYYY-MM-DD sesuai strptime python
                          'tanggal': "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                          // Format jam HH:MM
                          'jam_mulai': formatTime(_jamMulai!),
                          'jam_selesai': formatTime(_jamSelesai!),
                        }),
                      );

                      // Cek balasan dari server
                      if (context.mounted) {
                        if (response['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Post berhasil dibuat!")),
                          );
                          Navigator.pop(context, true); // Kembali ke halaman list
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response['message'] ?? "Gagal menyimpan data."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    "BUAT POST",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}