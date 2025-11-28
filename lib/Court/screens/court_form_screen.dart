import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/court_models.dart';
import '../helpers/court_api_helper.dart';

class CourtFormScreen extends StatefulWidget {
  final Court? court; // Null jika Add, terisi jika Edit

  const CourtFormScreen({Key? key, this.court}) : super(key: key);

  @override
  _CourtFormScreenState createState() => _CourtFormScreenState();
}

class _CourtFormScreenState extends State<CourtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourtApiHelper _api = CourtApiHelper();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _ratingController;
  late TextEditingController _phoneController;
  late TextEditingController _facilitiesController;
  late TextEditingController _descriptionController;

  String _selectedSport = "tennis";
  File? _imageFile;
  bool _isLoading = false;

  // Pilihan olahraga harus sama dengan backend (models.py)
  final List<String> _sportTypes = [
    'tennis', 'basketball', 'soccer', 'badminton',
    'volleyball', 'paddle', 'futsal', 'table_tennis',
  ];

  @override
  void initState() {
    super.initState();
    // Setup data awal
    _nameController = TextEditingController(text: widget.court?.name ?? "");
    _locationController = TextEditingController(text: widget.court?.location ?? "");
    _addressController = TextEditingController(text: widget.court?.address ?? "");
    // Hati-hati parsing double ke String
    _priceController = TextEditingController(text: widget.court != null ? widget.court!.price.toStringAsFixed(0) : "");
    _ratingController = TextEditingController(text: widget.court?.rating.toString() ?? "0");
    _facilitiesController = TextEditingController(text: widget.court?.facilities ?? "");
    
    // Data phone & deskripsi biasanya ada di detail, 
    // tapi object 'Court' dari list kadang belum memuatnya. 
    // Disini kita kosongkan defaultnya, user bisa isi ulang jika edit.
    _phoneController = TextEditingController(text: "");
    _descriptionController = TextEditingController(text: "");

    // Jika mode edit, set dropdown
    if (widget.court != null) {
      // Pastikan value ada di list, jika tidak default ke index 0
      if (_sportTypes.contains(widget.court!.sportType)) {
        _selectedSport = widget.court!.sportType;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _phoneController.dispose();
    _facilitiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Kunci Map harus sesuai dengan request.POST di Django views
    Map<String, String> fields = {
      'name': _nameController.text,
      'sport_type': _selectedSport,
      'location': _locationController.text,
      'address': _addressController.text,
      'price_per_hour': _priceController.text,
      'rating': _ratingController.text,
      'facilities': _facilitiesController.text,
      'description': _descriptionController.text,
      'owner_phone': _phoneController.text,
    };

    try {
      bool success;
      if (widget.court == null) {
        success = await _api.addCourt(fields, _imageFile);
      } else {
        success = await _api.editCourt(widget.court!.id, fields, _imageFile);
      }

      if (success) {
        if (!mounted) return;
        Navigator.pop(context, true); // Kembali ke screen sebelumnya dengan sinyal 'true'
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal menyimpan: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.court != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Lapangan" : "Tambah Lapangan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Area Upload Gambar ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (isEdit && widget.court!.imageUrl != null
                          ? Image.network(
                              "${CourtApiHelper.baseUrl}${widget.court!.imageUrl}",
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                Text("Ketuk untuk upload foto")
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 16),

              // --- Form Fields ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Lapangan", border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedSport,
                decoration: const InputDecoration(labelText: "Jenis Olahraga", border: OutlineInputBorder()),
                items: _sportTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedSport = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Lokasi (Kota/Area)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Lokasi wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Alamat Lengkap", border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Alamat wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: "Harga/Jam (Rp)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ratingController,
                      decoration: const InputDecoration(labelText: "Rating Awal (0-5)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "WhatsApp Owner", 
                  border: OutlineInputBorder(),
                  helperText: "Format: 628123456789"
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Nomor WA wajib diisi";
                  if (v.length < 9) return "Nomor terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _facilitiesController,
                decoration: const InputDecoration(labelText: "Fasilitas (Wifi, Parkir, dll)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Deskripsi Tambahan", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(isEdit ? "Simpan Perubahan" : "Buat Lapangan Baru", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}