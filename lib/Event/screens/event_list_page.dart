import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:move_buddy/Event/models/event_entry.dart';
import 'package:move_buddy/Event/screens/event_detail_page.dart';
import 'package:move_buddy/Event/screens/add_event_form.dart';
import 'package:move_buddy/Event/screens/my_bookings_page.dart';
import 'package:move_buddy/Event/widgets/event_card.dart';
import 'package:move_buddy/Event/widgets/event_filter_section.dart';
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
  bool _showFilters = false;

  Future<List<EventEntry>> fetchEvents(CookieRequest request) async {
    final uri = Uri.parse('$baseUrl/event/ajax/search/').replace(queryParameters: {
      if (_selectedSport.isNotEmpty) 'sport': _selectedSport,
      if (_availableOnly) 'available': 'true',
      if (_searchQuery.isNotEmpty) 'search': _searchQuery,
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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedSport = '';
      _selectedCity = '';
      _availableOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'SPORTS EVENTS',
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
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBookingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF84CC16),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventForm()),
          );
          if (result == true) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (_showFilters)
            EventFilterSection(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedSport: _selectedSport,
              selectedCity: _selectedCity,
              availableOnly: _availableOnly,
              onSearchChanged: (value) => setState(() => _searchQuery = value),
              onSportSelected: (value) => setState(() => _selectedSport = value),
              onCitySelected: (value) => setState(() => _selectedCity = value),
              onAvailableOnlyChanged: (value) => setState(() => _availableOnly = value),
              onResetFilters: _resetFilters,
            ),
          Expanded(
            child: FutureBuilder(
              future: fetchEvents(request),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)));
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
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No events found',
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        if (snapshot.data == null)
                          const Text(
                            'Response empty atau tidak terbaca.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Reload'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    EventEntry event = snapshot.data[index];
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
        ],
      ),
    );
  }
}
