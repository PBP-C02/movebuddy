import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/utils/event_helpers.dart';
import 'package:move_buddy/Sport_Partner/constants.dart';
import 'package:move_buddy/Event/models/event_entry.dart';

class AddEventForm extends StatefulWidget {
  final EventEntry? initialEvent;
  const AddEventForm({super.key, this.initialEvent});

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();

  String _name = "";
  String _sportType = "soccer";
  String _description = "";
  String _city = "";
  String _fullAddress = "";
  String _entryPrice = "";
  String _activities = "";
  String _rating = "0";
  String _googleMapsLink = "";
  String _category = "category 1";
  String _status = "available";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _entryPriceController = TextEditingController();
  final TextEditingController _activitiesController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _googleMapsController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  Uint8List? _uploadedImageBytes;
  String? _uploadedImageDataUrl;
  final ImagePicker _imagePicker = ImagePicker();

  List<DateTime> selectedDates = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _entryPriceController.dispose();
    _activitiesController.dispose();
    _ratingController.dispose();
    _googleMapsController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prefillFromEvent();
    EventHelpers.ensureLocaleInitialized().then((_) {
      if (mounted) setState(() {});
    });
  }

  bool get isEdit => widget.initialEvent != null;

  void _prefillFromEvent() {
    final event = widget.initialEvent;
    if (event == null) return;

    _name = event.name;
    _sportType = event.sportType.isNotEmpty ? event.sportType : _sportType;
    _description = event.description;
    _city = event.city;
    _fullAddress = event.fullAddress;
    _entryPrice = event.entryPrice;
    _activities = event.activities;
    _rating = event.rating;
    _googleMapsLink = event.googleMapsLink;
    _category = event.category.isNotEmpty ? event.category : _category;
    _status = event.status.isNotEmpty ? event.status : _status;

    _nameController.text = _name;
    _descriptionController.text = _description;
    _addressController.text = _fullAddress;
    _entryPriceController.text = _entryPrice;
    _activitiesController.text = _activities;
    _ratingController.text = _rating;
    _googleMapsController.text = _googleMapsLink;
    if (event.photoUrl.isNotEmpty) {
      _photoUrlController.text = event.photoUrl;
    }
    if (event.schedules != null) {
      selectedDates = event.schedules!.map((e) => e.date).toList();
    }
  }

  Future<void> selectDates() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8BC34A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && !selectedDates.contains(picked)) {
      setState(() => selectedDates.add(picked));
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final mimeType = _detectMimeType(pickedFile.path);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      setState(() {
        _uploadedImageBytes = bytes;
        _uploadedImageDataUrl = dataUrl;
      });
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Widget _buildPhotoPreview() {
    final url = _photoUrlController.text.trim();

    if (url.startsWith('data:image')) {
      try {
        final data = Uri.parse(url).data;
        if (data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                data.contentAsBytes(),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      } catch (_) {
        // Fallback to generic preview below
      }
    }

    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 40),
              ),
            ),
          ),
        ),
      );
    }

    if (_uploadedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.memory(
            _uploadedImageBytes!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'Photo preview will appear here',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          isEdit ? "Edit Event" : "Add Event",
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
                  const Text(
                    "Lengkapi detail event",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Nama Event',
                    hint: 'Weekend Soccer Match',
                    controller: _nameController,
                    onChanged: (value) => _name = value,
                    validator: (value) => value == null || value.isEmpty ? 'Harus diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Jenis Olahraga',
                    value: _sportType,
                    items: EventHelpers.sportTypes.map((sport) {
                      return DropdownMenuItem(
                        value: sport['value'],
                        child: Text(sport['label'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _sportType = value!),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Deskripsi',
                    hint: 'Ceritakan event kamu...',
                    maxLines: 3,
                    controller: _descriptionController,
                    onChanged: (value) => _description = value,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Foto Event",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Link Gambar (opsional)',
                    hint: 'https://contoh.com/event.jpg',
                    keyboardType: TextInputType.url,
                    controller: _photoUrlController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoPreview(),
                  const SizedBox(height: 6),
                  Text(
                    _photoUrlController.text.trim().isNotEmpty
                        ? 'Preview memakai link di atas. Kosongkan jika ingin memakai foto upload.'
                        : _uploadedImageBytes != null
                            ? 'Foto upload akan dikirim sebagai data URL.'
                            : 'Tempel link atau upload dari perangkat.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Lokasi",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    label: 'Kota',
                    value: _city.isEmpty ? null : _city,
                    items: EventHelpers.cities
                        .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                        .toList(),
                    onChanged: (value) => setState(() => _city = value ?? ""),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Alamat Lengkap',
                    hint: 'Tuliskan alamat detail',
                    maxLines: 2,
                    controller: _addressController,
                    onChanged: (value) => _fullAddress = value,
                    validator: (value) => value == null || value.isEmpty ? 'Harus diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Link Google Maps (opsional)',
                    hint: 'https://maps.google.com/...',
                    controller: _googleMapsController,
                    onChanged: (value) => _googleMapsLink = value,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Harga & Detail",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Harga Tiket (IDR)',
                    hint: '50000',
                    keyboardType: TextInputType.number,
                    controller: _entryPriceController,
                    onChanged: (value) => _entryPrice = value,
                    validator: (value) => value == null || value.isEmpty ? 'Harus diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Aktivitas / Fasilitas (pisahkan koma)',
                    hint: 'Basket court, Shower, Locker',
                    controller: _activitiesController,
                    onChanged: (value) => _activities = value,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Rating (0-5)',
                    hint: '5',
                    keyboardType: TextInputType.number,
                    controller: _ratingController,
                    onChanged: (value) => _rating = value,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Tanggal Tersedia",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Tanggal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: selectDates,
                  ),
                  if (selectedDates.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedDates.map((date) {
                        return Chip(
                          label: Text(EventHelpers.formatDateShort(date)),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() => selectedDates.remove(date));
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (_city.isEmpty) {
                            _showSnackBar('Pilih kota terlebih dahulu', isError: true);
                            return;
                          }
                          if (selectedDates.isEmpty) {
                            _showSnackBar('Tambah minimal satu tanggal', isError: true);
                            return;
                          }

                          final scheduleDates = selectedDates.map((date) {
                            return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }).toList();

                          final photoToSend = _photoUrlController.text.trim().isNotEmpty
                              ? _photoUrlController.text.trim()
                              : (_uploadedImageDataUrl ?? "");

                          try {
                          final payload = {
                            'name': _name,
                            'sport_type': _sportType,
                            'description': _description,
                            'city': _city,
                            'full_address': _fullAddress,
                            'entry_price': _entryPrice,
                            'activities': _activities,
                            'rating': _rating,
                            'google_maps_link': _googleMapsLink,
                            'category': _category,
                            'status': _status,
                            'schedule_dates': scheduleDates,
                            'photo_url': photoToSend,
                          };

                          final response = await _submitEvent(request, payload);

                          if (context.mounted) {
                            if (response is Map && response['success'] == true) {
                              _showSnackBar(
                                widget.initialEvent == null
                                      ? 'Event created successfully!'
                                      : 'Event updated successfully!',
                                );
                                Navigator.pop(context, true);
                              } else {
                                final message = _stringifyMessage(
                                  (response is Map ? response['message'] : null) ??
                                      'Failed to ${widget.initialEvent == null ? 'create' : 'update'} event',
                                );
                                _showSnackBar(message, isError: true);
                              }
                            }
                          } on FormatException catch (e) {
                            if (context.mounted) {
                              _showSnackBar(
                                'Respon tidak valid (mungkin sesi kadaluarsa atau server mengembalikan HTML): $e',
                                isError: true,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showSnackBar(_stringifyMessage(e), isError: true);
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Simpan Event",
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

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextEditingController? controller,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, hint: hint),
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label),
      items: items,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF8BC34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _stringifyMessage(dynamic message) {
    if (message == null) return '';
    if (message is String) return message;
    if (message is List) return message.join(', ');
    return message.toString();
  }

  Future<dynamic> _submitEvent(
    CookieRequest request,
    Map<String, dynamic> payload,
  ) async {
    final url = isEdit
        ? "$baseUrl/event/json/${widget.initialEvent!.id}/edit/"
        : "$baseUrl/event/json/create/";

    // Use CookieRequest so session cookies/CSRF stay in sync with login state
    return request.postJson(
      url,
      jsonEncode(payload),
    );
  }
}
