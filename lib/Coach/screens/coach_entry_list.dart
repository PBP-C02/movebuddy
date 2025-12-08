import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Coach/models/coach_entry.dart';
import 'package:move_buddy/Coach/widgets/coach_entry_card.dart';
import 'package:move_buddy/Coach/screens/coach_create_page.dart';
import 'package:move_buddy/Coach/screens/coach_detail_page.dart';

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
    final params = <String, String>{'view': _viewMode, 'sort': _sortBy};

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
      final paths = <String>{_searchPath}.toList();

      Object? lastError;

      for (final path in paths) {
        final url =
            '$_baseUrl$path${queryString.isEmpty ? '' : '?$queryString'}';
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

  Future<void> _openCreateCoach() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CoachCreatePage()),
    );
    if (created == true) {
      _refresh();
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _coachFuture = _fetchCoaches();
    });
    await _coachFuture;
  }

  Future<void> _openDetail(Coach coach) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CoachDetailPage(
          coach: coach,
          canEdit: _viewMode == 'my_coaches' || coach.isOwner,
        ),
      ),
    );
    if (updated == true) {
      _refresh();
    }
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
                  ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
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
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value:
                            _selectedLocation.isEmpty ? '' : _selectedLocation,
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
                        backgroundColor: const Color(0xFF8BC34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.filter_alt),
                      label: Text(priceSummary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori Olahraga',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.swap_horiz, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Scroll',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in categories) ...[
                        _FilterChipOption(
                          label: cat['label']!,
                          selected: _selectedCategory == cat['value'],
                          onTap: () => _toggleCategory(cat['value']!),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(() => _availableOnly = !_availableOnly);
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _availableOnly,
                        onChanged: (value) {
                          setState(() => _availableOnly = value ?? false);
                          _applyFilters();
                        },
                        activeColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Text(
                        'Hanya tampilkan yang tersedia',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 22),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        label: 'All',
                        selected: _viewMode == 'all',
                        onTap: () => _toggleViewMode('all'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentButton(
                        label: 'My Bookings',
                        selected: _viewMode == 'my_bookings',
                        onTap: () => _toggleViewMode('my_bookings'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentButton(
                        label: 'Created Classes',
                        selected: _viewMode == 'my_coaches',
                        onTap: () => _toggleViewMode('my_coaches'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menampilkan $_resultCount coach',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Perbarui filter untuk hasil terbaru',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openCreateCoach,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tambah Coach',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Coaches',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/coach/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.9)),
          ),
          RefreshIndicator(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 42,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada coach yang bisa ditampilkan.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                            textAlign: TextAlign.center,
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
                      onTap: () => _openDetail(coach),
                    );
                  },
                );
              },
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
    final background =
        selected ? const Color(0xFFE8F5E9) : Colors.grey.shade50;
    final borderColor =
        selected ? const Color(0xFF8BC34A) : Colors.grey.shade400;
    final textColor = selected ? const Color(0xFF2E7D32) : Colors.grey.shade900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFE8F5E9) : Colors.white;
    final border = selected ? const Color(0xFF8BC34A) : Colors.grey.shade300;
    final textColor = selected ? const Color(0xFF2E7D32) : Colors.grey.shade800;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
