// lib/court/services/court_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/court.dart';
import '../utils/court_helpers.dart';

class CourtService {
  CourtService({
    http.Client? client,
    String? baseUrl,
    String? sessionId,
    String? csrfToken,
  })  : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl),
        _sessionId = sessionId,
        _csrfToken = csrfToken;

  static const String _defaultBaseUrl =
      'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id';

  final http.Client _client;
  final String _baseUrl;
  String? _sessionId;
  String? _csrfToken;

  String get baseUrl => _baseUrl;
  String? get sessionId => _sessionId;
  String? get csrfToken => _csrfToken;

  static String _normalizeBaseUrl(String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) return _defaultBaseUrl;
    return baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }

  Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (params == null) return uri;
    return uri.replace(queryParameters: params);
  }

  Map<String, String> _headers({bool json = true, bool withCsrf = false}) {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (json) headers[HttpHeaders.contentTypeHeader] = 'application/json';

    final cookieParts = <String>[];
    if (_sessionId != null) cookieParts.add('sessionid=$_sessionId');
    if (_csrfToken != null) cookieParts.add('csrftoken=$_csrfToken');
    if (cookieParts.isNotEmpty) {
      headers[HttpHeaders.cookieHeader] = cookieParts.join('; ');
    }
    if (withCsrf && _csrfToken != null) {
      headers['X-CSRFToken'] = _csrfToken!;
    }
    return headers;
  }

  void _captureCookies(http.BaseResponse response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;

    final sessionMatch = RegExp(r'sessionid=([^;]+)').firstMatch(setCookie);
    final csrfMatch = RegExp(r'csrftoken=([^;]+)').firstMatch(setCookie);

    if (sessionMatch != null) {
      _sessionId = sessionMatch.group(1);
    }
    if (csrfMatch != null) {
      _csrfToken = csrfMatch.group(1);
    }
  }

  void _ensureCsrfToken() {
    if (_csrfToken == null) {
      throw Exception('CSRF token is missing. Call login() first.');
    }
  }

  void hydrateSession({
    String? sessionId,
    String? csrfToken,
  }) {
    _sessionId = sessionId ?? _sessionId;
    _csrfToken = csrfToken ?? _csrfToken;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final loginUri = _uri('/login/');

    // Prefetch CSRF token cookie
    final csrfResp = await _client.get(loginUri);
    _captureCookies(csrfResp);

    final response = await _client.post(
      loginUri,
      headers: _headers(withCsrf: true),
      body: jsonEncode({'email': email, 'password': password}),
    );
    _captureCookies(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      return true;
    }
    throw Exception(body['message'] ?? 'Login failed (${response.statusCode})');
  }

  Future<void> logout() async {
    final response = await _client.get(
      _uri('/logout/'),
      headers: _headers(json: false),
    );
    if (response.statusCode == 200) {
      _sessionId = null;
      _csrfToken = null;
      return;
    }
    throw Exception('Logout failed (${response.statusCode})');
  }

  Future<List<Court>> getAllCourts({
    String? query,
    String? sport,
    String? location,
  }) async {
    final hasFilters = (query ?? '').isNotEmpty ||
        (sport ?? '').isNotEmpty ||
        (location ?? '').isNotEmpty;

    final uri = hasFilters
        ? _uri('/court/api/court/search/', {
            if (query != null && query.isNotEmpty) 'q': query,
            if (sport != null && sport.isNotEmpty) 'sport': sport,
            if (location != null && location.isNotEmpty) 'location': location,
          })
        : _uri('/court/api/court/');

    final response = await _client.get(uri, headers: _headers(json: false));
    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to load courts (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final listKey = hasFilters ? 'court' : 'Court';
    final courtsRaw = data[listKey] as List<dynamic>? ?? [];

    return courtsRaw
        .map((json) => Court.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Court> getCourtDetail(int courtId) async {
    final response = await _client.get(
      _uri('/court/api/court/$courtId/'),
      headers: _headers(json: false),
    );
    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to load court ($courtId)');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final courtJson = data['court'] as Map<String, dynamic>;
    return Court.fromJson(courtJson);
  }

  Future<Map<String, dynamic>> getAvailability(int courtId, DateTime date) async {
    final response = await _client.get(
      _uri('/court/api/court/$courtId/availability/', {
        'date': CourtHelpers.formatDateForApi(date),
      }),
      headers: _headers(json: false),
    );

    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to check availability (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> setAvailability(
    int courtId,
    DateTime date,
    bool isAvailable,
  ) async {
    _ensureCsrfToken();

    final response = await _client.post(
      _uri('/court/api/court/$courtId/availability/set/'),
      headers: _headers(withCsrf: true),
      body: jsonEncode({
        'date': CourtHelpers.formatDateForApi(date),
        'is_available': isAvailable,
      }),
    );

    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to update availability (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final successValue = data['success'];
    return successValue == true ||
        successValue?.toString().toLowerCase() == 'true';
  }

  Future<String> getWhatsAppLink(
    int courtId, {
    String? date,
    String? time,
  }) async {
    final response = await _client.post(
      _uri('/court/api/court/whatsapp/link/'),
      headers: _headers(),
      body: jsonEncode({
        'court_id': courtId,
        if (date != null) 'date': date,
        if (time != null) 'time': time,
      }),
    );

    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to generate WhatsApp link (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true && data['whatsapp_link'] != null) {
      return data['whatsapp_link'] as String;
    }
    throw Exception(data['error'] ?? 'Cannot build WhatsApp link');
  }

  Future<bool> deleteCourt(int courtId) async {
    _ensureCsrfToken();

    final response = await _client.post(
      _uri('/court/api/court/$courtId/delete/'),
      headers: _headers(withCsrf: true),
    );

    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete court (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  Future<bool> addCourt({
    required String name,
    required String sportType,
    required String location,
    required String address,
    required double pricePerHour,
    required String ownerPhone,
    String? facilities,
    double? rating,
    String? description,
    File? image,
    String? mapsLink,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/court/api/court/add/'),
    );

    request.headers.addAll(_headers(json: false));
    request.fields.addAll({
      'name': name,
      'sport_type': sportType,
      'location': location,
      'address': address,
      'price_per_hour': pricePerHour.toString(),
      'owner_phone': ownerPhone,
      'facilities': facilities ?? '',
      'rating': (rating ?? 0).toString(),
      'description': description ?? '',
      'maps_link': mapsLink ?? '',
    });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final response = await http.Response.fromStream(await request.send());
    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Gagal menambahkan lapangan (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['success'] == true;
  }

  Future<bool> editCourt({
    required int courtId,
    required String name,
    required String sportType,
    required String location,
    required String address,
    required double pricePerHour,
    required String ownerPhone,
    String? facilities,
    double? rating,
    String? description,
    File? image,
    String? mapsLink,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/court/api/court/$courtId/edit/'),
    );

    request.headers.addAll(_headers(json: false));
    request.fields.addAll({
      'name': name,
      'sport_type': sportType,
      'location': location,
      'address': address,
      'price_per_hour': pricePerHour.toString(),
      'owner_phone': ownerPhone,
      'facilities': facilities ?? '',
      'rating': (rating ?? 0).toString(),
      'description': description ?? '',
      'maps_link': mapsLink ?? '',
    });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final response = await http.Response.fromStream(await request.send());
    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Gagal memperbarui lapangan (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['success'] == true;
  }

  Future<bool> createBooking(int courtId, DateTime date) async {
    _ensureCsrfToken();

    final response = await _client.post(
      _uri('/court/api/court/bookings/'),
      headers: _headers(withCsrf: true),
      body: jsonEncode({
        'court_id': courtId,
        'date': CourtHelpers.formatDateForApi(date),
      }),
    );

    _captureCookies(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to create booking (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['success'] == true;
  }

  void dispose() {
    _client.close();
  }
}
