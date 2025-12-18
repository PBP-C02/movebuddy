import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:Movebuddy/Event/models/event_entry.dart';
import 'package:Movebuddy/Event/utils/event_helpers.dart';
import 'package:Movebuddy/Sport_Partner/constants.dart';

class EditEventForm extends StatefulWidget {
  final EventEntry event;

  const EditEventForm({super.key, required this.event});

  @override
  State<EditEventForm> createState() => _EditEventFormState();
}

class _EditEventFormState extends State<EditEventForm> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _sportType;
  late String _description;
  late String _city;
  late String _fullAddress;
  late String _entryPrice;
  late String _activities;
  late String _rating;
  late String _googleMapsLink;
  late String _category;
  late String _status;

  List<DateTime> selectedDates = [];

  @override
  void initState() {
    super.initState();

    // Initialize with existing event data
    _name = widget.event.name;
    _sportType = widget.event.sportType;
    _description = widget.event.description;
    _city = widget.event.city;
    _fullAddress = widget.event.fullAddress;
    _entryPrice = widget.event.entryPrice;
    _activities = widget.event.activities;
    _rating = widget.event.rating;
    _googleMapsLink = widget.event.googleMapsLink;
    _category = widget.event.category;
    _status = widget.event.status;

    // Initialize selected dates from event schedules
    if (widget.event.schedules != null) {
      selectedDates = widget.event.schedules!.map((s) => s.date).toList();
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
              primary: Color(0xFF84CC16),
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'EDIT EVENT',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF84CC16),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                'Basic Information',
                Icons.info_outline,
                Column(
                  children: [
                    _buildTextField(
                      label: 'Event Name',
                      hint: 'e.g., Weekend Soccer Match',
                      initialValue: _name,
                      onChanged: (value) => setState(() => _name = value),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Sport Type',
                      value: _sportType,
                      items: EventHelpers.sportTypes.map((sport) {
                        return DropdownMenuItem(
                          value: sport['value'],
                          child: Row(
                            children: [
                              Text(
                                EventHelpers.getSportIcon(sport['value']!),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(sport['label']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _sportType = value!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Description',
                      hint: 'Tell us about your event...',
                      initialValue: _description,
                      maxLines: 3,
                      onChanged: (value) =>
                          setState(() => _description = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                'Location',
                Icons.location_on,
                Column(
                  children: [
                    _buildDropdown(
                      label: 'City',
                      value: _city.isEmpty ? null : _city,
                      items: EventHelpers.cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                      onChanged: (value) => setState(() => _city = value!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Full Address',
                      hint: 'Complete address with details',
                      initialValue: _fullAddress,
                      maxLines: 2,
                      onChanged: (value) =>
                          setState(() => _fullAddress = value),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Google Maps Link (optional)',
                      hint: 'https://maps.google.com/...',
                      initialValue: _googleMapsLink,
                      onChanged: (value) =>
                          setState(() => _googleMapsLink = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                'Pricing & Details',
                Icons.attach_money,
                Column(
                  children: [
                    _buildTextField(
                      label: 'Entry Price (IDR)',
                      hint: '50000',
                      initialValue: _entryPrice,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() => _entryPrice = value),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Activities (comma separated)',
                      hint: 'e.g., Basketball court, Shower, Locker',
                      initialValue: _activities,
                      onChanged: (value) => setState(() => _activities = value),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Rating (0-5)',
                      hint: '5',
                      initialValue: _rating,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                'Available Dates',
                Icons.calendar_today,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84CC16),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: selectDates,
                    ),
                    if (selectedDates.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_city.isEmpty) {
                        _showSnackBar('Please select a city', isError: true);
                        return;
                      }
                      if (selectedDates.isEmpty) {
                        _showSnackBar(
                          'Please add at least one date',
                          isError: true,
                        );
                        return;
                      }

                      final scheduleDates = selectedDates.map((date) {
                        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      }).toList();

                      try {
                        final response = await request.postJson(
                          "$baseUrl/event/json/${widget.event.id}/edit/",
                          jsonEncode({
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
                          }),
                        );

                        if (context.mounted) {
                          if (response['success'] == true) {
                            _showSnackBar('Event updated successfully!');
                            Navigator.pop(context, true);
                          } else {
                            _showSnackBar(
                              response['message'] ?? 'Failed',
                              isError: true,
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showSnackBar('Error: $e', isError: true);
                        }
                      }
                    }
                  },
                  child: const Text(
                    'UPDATE EVENT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF84CC16), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    String? initialValue,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
          borderSide: const BorderSide(color: Color(0xFF84CC16), width: 2),
        ),
      ),
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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
          borderSide: const BorderSide(color: Color(0xFF84CC16), width: 2),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF84CC16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
