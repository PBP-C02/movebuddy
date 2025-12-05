import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
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
  final _ratingController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _imageUrlController = TextEditingController();

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
      _ratingController.text = c.rating.toStringAsFixed(2);
      _imageUrlController.text = c.imageUrl ?? "";
      _mapLinkController.text = ""; // backend belum mengirim map link, tetap biarkan kosong
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
    _ratingController.dispose();
    _mapLinkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String _sanitizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
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
    final ratingValue = _ratingController.text.trim();

    final Map<String, String> fields = {
      'name': _nameController.text.trim(),
      'sport_type': _selectedSportType ?? '',
      'location': _locationController.text.trim(),
      'address': _addressController.text.trim(),
      'price_per_hour': priceValue,
      'owner_phone': sanitizedPhone,
      'facilities': _facilitiesController.text.trim(),
      'description': _descController.text.trim(),
      'rating': ratingValue.isEmpty ? '0' : ratingValue,
      'image_url': _imageUrlController.text.trim(),
      'google_maps_link': _mapLinkController.text.trim(),
    };

    bool success;
    final api = CourtApiHelper(request); // Inject request

    try {
      if (widget.court == null) {
        // Mode Add
        success = await api.addCourt(fields);
      } else {
        // Mode Edit
        success = await api.editCourt(widget.court!.id, fields);
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
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.court == null ? "Add New Court" : "Edit Court",
          style: const TextStyle(fontWeight: FontWeight.w700),
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
                  Text(
                    widget.court == null ? "Lengkapi detail lapangan" : "Perbarui informasi lapangan",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration("Nama Lapangan"),
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
                    decoration: _inputDecoration("Jenis Olahraga"),
                    onChanged: (val) => setState(() => _selectedSportType = val),
                    validator: (v) => (v == null || v.isEmpty) ? "Pilih jenis olahraga" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: _inputDecoration("Link Gambar (opsional)", hint: "https://contoh.com/gambar.jpg"),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: _inputDecoration("City / Area"),
                          validator: (v) => v == null || v.trim().isEmpty ? "Harus diisi" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: _inputDecoration("Harga / Jam", prefix: "Rp "),
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
                decoration: _inputDecoration("Alamat Lengkap"),
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mapLinkController,
                decoration: _inputDecoration(
                  "Google Maps link (opsional)",
                  hint: "https://maps.google.com/?q=-6.2,106.8",
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration("No. HP Pemilik"),
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
                decoration: _inputDecoration("Fasilitas (pisahkan koma)"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ratingController,
                decoration: _inputDecoration("Rating (opsional)", hint: "0 - 5"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final trimmed = v?.trim() ?? "";
                  if (trimmed.isEmpty) return null;
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null) return "Masukkan angka";
                  if (parsed < 0 || parsed > 5) return "0 - 5";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: _inputDecoration("Deskripsi (opsional)"),
                maxLines: 3,
              ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Simpan Court",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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

  InputDecoration _inputDecoration(String label, {String? hint, String? prefix}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
