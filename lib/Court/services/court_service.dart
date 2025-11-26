// lib/Court/services/court_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/court.dart';
import '../utils/court_helpers.dart';

class CourtService {
  final CookieRequest request;
  final String baseUrl;

  CourtService({
    required this.request,
    String? baseUrl,
  }) : baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'COURT_BASE_URL',
                defaultValue: 'http://127.0.0.1:8000',
              ),
        );

  static String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  String _buildUrl(String path) {
    return '$baseUrl$path';
  }

  /// Get all courts or search with filters
  Future<List<Court>> getAllCourts({
    String? query,
    String? sport,
    String? location,
  }) async {
    try {
      final hasFilters = (query ?? '').isNotEmpty ||
          (sport ?? '').isNotEmpty ||
          (location ?? '').isNotEmpty;

      String url;
      if (hasFilters) {
        final params = <String, String>{};
        if (query != null && query.isNotEmpty) params['q'] = query;
        if (sport != null && sport.isNotEmpty) params['sport'] = sport;
        if (location != null && location.isNotEmpty) params['location'] = location;
        
        final queryString = params.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = _buildUrl('/court/api/court/search/?$queryString');
      } else {
        url = _buildUrl('/court/api/court/');
      }

      final response = await request.get(url);

      if (response == null) {
        throw Exception('Response is null');
      }

      // Handle different response formats
      List<dynamic> courtsRaw;
      if (response is Map) {
        // Response is a map, look for 'Court' or 'court' key
        courtsRaw = (response['Court'] ?? response['court'] ?? []) as List<dynamic>;
      } else if (response is List) {
        // Response is already a list
        courtsRaw = response;
      } else {
        throw Exception('Unexpected response format: ${response.runtimeType}');
      }

      return courtsRaw
          .map((json) => Court.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error in getAllCourts: $e');
      rethrow;
    }
  }

  /// Get single court detail
  Future<Court> getCourtDetail(int courtId) async {
    try {
      final response = await request.get(_buildUrl('/court/api/court/$courtId/'));

      if (response == null) {
        throw Exception('Court not found');
      }

      // Handle response format
      Map<String, dynamic> courtJson;
      if (response is Map) {
        courtJson = (response['court'] ?? response) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response format');
      }

      return Court.fromJson(courtJson);
    } catch (e) {
      print('Error in getCourtDetail: $e');
      rethrow;
    }
  }

  /// Check availability for a specific date
  Future<Map<String, dynamic>> getAvailability(int courtId, DateTime date) async {
    try {
      final dateStr = CourtHelpers.formatDateForApi(date);
      final response = await request.get(
        _buildUrl('/court/api/court/$courtId/availability/?date=$dateStr'),
      );

      if (response == null) {
        throw Exception('Failed to check availability');
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error in getAvailability: $e');
      rethrow;
    }
  }

  /// Set availability for a court on a specific date
  Future<bool> setAvailability(
    int courtId,
    DateTime date,
    bool isAvailable,
  ) async {
    try {
      final response = await request.postJson(
        _buildUrl('/court/api/court/$courtId/availability/set/'),
        jsonEncode({
          'date': CourtHelpers.formatDateForApi(date),
          'is_available': isAvailable,
        }),
      );

      if (response == null) {
        return false;
      }

      return response['success'] == true;
    } catch (e) {
      print('Error in setAvailability: $e');
      rethrow;
    }
  }

  /// Generate WhatsApp booking link
  Future<String> getWhatsAppLink(
    int courtId, {
    String? date,
    String? time,
  }) async {
    try {
      final response = await request.postJson(
        _buildUrl('/court/api/court/whatsapp/link/'),
        jsonEncode({
          'court_id': courtId,
          if (date != null) 'date': date,
          if (time != null) 'time': time,
        }),
      );

      if (response == null || response['success'] != true) {
        throw Exception('Failed to generate WhatsApp link');
      }

      return response['whatsapp_link'] as String;
    } catch (e) {
      print('Error in getWhatsAppLink: $e');
      rethrow;
    }
  }

  /// Delete a court (owner only)
  Future<bool> deleteCourt(int courtId) async {
    try {
      final response = await request.post(
        _buildUrl('/court/api/court/$courtId/delete/'),
        {},
      );

      if (response == null) {
        return false;
      }

      return response['success'] == true;
    } catch (e) {
      print('Error in deleteCourt: $e');
      rethrow;
    }
  }

  /// Add a new court
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
    try {
      final resp = await _multipartCourtRequest(
        path: '/court/api/court/add/',
        fields: {
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
        },
        image: image,
      );
      return resp['success'] == true;
    } catch (e) {
      print('Error in addCourt: $e');
      rethrow;
    }
  }

  /// Edit existing court
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
    try {
      final resp = await _multipartCourtRequest(
        path: '/court/api/court/$courtId/edit/',
        fields: {
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
        },
        image: image,
      );
      return resp['success'] == true;
    } catch (e) {
      print('Error in editCourt: $e');
      rethrow;
    }
  }

  /// Create a booking
  Future<bool> createBooking(int courtId, DateTime date) async {
    try {
      final response = await request.postJson(
        _buildUrl('/court/api/court/bookings/'),
        jsonEncode({
          'court_id': courtId,
          'date': CourtHelpers.formatDateForApi(date),
        }),
      );

      if (response == null) {
        return false;
      }

      return response['success'] == true;
    } catch (e) {
      print('Error in createBooking: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _multipartCourtRequest({
    required String path,
    required Map<String, String> fields,
    File? image,
  }) async {
    final uri = Uri.parse(_buildUrl(path));
    final requestHeaders = <String, String>{};
    final cookieHeader = request.headers['cookie'];
    if (cookieHeader != null) {
      requestHeaders[HttpHeaders.cookieHeader] = cookieHeader;
    }

    final multipartRequest = http.MultipartRequest('POST', uri)
      ..headers.addAll(requestHeaders)
      ..fields.addAll(fields);

    if (image != null) {
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamed = await multipartRequest.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed request (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
