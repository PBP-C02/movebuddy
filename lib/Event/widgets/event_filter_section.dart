import 'package:flutter/material.dart';
import '../utils/event_helpers.dart';

class EventFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedSport;
  final String selectedCity;
  final bool availableOnly;
  final Function(String) onSearchChanged;
  final Function(String) onSportSelected;
  final Function(String) onCitySelected;
  final Function(bool) onAvailableOnlyChanged;
  final VoidCallback? onResetFilters;

  const EventFilterSection({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedSport,
    required this.selectedCity,
    required this.availableOnly,
    required this.onSearchChanged,
    required this.onSportSelected,
    required this.onCitySelected,
    required this.onAvailableOnlyChanged,
    this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 16),
          _buildCityDropdown(),
          const SizedBox(height: 20),
          _buildSportFilters(),
          const SizedBox(height: 16),
          _buildAvailableOnlyCheckbox(),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            _buildResetButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIND YOUR SPORTS EVENT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Discover amazing sports events near you',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search events or locations...',
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF94A3B8),
        ),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCity.isEmpty ? null : selectedCity,
      decoration: InputDecoration(
        labelText: 'City',
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      items: [
        const DropdownMenuItem(value: '', child: Text('All cities')),
        ...EventHelpers.cities.map((city) => DropdownMenuItem(
          value: city,
          child: Text(city),
        )),
      ],
      onChanged: (value) => onCitySelected(value ?? ''),
    );
  }

  Widget _buildSportFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sport Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildSportChip('', 'All'),
              ...EventHelpers.sportTypes.map((sport) => _buildSportChip(
                sport['value']!,
                sport['label']!,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSportChip(String sport, String label) {
    final isSelected = selectedSport == sport;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onSportSelected(sport),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF84CC16) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF84CC16) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF84CC16).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableOnlyCheckbox() {
    return InkWell(
      onTap: () => onAvailableOnlyChanged(!availableOnly),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: availableOnly ? const Color(0xFF84CC16) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: availableOnly ? const Color(0xFF84CC16) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: availableOnly
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            const Text(
              'Show available only',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onResetFilters,
        icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF64748B)),
        label: const Text(
          'Reset Filters',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return searchQuery.isNotEmpty ||
        selectedSport.isNotEmpty ||
        selectedCity.isNotEmpty ||
        availableOnly;
  }
}