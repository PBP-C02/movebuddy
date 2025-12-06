import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/models/event_entry.dart';
import 'package:move_buddy/Event/screens/event_detail_page.dart';
import 'package:move_buddy/Event/screens/add_event_form.dart';
import 'package:move_buddy/Event/screens/my_bookings_page.dart';
import 'package:move_buddy/Event/widgets/event_card.dart';
import 'package:move_buddy/Event/utils/event_helpers.dart';
import 'package:move_buddy/Sport_Partner/constants.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSport = '';
  String _selectedCity = '';
  bool _availableOnly = false;
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
    super.dispose();
  }

  Future<List<EventEntry>> fetchEvents(CookieRequest request) async {
    final uri = Uri.parse('$baseUrl/event/ajax/search/').replace(queryParameters: {
      if (_selectedSport.isNotEmpty) 'sport': _selectedSport,
      if (_availableOnly) 'available': 'true',
      if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      if (_selectedCity.isNotEmpty) 'city': _selectedCity,
    });

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

  void _refreshData(CookieRequest request) {
    setState(() {
      _eventsFuture = fetchEvents(request);
    });
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
      _searchQuery = '';
      _selectedSport = '';
      _selectedCity = '';
      _availableOnly = false;
      _activeTab = 'all';
    });
    _refreshData(request);
  }

  Future<void> _navigateToAddEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEventForm()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event berhasil dibuat!")),
      );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBookingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterCard(request),
      Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshData(request),
              child: FutureBuilder<List<EventEntry>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load events\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _refreshData(request),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text("Tidak ada event ditemukan.")),
                      ],
                    );
                  }

                  var events = snapshot.data!;
                  if (_activeTab == 'created') {
                    events = events.where((e) => e.isOrganizer).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventCard(
                        event: event,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailPage(eventId: event.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
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
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF8293A7)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7E0EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB5D38C), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSportChip('', "All"),
                ...EventHelpers.sportTypes.map((sport) => _buildSportChip(
                      sport["value"] ?? "",
                      sport["label"] ?? "",
                    )),
              ].map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList(),
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
                    _buildTabPill("All", "all", onTap: () {
                      setState(() => _activeTab = 'all');
                      _refreshData(request);
                    }),
                    _buildTabPill("My Bookings", "bookings", onTap: () async {
                      setState(() => _activeTab = 'bookings');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyBookingsPage()),
                      );
                    }),
                    _buildTabPill("Created Events", "created", onTap: () {
                      setState(() => _activeTab = 'created');
                    }),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Tersedia saja",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6C7B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        side: BorderSide(color: selected ? const Color(0xFFB7DC81) : const Color(0xFFCBD5E1)),
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
}
