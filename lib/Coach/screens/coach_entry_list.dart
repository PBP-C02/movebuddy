import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Coach/models/coach_entry.dart';
import 'package:move_buddy/Coach/widgets/coach_entry_card.dart';

class CoachEntryListPage extends StatefulWidget {
  const CoachEntryListPage({super.key});

  @override
  State<CoachEntryListPage> createState() => _CoachEntryListPageState();
}

class _CoachEntryListPageState extends State<CoachEntryListPage> {
  static const String _baseUrl = String.fromEnvironment(
    'COACH_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String _searchPath = String.fromEnvironment(
    'COACH_SEARCH_PATH',
    defaultValue: '/coach/api/search/',
  );
  static const List<String> _locationOptions = [
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

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _searchQuery = '';
  String _selectedLocation = '';
  String _selectedCategory = '';
  bool _availableOnly = false;
  String _viewMode = 'all';
  String _sortBy = 'date_asc';
  int _resultCount = 0;

  late final CookieRequest _request;
  late Future<List<Coach>> _coachFuture;

  @override
  void initState() {
    super.initState();
    _request = context.read<CookieRequest>();
    _coachFuture = _fetchCoaches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Map<String, String> _buildQueryParams() {
    final params = <String, String>{
      'view': _viewMode,
      'sort': _sortBy,
    };

    if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;
    if (_selectedLocation.isNotEmpty) params['location'] = _selectedLocation;
    if (_selectedCategory.isNotEmpty) params['category'] = _selectedCategory;

    final minPrice = _minPriceController.text.trim();
    final maxPrice = _maxPriceController.text.trim();
    if (minPrice.isNotEmpty) params['min_price'] = minPrice;
    if (maxPrice.isNotEmpty) params['max_price'] = maxPrice;

    if (_availableOnly) params['available'] = 'true';

    return params;
  }

  Future<List<Coach>> _fetchCoaches() async {
    try {
      final queryString = Uri(queryParameters: _buildQueryParams()).query;
      final paths = <String>{
        _searchPath,
      }.toList();

      Object? lastError;

      for (final path in paths) {
        final url = '$_baseUrl$path${queryString.isEmpty ? '' : '?$queryString'}';
        try {
          final response = await _request.get(url);

          if (response == null) {
            lastError = 'Response kosong dari $url';
            continue;
          }

          List<dynamic> rawCoaches;
          if (response is Map && response['coaches'] is List) {
            rawCoaches = response['coaches'] as List<dynamic>;
          } else if (response is List) {
            rawCoaches = response;
          } else {
            lastError = 'Format tidak sesuai dari $url';
            continue;
          }

          final coaches = rawCoaches
              .map((item) => Coach.fromJson(item as Map<String, dynamic>))
              .toList();

          if (mounted) {
            setState(() {
              _resultCount = coaches.length;
            });
          }

          return coaches;
        } on FormatException catch (e) {
          debugPrint('Respon bukan JSON dari $url: $e');
          lastError = e;
          continue;
        } catch (e) {
          debugPrint('Error ketika memuat coach dari $url: $e');
          lastError = e;
          continue;
        }
      }

      throw Exception(
        'Gagal memuat data coach. Pastikan COACH_SEARCH_PATH mengarah ke endpoint JSON. Error terakhir: $lastError',
      );
    } catch (e) {
      debugPrint('Error ketika memuat coach: $e');
      rethrow;
    }
  }

  Future<void> _refresh() async {
    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    setState(() {
      _coachFuture = _fetchCoaches();
    });
    await _coachFuture;
  }

  void _toggleCategory(String value) {
    setState(() {
      _selectedCategory = _selectedCategory == value ? '' : value;
    });
    _applyFilters();
  }

  void _toggleViewMode(String value) {
    setState(() {
      _viewMode = _viewMode == value ? 'all' : value;
    });
    _applyFilters();
  }

  void _openPriceFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Harga',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga minimum',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga maksimum',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      setState(() {});
                    },
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _applyFilters();
                    },
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCoachDetail(Coach coach) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  coach.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  coach.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kontak & Link',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (coach.instagramLink.isNotEmpty)
                  _InfoRow(
                    icon: Icons.link,
                    label: 'Instagram',
                    value: coach.instagramLink,
                  ),
                if (coach.mapsLink.isNotEmpty)
                  _InfoRow(
                    icon: Icons.map_outlined,
                    label: 'Lokasi',
                    value: coach.mapsLink,
                  ),
                if (coach.instagramLink.isEmpty && coach.mapsLink.isEmpty)
                  Text(
                    'Belum ada link tambahan.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    final priceSummary = () {
      final min = _minPriceController.text.trim();
      final max = _maxPriceController.text.trim();
      if (min.isEmpty && max.isEmpty) return 'Filter harga';
      if (min.isNotEmpty && max.isNotEmpty) return 'Rp $min - Rp $max';
      if (min.isNotEmpty) return 'Mulai Rp $min';
      return 'Sampai Rp $max';
    }();

    const categories = [
      {'label': 'All', 'value': ''},
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Perfect Coach',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Jelajahi coach favoritmu dengan pengalaman dan jadwal yang sesuai.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari coach, lokasi, atau sesi...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLocation.isEmpty ? '' : _selectedLocation,
                        items: [
                          for (final loc in _locationOptions)
                            DropdownMenuItem(
                              value: loc,
                              child: Text(loc.isEmpty ? 'Semua lokasi' : loc),
                            ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Lokasi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _selectedLocation = value ?? '');
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openPriceFilterSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade900,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.filter_alt),
                      label: Text(priceSummary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Kategori Olahraga',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in categories)
                      _FilterChipOption(
                        label: cat['label']!,
                        selected: _selectedCategory == cat['value'],
                        onTap: () => _toggleCategory(cat['value']!),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _availableOnly,
                      onChanged: (value) {
                        setState(() => _availableOnly = value ?? false);
                        _applyFilters();
                      },
                    ),
                    const Text('Hanya tampilkan yang tersedia'),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'View Mode',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    _FilterChipOption(
                      label: 'All',
                      selected: _viewMode == 'all',
                      onTap: () => _toggleViewMode('all'),
                    ),
                    _FilterChipOption(
                      label: 'My Bookings',
                      selected: _viewMode == 'my_bookings',
                      onTap: () => _toggleViewMode('my_bookings'),
                    ),
                    _FilterChipOption(
                      label: 'Created Classes',
                      selected: _viewMode == 'my_coaches',
                      onTap: () => _toggleViewMode('my_coaches'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Menampilkan $_resultCount coach',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Urutkan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'date_asc',
                            child: Text('Tanggal terdekat'),
                          ),
                          DropdownMenuItem(
                            value: 'date_desc',
                            child: Text('Tanggal terjauh'),
                          ),
                          DropdownMenuItem(
                            value: 'price_asc',
                            child: Text('Harga terendah'),
                          ),
                          DropdownMenuItem(
                            value: 'price_desc',
                            child: Text('Harga tertinggi'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value ?? 'date_asc');
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Coach'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Coach>>(
          future: _coachFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildFilterBar(),
                  const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildFilterBar(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 42,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat data coach.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Periksa koneksi atau URL endpoint, lalu coba lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final coaches = snapshot.data ?? [];
            if (coaches.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildFilterBar(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 42,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada coach yang bisa ditampilkan.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba nonaktifkan filter atau tarik untuk refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: coaches.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterBar();
                }
                final coach = coaches[index - 1];
                return CoachEntryCard(
                  coach: coach,
                  onTap: () => _showCoachDetail(coach),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.green.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.green.shade900 : Colors.grey.shade800,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
    );
  }
}
