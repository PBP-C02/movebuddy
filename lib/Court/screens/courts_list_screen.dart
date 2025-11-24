import 'package:flutter/material.dart';
import '../models/court.dart';
import '../services/court_service.dart';
import '../widgets/court_card.dart';
import '../utils/court_helpers.dart';
// import 'court_detail_screen.dart';

class CourtsListScreen extends StatefulWidget {
  final CourtService courtService;

  const CourtsListScreen({Key? key, required this.courtService})
    : super(key: key);

  @override
  State<CourtsListScreen> createState() => _CourtsListScreenState();
}

class _CourtsListScreenState extends State<CourtsListScreen> {
  List<Court> _courts = [];
  List<Court> _filteredCourts = [];
  bool _isLoading = true;
  String _selectedSport = '';
  String _selectedLocation = '';
  String _searchQuery = '';
  bool _availableOnly = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);

    try {
      final courts = await widget.courtService.getAllCourts();
      if (mounted) {
        setState(() {
          _courts = courts;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _courts.where((court) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          court.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          court.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          court.address.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesSport =
          _selectedSport.isEmpty || court.sportType == _selectedSport;
      bool matchesLocation =
          _selectedLocation.isEmpty ||
          court.location.toLowerCase() == _selectedLocation.toLowerCase();
      bool matchesAvailability = !_availableOnly || court.isAvailable;

      return matchesSearch &&
          matchesSport &&
          matchesLocation &&
          matchesAvailability;
    }).toList();

    setState(() {
      _filteredCourts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFCBED98),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        _buildFilters(),
                        Expanded(
                          child: _filteredCourts.isEmpty
                              ? _buildEmptyState()
                              : _buildCourtsList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'MOVEBUDDY',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF64748B),
            tooltip: 'Add Court',
            onPressed: () {
              // TODO: Navigate to add court screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Court feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: const Color(0xFF64748B),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
          const Text(
            'FIND YOUR PERFECT COURT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Temukan lapangan olahraga terbaik untuk kamu',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari lapangan atau lokasi...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
          ),
          const SizedBox(height: 16),

          // Location dropdown
          DropdownButtonFormField<String>(
            value: _selectedLocation.isEmpty ? null : _selectedLocation,
            decoration: InputDecoration(
              labelText: 'Lokasi',
              labelStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
            items: [
              const DropdownMenuItem(value: '', child: Text('Semua lokasi')),
              ...CourtHelpers.cities.map(
                (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLocation = value ?? '';
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 20),

          // Sport filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSportChip('', 'All'),
                ...CourtHelpers.sportTypes.map(
                  (sport) => _buildSportChip(sport['value']!, sport['label']!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Available only checkbox
          InkWell(
            onTap: () {
              setState(() {
                _availableOnly = !_availableOnly;
                _applyFilters();
              });
            },
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
                      color: _availableOnly
                          ? const Color(0xFFCBED98)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _availableOnly
                            ? const Color(0xFFCBED98)
                            : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: _availableOnly
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Color(0xFF1F2B15),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hanya tampilkan yang tersedia',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportChip(String sport, String label) {
    final isSelected = _selectedSport == sport;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSport = sport;
            _applyFilters();
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCBED98) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFCBED98)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFCBED98).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF1F2B15)
                  : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourtsList() {
    return RefreshIndicator(
      onRefresh: _loadCourts,
      color: const Color(0xFFCBED98),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredCourts.length,
        itemBuilder: (context, index) {
          return CourtCard(
            court: _filteredCourts[index],
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => CourtDetailScreen(
              //       courtId: _filteredCourts[index].id,
              //       courtService: widget.courtService,
              //     ),
              //   ),
              // ).then((_) => _loadCourts());
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.sports_tennis,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tidak ada lapangan ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coba ubah filter pencarian kamu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedSport = '';
                  _selectedLocation = '';
                  _availableOnly = false;
                  _applyFilters();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCBED98),
                foregroundColor: const Color(0xFF1F2B15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Reset Filter',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // TODO: Call auth service logout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout functionality coming soon')),
      );
    }
  }
}
