import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/court_models.dart';
import '../helpers/court_api_helper.dart';

class CourtFormScreen extends StatefulWidget {
  final Court? court; // Jika null = Add Mode, Jika ada = Edit Mode

  const CourtFormScreen({Key? key, this.court}) : super(key: key);

  @override
  _CourtFormScreenState createState() => _CourtFormScreenState();
}

class _CourtFormScreenState extends State<CourtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final Map<String, String> _sportLabels = const {
    'tennis': 'Tennis',
    'basketball': 'Basketball',
    'soccer': 'Soccer',
    'badminton': 'Badminton',
    'volleyball': 'Volleyball',
    'paddle': 'Paddle',
    'futsal': 'Futsal',
    'table_tennis': 'Table Tennis',
  };
  String? _selectedSportType;

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController(); // e.g. "Jakarta Selatan"
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi form dengan data lama
    if (widget.court != null) {
      final c = widget.court!;
      _nameController.text = c.name;
      _selectedSportType = c.sportType;
      _locationController.text = c.location;
      _addressController.text = c.address;
      _priceController.text = c.price.toInt().toString();
      _phoneController.text = ""; // Note: BasicInfo Court mungkin tidak menyimpan phone, sesuaikan jika ada
      _facilitiesController.text = c.facilities;
      // Description ada di Detail, bukan BasicInfo. 
      // Jika model Court kamu punya desc, masukkan di sini.
    } else {
      _selectedSportType = _sportLabels.keys.first;
    }

    // Fallback jika value dari backend tidak ada di daftar pilihan
    if (_selectedSportType != null && !_sportLabels.containsKey(_selectedSportType)) {
      _selectedSportType = _sportLabels.keys.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _facilitiesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _sanitizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Ambil CookieRequest dari Provider
    final request = context.read<CookieRequest>();
    
    // 2. Siapkan data fields
    // Sesuaikan key map ini dengan yang diminta Django views.py kamu
    final sanitizedPhone = _sanitizePhone(_phoneController.text);
    final priceValue = _priceController.text.replaceAll(',', '').trim();

    final Map<String, String> fields = {
      'name': _nameController.text.trim(),
      'sport_type': _selectedSportType ?? '',
      'location': _locationController.text.trim(),
      'address': _addressController.text.trim(),
      'price_per_hour': priceValue,
      'owner_phone': sanitizedPhone,
      'facilities': _facilitiesController.text.trim(),
      'description': _descController.text.trim(),
      'rating': '0',
    };

    bool success;
    final api = CourtApiHelper(request); // Inject request
    final imageFile = _imageFile != null ? File(_imageFile!.path) : null;

    try {
      if (widget.court == null) {
        // Mode Add
        success = await api.addCourt(fields, imageFile: imageFile);
      } else {
        // Mode Edit
        success = await api.editCourt(widget.court!.id, fields, imageFile: imageFile);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          // Kembali ke screen sebelumnya dengan sinyal 'true' agar list di-refresh
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal menyimpan data. Cek input Anda.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.court == null ? "Tambah Lapangan" : "Edit Lapangan"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Lapangan", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Harus diisi" : null,
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _selectedSportType,
              items: _sportLabels.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              decoration: const InputDecoration(
                labelText: "Jenis Olahraga",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _selectedSportType = val),
              validator: (v) => (v == null || v.isEmpty) ? "Pilih jenis olahraga" : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_imageFile == null ? "Pilih Gambar" : "Ganti Gambar"),
                  ),
                ),
                if (_imageFile != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _imageFile!.path.split(Platform.pathSeparator).last,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: "Area (misal: Jakarta)", border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? "Harus diisi" : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: "Harga / Jam", border: OutlineInputBorder(), prefixText: "Rp "),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = v?.replaceAll(',', '').trim() ?? '';
                      if (value.isEmpty) return "Harus diisi";
                      final parsed = double.tryParse(value);
                      if (parsed == null) return "Masukkan angka valid";
                      if (parsed < 0) return "Harga tidak boleh negatif";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder()),
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? "Harus diisi" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "No. HP Pemilik", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = _sanitizePhone(v ?? '');
                if (digits.isEmpty) return "Harus diisi";
                if (digits.length < 8 || digits.length > 20) return "Gunakan 8-20 digit angka";
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _facilitiesController,
              decoration: const InputDecoration(labelText: "Fasilitas (pisahkan koma)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
