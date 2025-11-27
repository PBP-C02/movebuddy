// lib/court/screens/edit_court_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../models/court.dart';
import '../services/court_service.dart';
import '../utils/court_helpers.dart';

class EditCourtScreen extends StatefulWidget {
  final Court court;
  final CourtService courtService;

  const EditCourtScreen({
    super.key,
    required this.court,
    required this.courtService,
  });

  @override
  State<EditCourtScreen> createState() => _EditCourtScreenState();
}

class _EditCourtScreenState extends State<EditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _facilitiesController;
  late TextEditingController _ratingController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _mapsLinkController;

  late String _selectedSport;
  File? _newImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.court.name);
    _locationController = TextEditingController(text: widget.court.location);
    _addressController = TextEditingController(text: widget.court.address);
    _priceController = TextEditingController(
      text: widget.court.price.toStringAsFixed(0),
    );
    _facilitiesController = TextEditingController(
      text: widget.court.facilities,
    );
    _ratingController = TextEditingController(
      text: widget.court.rating > 0
          ? widget.court.rating.toStringAsFixed(1)
          : '',
    );
    _descriptionController = TextEditingController(
      text: widget.court.description,
    );
    _phoneController = TextEditingController(
      text: widget.court.ownerPhone ?? '',
    );
    _mapsLinkController = TextEditingController();
    _selectedSport = widget.court.sportType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _facilitiesController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _mapsLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF64748B)),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF64748B)),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newImage = File(image.path);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<CookieRequest>();
      await auth.init();
      if (!mounted) return;
      final hasSession = auth.loggedIn || auth.cookies.isNotEmpty;
      if (!hasSession) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login terlebih dahulu untuk memperbarui lapangan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await widget.courtService.editCourt(
        courtId: widget.court.id,
        name: _nameController.text.trim(),
        sportType: _selectedSport,
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        pricePerHour: double.parse(_priceController.text.trim()),
        ownerPhone: CourtHelpers.sanitizePhoneNumber(_phoneController.text),
        facilities: _facilitiesController.text.trim(),
        rating: _ratingController.text.isEmpty
            ? null
            : double.tryParse(_ratingController.text.trim()),
        description: _descriptionController.text.trim(),
        image: _newImage,
        mapsLink: _mapsLinkController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lapangan berhasil diperbarui!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context, true); // Return true to refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui lapangan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('EDIT LAPANGAN'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EDIT COURT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.5,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Perbarui informasi lapangan',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nama Lapangan *',
            hint: 'Contoh: Lapangan Tennis ABC',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama lapangan wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildSportDropdown(),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _locationController,
            label: 'Kota *',
            hint: 'Contoh: Jakarta',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kota wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _phoneController,
            label: 'Nomor Kontak *',
            hint: 'Contoh: 081234567890',
            keyboardType: TextInputType.phone,
            validator: CourtHelpers.validatePhoneNumber,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _addressController,
            label: 'Alamat Lengkap *',
            hint: 'Jl. Contoh No. 123',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Harga per Jam (IDR) *',
                  hint: '150000',
                  keyboardType: TextInputType.number,
                  validator: CourtHelpers.validatePrice,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _ratingController,
                  label: 'Rating (1-5)',
                  hint: '4.5',
                  keyboardType: TextInputType.number,
                  validator: CourtHelpers.validateRating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _facilitiesController,
            label: 'Fasilitas',
            hint: 'Parking, Restroom, Canteen',
            helperText: 'Pisahkan dengan koma',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Deskripsi',
            hint: 'Deskripsi singkat tentang lapangan',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _mapsLinkController,
            label: 'Google Maps Link',
            hint: 'https://maps.google.com/?q=-6.2,106.8',
            helperText: 'Kosongkan untuk mempertahankan lokasi saat ini',
          ),
          const SizedBox(height: 24),
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBED98),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Olahraga *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSport,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFCBED98),
                width: 2,
              ),
            ),
          ),
          items: CourtHelpers.sportTypes.map((sport) {
            return DropdownMenuItem(
              value: sport['value'],
              child: Row(
                children: [
                  Text(
                    CourtHelpers.getSportIcon(sport['value']!),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(sport['label']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSport = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Lapangan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        
        // Current image
        if (widget.court.imageUrl != null && _newImage == null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.court.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // New image
        if (_newImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _newImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: Icon(
            _newImage == null ? Icons.edit : Icons.edit,
            color: const Color(0xFF64748B),
          ),
          label: Text(
            _newImage == null ? 'Ganti Foto' : 'Pilih Foto Lain',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kosongkan untuk mempertahankan foto saat ini',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCBED98),
          foregroundColor: const Color(0xFF1F2B15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1F2B15),
                ),
              )
            : const Text(
                'SIMPAN PERUBAHAN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
