import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class CoachCreatePage extends StatefulWidget {
  const CoachCreatePage({super.key});

  @override
  State<CoachCreatePage> createState() => _CoachCreatePageState();
}

class _CoachCreatePageState extends State<CoachCreatePage> {
  static const String _baseUrl = String.fromEnvironment(
    'COACH_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String _createPath = String.fromEnvironment(
    'COACH_CREATE_PATH',
    defaultValue: '/coach/create-flutter/',
  );

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _instagramController = TextEditingController();
  final _mapsController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double _rating = 5.0;
  String _selectedCategory = 'badminton';
  XFile? _pickedImage;
  String? _imageBase64;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = const [
    {'label': 'Badminton', 'value': 'badminton'},
    {'label': 'Basketball', 'value': 'basketball'},
    {'label': 'Soccer', 'value': 'soccer'},
    {'label': 'Tennis', 'value': 'tennis'},
    {'label': 'Volleyball', 'value': 'volleyball'},
    {'label': 'Paddle', 'value': 'paddle'},
    {'label': 'Futsal', 'value': 'futsal'},
    {'label': 'Table Tennis', 'value': 'table_tennis'},
    {'label': 'Swimming', 'value': 'swimming'},
  ];

  final List<String> _locationOptions = const [
    '',
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Depok',
    'Tangerang',
    'Bekasi',
    'Yogyakarta',
    'Medan',
    'Bogor',
    'Denpasar',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _instagramController.dispose();
    _mapsController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 75,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = file;
        _imageBase64 = base64Encode(bytes);
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal, jam mulai, dan jam selesai wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final request = context.read<CookieRequest>();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final startStr = _formatTime(_startTime!);
    final endStr = _formatTime(_endTime!);

    final sanitizedPrice = _priceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final payload = <String, String>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'location': _locationController.text.trim(),
      'address': _addressController.text.trim(),
      'price': sanitizedPrice,
      'date': '${dateStr}T$startStr',
      'startTime': startStr,
      'endTime': endStr,
      'rating': _rating.toStringAsFixed(1),
      'instagram_link': _instagramController.text.trim(),
      'mapsLink': _mapsController.text.trim(),
    };

    if (_imageBase64 != null) {
      payload['image_base64'] = _imageBase64!;
    }

    try {
      final response = await request.postJson(
        '$_baseUrl$_createPath',
        jsonEncode(payload),
      );

      final success =
          response is Map &&
          (response['success'] == true || response['status'] == 'success');

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Coach berhasil dibuat.')));
        Navigator.pop(context, true);
      } else {
        final message =
            (response is Map ? response['message'] : null) ??
            'Gagal membuat coach, coba lagi.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? 'Pilih tanggal'
        : DateFormat('dd MMM yyyy').format(_selectedDate!);
    final startLabel = _startTime == null
        ? 'Jam mulai'
        : _formatTime(_startTime!);
    final endLabel = _endTime == null ? 'Jam selesai' : _formatTime(_endTime!);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Coach')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _locationController.text.isEmpty
                  ? ''
                  : _locationController.text,
              decoration: const InputDecoration(
                labelText: 'Kota',
                border: OutlineInputBorder(),
              ),
              items: _locationOptions
                  .map(
                    (loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc.isEmpty ? 'Pilih lokasi' : loc),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _locationController.text = value ?? '');
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat lengkap',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga per sesi',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                return int.tryParse(
                          v.replaceAll('.', '').replaceAll(',', ''),
                        ) ==
                        null
                    ? 'Masukkan angka'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(isStart: true),
                    icon: const Icon(Icons.access_time),
                    label: Text(startLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(isStart: false),
                    icon: const Icon(Icons.access_time_filled),
                    label: Text(endLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Rating awal'),
                    const SizedBox(width: 8),
                    Text(_rating.toStringAsFixed(1)),
                  ],
                ),
                Slider(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                  divisions: 10,
                  min: 0,
                  max: 5,
                  label: _rating.toStringAsFixed(1),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram (opsional)',
                hintText: 'https://instagram.com/username',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mapsController,
              decoration: const InputDecoration(
                labelText: 'Link Google Maps (opsional)',
                hintText: 'https://maps.google.com/...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                _pickedImage == null
                    ? 'Pilih gambar (opsional)'
                    : 'Ganti gambar',
              ),
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb && _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_pickedImage!.path),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84CC16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Simpan Coach',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
