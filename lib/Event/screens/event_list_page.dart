import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:Movebuddy/Coach/screens/coach_entry_list.dart';
import 'package:Movebuddy/Event/models/event_entry.dart';
import 'package:Movebuddy/Event/screens/event_detail_page.dart';
import 'package:Movebuddy/Event/screens/add_event_form.dart';
import 'package:Movebuddy/Event/screens/edit_event_form.dart';
import 'package:Movebuddy/Event/widgets/event_card.dart';
import 'package:Movebuddy/Event/utils/event_helpers.dart';
import 'package:Movebuddy/Event/event_config.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _searchQuery = '';
  String _selectedSport = '';
  String _selectedCity = '';
  bool _availableOnly = false;
  String _sortBy = 'newest';
  Timer? _debounce;
  late Future<List<EventEntry>> _eventsFuture;
  bool _isInit = true;
  String _activeTab = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final request = context.read<CookieRequest>();
      _refreshData(request);
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<List<EventEntry>> fetchEvents(CookieRequest request) async {
    final uri = Uri.parse(EventConfig.resolve('/event/ajax/search/')).replace(
      queryParameters: {
        if (_selectedSport.isNotEmpty) 'sport': _selectedSport,
        if (_availableOnly) 'available': 'true',
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCity.isNotEmpty) 'city': _selectedCity,
      },
    );

    final response = await request.get(uri.toString());

    debugPrint('GET $uri');
    debugPrint('event response type: ${response.runtimeType}');
    debugPrint('event response: $response');

    final eventData = response is Map<String, dynamic>
        ? (response['events'] as List<dynamic>? ?? [])
        : response is List
        ? response
        : [];

    final events = eventData
        .whereType<Map<String, dynamic>>()
        .map(EventEntry.fromJson)
        .toList();

    return events;
  }

  Future<List<EventEntry>> fetchBookings(CookieRequest request) async {
    try {
      final response = await request.get(
        EventConfig.resolve('/event/json/my-bookings/'),
      );
      if (response is List) {
        final bookings = response
            .whereType<Map<String, dynamic>>()
            .map((item) => item['event'])
            .whereType<Map<String, dynamic>>()
            .map((json) {
              final entry = EventEntry.fromJson(json);
              entry.isRegistered = true;
              return entry;
            })
            .toList();
        return bookings;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      rethrow;
    }
  }

  void _refreshData(CookieRequest request) {
    setState(() {
      _eventsFuture = _activeTab == 'bookings'
          ? fetchBookings(request)
          : fetchEvents(request);
    });
  }

  double? _parseFilterPrice(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  double _extractPrice(String rawPrice) {
    final cleaned = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double _extractRating(String rawRating) {
    final cleaned = rawRating.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  List<EventEntry> _applyLocalFilters(List<EventEntry> events) {
    final minPrice = _parseFilterPrice(_minPriceController.text);
    final maxPrice = _parseFilterPrice(_maxPriceController.text);

    var filtered = events.where((event) {
      if (_activeTab == 'created' && !event.isOrganizer) return false;
      if (_activeTab == 'bookings' && !event.isRegistered) return false;
      if (_availableOnly && event.status.toLowerCase() != 'available')
        return false;

      final price = _extractPrice(event.entryPrice);
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;
      return true;
    }).toList();

    int compareDate(EventEntry a, EventEntry b) =>
        b.createdAt.compareTo(a.createdAt);
    int comparePriceAsc(EventEntry a, EventEntry b) =>
        _extractPrice(a.entryPrice).compareTo(_extractPrice(b.entryPrice));
    int comparePriceDesc(EventEntry a, EventEntry b) =>
        _extractPrice(b.entryPrice).compareTo(_extractPrice(a.entryPrice));
    int compareRatingDesc(EventEntry a, EventEntry b) =>
        _extractRating(b.rating).compareTo(_extractRating(a.rating));

    switch (_sortBy) {
      case 'price_low':
        filtered.sort(comparePriceAsc);
        break;
      case 'price_high':
        filtered.sort(comparePriceDesc);
        break;
      case 'rating':
        filtered.sort(compareRatingDesc);
        break;
      default:
        filtered.sort(compareDate);
    }

    return filtered;
  }

  void _onSearchChanged(String value, CookieRequest request) {
    _searchQuery = value;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _refreshData(request);
    });
  }

  void _resetFilters(CookieRequest request) {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _searchQuery = '';
      _selectedSport = '';
      _selectedCity = '';
      _sortBy = 'newest';
      _availableOnly = false;
      _activeTab = 'all';
    });
    _refreshData(request);
  }

  String _priceSummary() {
    final min = _minPriceController.text.trim();
    final max = _maxPriceController.text.trim();
    if (min.isEmpty && max.isEmpty) return 'Filter harga';
    if (min.isNotEmpty && max.isNotEmpty) return 'Rp $min - Rp $max';
    if (min.isNotEmpty) return 'Mulai Rp $min';
    return 'Sampai Rp $max';
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
              final borderColor = highlightError
                  ? Colors.red
                  : const Color(0xFFD7E0EB);
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
                    color: highlightError
                        ? Colors.red
                        : const Color(0xFF182435),
                    width: 1.5,
                  ),
                ),
              );
            }

            void _clearError() {
              if (errorText != null) {
                setStateDialog(() => errorText = null);
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 32,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                          'Filter Harga Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                            final minVal =
                                _parseFilterPrice(_minPriceController.text) ??
                                0;
                            final maxVal =
                                _parseFilterPrice(_maxPriceController.text) ??
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
                            setState(() {});
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

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedSport.isNotEmpty ||
      _selectedCity.isNotEmpty ||
      _availableOnly ||
      _activeTab != 'all' ||
      _minPriceController.text.trim().isNotEmpty ||
      _maxPriceController.text.trim().isNotEmpty;

  Future<void> _openCoachShortcut() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachEntryListPage()),
    );
  }

  Future<void> _deleteEvent(
    CookieRequest request, {
    required EventEntry event,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus event?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final decoded = await request.post(
        EventConfig.resolve('/event/json/${event.id}/delete/'),
        {},
      );
      final success = decoded is Map && decoded['success'] == true;
      final message = _stringifyMessage(
        (decoded is Map ? decoded['message'] : null) ??
            'Gagal menghapus event.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? null : Colors.red,
        ),
      );

      if (success) {
        _refreshData(request);
      }
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Respon tidak valid: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<EventEntry?> _fetchEventDetailForEdit(
    CookieRequest request, {
    required String eventId,
  }) async {
    try {
      final response = await request.get(
        EventConfig.resolve('/event/json/$eventId/'),
      );
      if (response is Map) {
        return EventEntry.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint('Failed to fetch event detail for edit: $e');
    }
    return null;
  }

  Future<void> _openEditEvent(EventEntry event, CookieRequest request) async {
    // Prefer fresh detail but fallback to existing data
    EventEntry? detailed =
        await _fetchEventDetailForEdit(request, eventId: event.id) ?? event;
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventForm(event: detailed!)),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event berhasil diperbarui.")),
      );
      _refreshData(request);
    }
  }

  Future<void> _openEventDetail(EventEntry event, CookieRequest request) async {
    final parsedId = int.tryParse(event.id) ?? 0;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(eventId: parsedId),
      ),
    );
    if (changed == true && mounted) {
      _refreshData(request);
    }
  }

  Future<void> _navigateToAddEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEventForm()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Event berhasil dibuat!")));
      _refreshData(context.read<CookieRequest>());
    }
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
        title: const Text(
          "Events",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_added_outlined),
            onPressed: () {
              setState(() => _activeTab = 'bookings');
              _refreshData(request);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(request),
        child: FutureBuilder<List<EventEntry>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            final children = <Widget>[_buildFilterCard(request)];

            if (snapshot.connectionState == ConnectionState.waiting) {
              children.add(
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: children,
              );
            }

            if (snapshot.hasError) {
              children.add(
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load events\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _refreshData(request),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: children,
              );
            }

            final events = snapshot.data ?? [];
            final filteredEvents = _applyLocalFilters(events);

            if (events.isEmpty) {
              children.addAll(const [
                SizedBox(height: 80),
                Center(child: Text("Tidak ada event ditemukan di PWS.")),
              ]);
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: children,
              );
            }

            if (filteredEvents.isEmpty) {
              children.add(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildResultHeader(0, request),
                      Container(
                        padding: const EdgeInsets.all(18),
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
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Tidak ada event yang cocok dengan filter.",
                              style: TextStyle(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Coba hapus filter harga/kota atau cari olahraga lain.",
                              style: TextStyle(color: Color(0xFF6B7280)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _resetFilters(request),
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reset semua filter"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: children,
              );
            }

            children.addAll([
              _buildResultHeader(filteredEvents.length, request),
              ...filteredEvents.map(
                (event) => Column(
                  children: [
                    EventCard(
                      event: event,
                      onTap: () => _openEventDetail(event, request),
                    ),
                    if (event.isOrganizer)
                      _buildOrganizerQuickActions(event, request),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ]);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12),
              children: children,
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultHeader(int count, CookieRequest request) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Menampilkan $count event",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasActiveFilters
                            ? "Filter aktif sedang diterapkan."
                            : "Menampilkan semua event tanpa filter tambahan.",
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton.icon(
                    onPressed: () => _resetFilters(request),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF182435),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
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
                      DropdownMenuItem(value: 'newest', child: Text('Terbaru')),
                      DropdownMenuItem(
                        value: 'price_low',
                        child: Text('Harga terendah'),
                      ),
                      DropdownMenuItem(
                        value: 'price_high',
                        child: Text('Harga tertinggi'),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: Text('Rating tertinggi'),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _sortBy = val ?? 'newest'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openCoachShortcut,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF182435)),
                      foregroundColor: const Color(0xFF182435),
                      backgroundColor: const Color(0xFFF8FAFD),
                    ),
                    icon: const Icon(Icons.diversity_3),
                    label: const Text('Cari Coach'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Butuh pendamping latihan? Lanjutkan ke halaman Coach untuk menemukan pelatih yang sesuai dengan sport dan kota pilihan.",
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerQuickActions(EventEntry event, CookieRequest request) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 120,
            child: OutlinedButton.icon(
              onPressed: () => _deleteEvent(request, event: event),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: OutlinedButton.icon(
              onPressed: () => _openEditEvent(event, request),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(CookieRequest request) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
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
          const Center(
            child: Column(
              children: [
                Text(
                  "FIND YOUR PERFECT EVENT",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Color(0xFF0F1A2C),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Temukan event olahraga terbaik untuk kamu",
                  style: TextStyle(color: Color(0xFF7A869A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari event atau lokasi...",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF8293A7),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('', request);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7E0EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB5D38C),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (val) => _onSearchChanged(val, request),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _navigateToAddEvent,
                icon: const Icon(Icons.add, color: Color(0xFF182435)),
                label: const Text(
                  "ADD EVENT",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF182435),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB7DC81),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCity.isEmpty ? '' : _selectedCity,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Semua kota'),
                    ),
                    ...EventHelpers.cities
                        .map(
                          (city) =>
                              DropdownMenuItem(value: city, child: Text(city)),
                        )
                        .toList(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Kota',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _selectedCity = val ?? '');
                    _refreshData(request);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openPriceFilterSheet,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: Color(0xFFB7DC81)),
                    foregroundColor: const Color(0xFF182435),
                    backgroundColor: const Color(0xFFF8FAFD),
                  ),
                  icon: const Icon(Icons.price_change),
                  label: Text(_priceSummary(), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                        _buildSportChip('', "All"),
                        ...EventHelpers.sportTypes.map(
                          (sport) => _buildSportChip(
                            sport["value"] ?? "",
                            sport["label"] ?? "",
                          ),
                        ),
                      ]
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: w,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildTabPill(
                      "All",
                      "all",
                      onTap: () {
                        setState(() => _activeTab = 'all');
                        _refreshData(request);
                      },
                    ),
                    _buildTabPill(
                      "My Bookings",
                      "bookings",
                      onTap: () {
                        setState(() => _activeTab = 'bookings');
                        _refreshData(request);
                      },
                    ),
                    _buildTabPill(
                      "Created Events",
                      "created",
                      onTap: () {
                        setState(() => _activeTab = 'created');
                        _refreshData(request);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _availableOnly = !_availableOnly);
                  _refreshData(request);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _availableOnly,
                        onChanged: (val) {
                          setState(() => _availableOnly = val ?? false);
                          _refreshData(request);
                        },
                        activeColor: const Color(0xFFB7DC81),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Tersedia saja",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6C7B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _resetFilters(request),
              icon: const Icon(Icons.refresh),
              label: const Text("Reset filter"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5F6C7B),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportChip(String value, String label) {
    final selected = _selectedSport == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFB7DC81),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF182435) : const Color(0xFF3A4A5A),
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        setState(() => _selectedSport = value);
        _refreshData(context.read<CookieRequest>());
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? const Color(0xFFB7DC81) : const Color(0xFFCBD5E1),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTabPill(String label, String key, {VoidCallback? onTap}) {
    final selected = _activeTab == key;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB7DC81) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB7DC81).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
          border: Border.all(
            color: selected ? const Color(0xFFB7DC81) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF182435) : const Color(0xFF556575),
          ),
        ),
      ),
    );
  }

  String _stringifyMessage(dynamic message) {
    if (message == null) return '';
    if (message is String) return message;
    if (message is List) return message.join(', ');
    return message.toString();
  }
}
