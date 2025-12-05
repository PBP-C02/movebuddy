import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Sport_Partner/models/partner_post.dart';
import 'package:move_buddy/Sport_Partner/constants.dart'; // Pastikan constants ada

class EditPostPage extends StatefulWidget {
  final PartnerPost post;
  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();
  
  late String _title;
  late String _description;
  late String _category;
  late String _lokasi;
  late DateTime _selectedDate;
  late TimeOfDay _jamMulai;
  late TimeOfDay _jamSelesai;

  final List<String> _categories = [
    'tennis', 'basketball', 'soccer', 'badminton', 'volleyball',
    'paddle', 'futsal', 'table_tennis', 'jogging'
  ];

  @override
  void initState() {
    super.initState();
    // PRE-FILL DATA DARI POST YANG ADA
    _title = widget.post.title;
    _description = widget.post.description;
    _category = widget.post.category;
    _lokasi = widget.post.lokasi;
    _selectedDate = widget.post.tanggal;
    
    // Konversi String jam ("14:00") ke TimeOfDay
    _jamMulai = _parseTime(widget.post.jamMulai);
    _jamSelesai = _parseTime(widget.post.jamSelesai);
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

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
        title: const Text('Edit Activity'),
        backgroundColor: const Color(0xFF84CC16),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: "Judul",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => _title = val,
                validator: (val) => val!.isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _description,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Deskripsi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => _description = val,
                validator: (val) => val!.isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_category) ? _category : _categories.first,
                decoration: InputDecoration(labelText: "Kategori", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: _categories.map((item) => DropdownMenuItem(value: item, child: Text(item.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _lokasi,
                decoration: InputDecoration(
                  labelText: "Lokasi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => _lokasi = val,
                validator: (val) => val!.isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 20),

              // Date & Time Pickers (Sederhana)
              ListTile(
                title: Text("Tanggal: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                   final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                   if(picked != null) setState(() => _selectedDate = picked);
                },
              ),
               ListTile(
                title: Text("Jam: ${formatTime(_jamMulai)} - ${formatTime(_jamSelesai)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                   // Implementasi simple time picker, logic sama kayak create
                   final pickedStart = await showTimePicker(context: context, initialTime: _jamMulai);
                   if (pickedStart != null) {
                      setState(() => _jamMulai = pickedStart);
                      // ignore: use_build_context_synchronously
                      final pickedEnd = await showTimePicker(context: context, initialTime: _jamSelesai);
                      if (pickedEnd != null) setState(() => _jamSelesai = pickedEnd);
                   }
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16), padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final response = await request.postJson(
                        "$baseUrl/sport_partner/post/${widget.post.postId}/edit-json/",
                        jsonEncode({
                          'title': _title,
                          'description': _description,
                          'category': _category,
                          'lokasi': _lokasi,
                          'tanggal': "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}",
                          'jam_mulai': formatTime(_jamMulai),
                          'jam_selesai': formatTime(_jamSelesai),
                        }),
                      );

                      if (context.mounted) {
                        if (response['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post updated!")));
                          Navigator.pop(context, true); // Return true agar detail refresh
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
                        }
                      }
                    }
                  },
                  child: const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}