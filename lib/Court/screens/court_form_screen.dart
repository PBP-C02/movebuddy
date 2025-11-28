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

  // Controllers
  final _nameController = TextEditingController();
  final _sportTypeController = TextEditingController();
  final _locationController = TextEditingController(); // e.g. "Jakarta Selatan"
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facilitiesController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi form dengan data lama
    if (widget.court != null) {
      final c = widget.court!;
      _nameController.text = c.name;
      _sportTypeController.text = c.sportType;
      _locationController.text = c.location;
      _addressController.text = c.address;
      _priceController.text = c.price.toInt().toString();
      _phoneController.text = ""; // Note: BasicInfo Court mungkin tidak menyimpan phone, sesuaikan jika ada
      _facilitiesController.text = c.facilities;
      // Description ada di Detail, bukan BasicInfo. 
      // Jika model Court kamu punya desc, masukkan di sini.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sportTypeController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _facilitiesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Ambil CookieRequest dari Provider
    final request = context.read<CookieRequest>();
    
    // 2. Siapkan data fields
    // Sesuaikan key map ini dengan yang diminta Django views.py kamu
    final Map<String, String> fields = {
      'name': _nameController.text,
      'sport_type': _sportTypeController.text,
      'location': _locationController.text,
      'address': _addressController.text,
      'price_per_hour': _priceController.text,
      'owner_phone': _phoneController.text,
      'facilities': _facilitiesController.text,
      'description': _descController.text,
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
            
            TextFormField(
              controller: _sportTypeController,
              decoration: const InputDecoration(labelText: "Jenis Olahraga (tennis, futsal, dll)", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Harus diisi" : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: "Area (misal: Jakarta)", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Harus diisi" : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: "Harga / Jam", border: OutlineInputBorder(), prefixText: "Rp "),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Harus diisi" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder()),
              maxLines: 2,
              validator: (v) => v!.isEmpty ? "Harus diisi" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "No. HP Pemilik", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
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