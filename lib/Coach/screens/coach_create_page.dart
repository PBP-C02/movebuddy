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
    defaultValue: 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/coach/',
  );
  static const String _createPath = String.fromEnvironment(
    'COACH_CREATE_PATH',
    defaultValue: 'create-flutter/',
  );

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _instagramController = TextEditingController();
  final _mapsController = TextEditingController();
  final _ratingController = TextEditingController(text: '5.0');

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
    _ratingController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final hasScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final withScheme = hasScheme ? trimmed : 'https://$trimmed';
    final encoded = withScheme.replaceAll(' ', '%20');
    final uri = Uri.tryParse(encoded);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return '';
    }
    return uri.toString();
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

    final mapsLink = _normalizeUrl(_mapsController.text);
    if (mapsLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link Google Maps wajib diisi.'),
        ),
      );
      return;
    }

    final ratingValue = double.tryParse(_ratingController.text.trim());
    if (ratingValue == null || ratingValue < 0 || ratingValue > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating harus angka 0-5.'),
        ),
      );
      return;
    }

    _rating = ratingValue;
    setState(() => _isSubmitting = true);
    final request = context.read<CookieRequest>();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final startStr = _formatTime(_startTime!);
    final endStr = _formatTime(_endTime!);

    final sanitizedPrice = _priceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final instagramLink = _normalizeUrl(_instagramController.text);

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
      'instagram_link': instagramLink,
      'mapsLink': mapsLink,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Tambah Coach',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
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
                child: Form(
                  key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lengkapi detail coach',
                          style:
                              TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        _buildSectionTitle('Informasi Coach'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          decoration: _filledDecoration('Judul'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _filledDecoration('Deskripsi'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: _filledDecoration('Kategori'),
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
                        const SizedBox(height: 18),
                        _buildSectionTitle('Lokasi'),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _locationController.text.isEmpty
                              ? ''
                              : _locationController.text,
                          decoration: _filledDecoration('Kota'),
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
                          decoration: _filledDecoration('Alamat lengkap'),
                          maxLines: 2,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mapsController,
                          decoration: _filledDecoration(
                            'Link Google Maps',
                            hint: 'https://maps.google.com/...',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Jadwal & Harga'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _priceController,
                          decoration: _filledDecoration(
                            'Harga per sesi',
                            prefix: 'Rp ',
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectDate,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF7F8FA),
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
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
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF7F8FA),
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.access_time),
                                label: Text(startLabel),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectTime(isStart: false),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF7F8FA),
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.access_time_filled),
                                label: Text(endLabel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Rating & Kontak'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ratingController,
                          decoration: _filledDecoration(
                            'Rating (0-5)',
                            hint: 'contoh: 4.5',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed < 0 || parsed > 5) {
                              return 'Masukkan angka 0-5';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _instagramController,
                          decoration: _filledDecoration(
                            'Instagram (opsional)',
                            hint: 'https://instagram.com/username',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Foto Coach'),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.image_outlined, size: 22),
                            label: Text(
                              _pickedImage == null
                                  ? 'Pilih gambar (opsional)'
                                  : 'Ganti gambar',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            color: const Color(0xFFF5F5F5),
                            child: _pickedImage != null
                                ? (kIsWeb && _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.image_outlined,
                                          size: 42, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Belum ada gambar',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7DC81),
                            foregroundColor: const Color(0xFF182435),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF182435),
                                  ),
                                )
                              : const Text(
                                  'Simpan Coach',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
      );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _filledDecoration(String label,
      {String? hint, String? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
    );
  }
}
