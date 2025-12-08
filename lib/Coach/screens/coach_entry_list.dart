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
    defaultValue: 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/coach/',
  );
  static const String _searchPath = String.fromEnvironment(
    'COACH_SEARCH_PATH',
    defaultValue: 'api/search/',
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
      final currentUserId = _resolveCurrentUserId();

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
              .map(
                (item) => Coach.fromJson(
                  item as Map<String, dynamic>,
                  currentUserId: currentUserId,
                ),
              )
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
          canEdit: coach.isOwner,
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

  String? _resolveCurrentUserId() {
    final cookieId = _request.cookies['user_id']?.toString();
    if (cookieId != null && cookieId.isNotEmpty) return cookieId;

    final data = _request.jsonData;
    if (data is Map) {
      for (final key in ['id', 'user_id', 'userId']) {
        final val = data[key];
        if (val != null && val.toString().isNotEmpty) {
          return val.toString();
        }
      }
    }
    return null;
  }

  void _toggleViewMode(String value) {
    setState(() {
      _viewMode = _viewMode == value ? 'all' : value;
    });
    _applyFilters();
  }

  void _openPriceFilterSheet() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            InputDecoration _priceDecoration(
              String label, {
              bool highlightError = false,
            }) {
              final borderColor = highlightError ? Colors.red : Colors.grey.shade400;
              return InputDecoration(
                labelText: label,
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: highlightError ? Colors.red : const Color(0xFF182435),
                    width: 1.5,
                  ),
                ),
              );
            }

            void _clearError() {
              if (errorText != null) {
                setStateDialog(() {
                  errorText = null;
                });
              }
            }

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Harga',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
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
                            decoration: _priceDecoration(
                              'Harga minimum',
                              highlightError: errorText != null,
                            ),
                            onChanged: (_) => _clearError(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: _priceDecoration(
                              'Harga maksimum',
                              highlightError: errorText != null,
                            ),
                            onChanged: (_) => _clearError(),
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            _minPriceController.clear();
                            _maxPriceController.clear();
                            setState(() {});
                            _clearError();
                          },
                          child: const Text('Reset'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            final minVal = int.tryParse(
                                  _minPriceController.text
                                      .replaceAll(RegExp(r'[^0-9]'), ''),
                                ) ??
                                0;
                            final maxVal = int.tryParse(
                                  _maxPriceController.text
                                      .replaceAll(RegExp(r'[^0-9]'), ''),
                                ) ??
                                0;

                            if (_minPriceController.text.trim().isNotEmpty &&
                                _maxPriceController.text.trim().isNotEmpty &&
                                minVal > maxVal) {
                              setStateDialog(() {
                                errorText =
                                    'Harga minimum tidak boleh lebih besar dari maksimum.';
                              });
                              return;
                            }

                            Navigator.of(dialogCtx).pop();
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7DC81),
                            foregroundColor: const Color(0xFF182435),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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

    const sectionLabelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: Color(0xFF182435),
    );

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
                      onPressed: _openCreateCoach,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB7DC81),
                        foregroundColor: const Color(0xFF182435),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Coach'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori Olahraga',
                      style: sectionLabelStyle,
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
                        activeColor: const Color(0xFFB7DC81),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Text(
                        'Hanya tampilkan yang tersedia',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6C7B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF182435),
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
                    onPressed: _openPriceFilterSheet,
                    style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB7DC81),
                  foregroundColor: const Color(0xFF182435),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_alt, color: Color(0xFF182435)),
                        const SizedBox(width: 8),
                        Text(
                          priceSummary,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
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
      backgroundColor: Colors.white,
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
        selected ? const Color(0xFFB7DC81) : Colors.grey.shade50;
    final borderColor =
        selected ? const Color(0xFFB7DC81) : Colors.grey.shade400;
    final textColor = selected ? const Color(0xFF182435) : Colors.grey.shade900;

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
              const Icon(Icons.check, size: 16, color: Color(0xFF182435)),
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
    final bg = selected ? const Color(0xFFB7DC81) : Colors.white;
    final border = selected ? const Color(0xFFB7DC81) : Colors.grey.shade300;
    final textColor =
        selected ? const Color(0xFF182435) : const Color(0xFF3A4A5A);

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
