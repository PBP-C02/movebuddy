import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/court_models.dart';

class CourtAvailability {
  final bool available;
  final bool canManage;

  CourtAvailability({
    required this.available,
    required this.canManage,
  });

  factory CourtAvailability.fromJson(Map<dynamic, dynamic> json) {
    return CourtAvailability(
      available: json['available'] == true,
      canManage: json['can_manage'] == true,
    );
  }
}

class CourtApiHelper {
  final CookieRequest request;

  // Gunakan 10.0.2.2 untuk Emulator Android
  // Gunakan IP Laptop (misal 192.168.x.x) untuk HP Fisik
  static const String baseUrl = "https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/";

  CourtApiHelper(this.request);

  /// Build a usable image URL from API value (handles absolute/relative/empty).
  static String resolveImageUrl(
    String? rawUrl, {
    String placeholder = "https://via.placeholder.com/150",
  }) {
    if (rawUrl == null) return placeholder;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return placeholder;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    // Assume relative path from Django (eg: /media/xxx.jpg or media/xxx.jpg)
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }

  String _buildUrl(String path) {
    return '$baseUrl$path';
  }

  // --- GET DATA ---

  Future<List<Court>> fetchCourts({
    String query = "",
    String sport = "",
    String location = "",
    String sort = "",
    String minPrice = "",
    String maxPrice = "",
    String minRating = "",
    String latitude = "",
    String longitude = "",
  }) async {
    try {
      // Menyusun Query Parameters
      final params = <String, String>{};
      if (query.isNotEmpty) params['q'] = query;
      if (sport.isNotEmpty) params['sport'] = sport;
      if (location.isNotEmpty) params['location'] = location;
      if (sort.isNotEmpty) params['sort'] = sort;
      if (minPrice.isNotEmpty) params['min_price'] = minPrice;
      if (maxPrice.isNotEmpty) params['max_price'] = maxPrice;
      if (minRating.isNotEmpty) params['min_rating'] = minRating;
      if (latitude.isNotEmpty) params['lat'] = latitude;
      if (longitude.isNotEmpty) params['lng'] = longitude;
      
      String queryString = "";
      if (params.isNotEmpty) {
        queryString = "?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}";
      }

      final url = _buildUrl('/court/api/court/search/$queryString');
      final response = await request.get(url);

      // Parsing respon dari Django
      List<dynamic> listJson;
      if (response is Map && response.containsKey('court')) {
         listJson = response['court'];
      } else if (response is List) {
         listJson = response;
      } else {
         listJson = []; 
      }

      return listJson.map((json) => Court.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Gagal memuat data court: $e");
    }
  }

  Future<CourtDetail> fetchCourtDetail(int id) async {
    try {
      final response = await request.get(_buildUrl('/court/api/court/$id/'));
      
      if (response is Map) {
         // Handle struktur json yg mungkin dibungkus key 'court' atau langsung objek
         final data = response.containsKey('court') ? response['court'] : response;
         return CourtDetail.fromJson(data);
      } else {
        throw Exception("Format respon detail tidak valid");
      }
    } catch (e) {
      throw Exception("Gagal memuat detail court: $e");
    }
  }

  Future<CourtAvailability> fetchAvailabilityStatus(int id, String dateStr) async {
    try {
      final response = await request.get(
        _buildUrl('/court/api/court/$id/availability/?date=${Uri.encodeComponent(dateStr)}'),
      );

      if (response is Map) {
        return CourtAvailability.fromJson(response);
      }
      throw Exception("Format respon availability tidak valid");
    } catch (e) {
      throw Exception("Gagal memuat status ketersediaan: $e");
    }
  }

  Future<bool> checkAvailability(int id, String dateStr) async {
    final status = await fetchAvailabilityStatus(id, dateStr);
    return status.available;
  }

  Future<bool> setAvailability(int id, {required String dateStr, required bool isAvailable}) async {
    final csrf = request.cookies['csrftoken']?.value;
    if (csrf != null && csrf.isNotEmpty) {
      request.headers['X-CSRFToken'] = csrf;
    }
    try {
      final response = await request.postJson(
        _buildUrl('/court/api/court/$id/availability/set/'),
        jsonEncode({
          "date": dateStr,
          "is_available": isAvailable,
        }),
      );

      if (response is Map && response['success'] == true) {
        return response['available'] == true;
      }
      final message = response is Map ? response['error'] ?? response['message'] : null;
      throw Exception(message ?? "Gagal memperbarui status ketersediaan");
    } catch (e) {
      throw Exception("Gagal memperbarui status ketersediaan: $e");
    } finally {
      if (csrf != null) {
        request.headers.remove('X-CSRFToken');
      }
    }
  }

  // --- POST DATA (Booking & CRUD) ---

  Future<String?> generateWhatsappLink(int courtId, {String? dateStr, String? timeStr}) async {
    final payload = jsonEncode({
      "court_id": courtId,
      "date": dateStr,
      "time": timeStr,
    });

    // Coba endpoint csrf-exempt lebih dulu
    for (final path in ['/court/api/court/whatsapp/link/', '/court/api/court/whatsapp/']) {
      try {
        final response = await request.postJson(_buildUrl(path), payload);
        if (response is Map && response['success'] == true) {
          return response['whatsapp_link'] ?? response['link'];
        }
      } catch (e) {
        // lanjut coba endpoint lain
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> createBooking(int courtId, String dateStr) async {
    try {
      final response = await request.postJson(
        _buildUrl('/court/api/court/bookings/'),
        jsonEncode({
          "court_id": courtId,
          "date": dateStr, 
        }),
      );
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? "Booking gagal");
      }
    } catch (e) {
      throw Exception("Gagal booking: $e");
    }
  }
  
  Future<bool> addCourt(Map<String, String> fields) async {
    try {
      final response = await request.post(
        _buildUrl('/court/api/court/add/'),
        fields,
      );

      return response is Map && response['success'] == true;
    } catch (e) {
      debugPrint("Error Add Court: $e");
      return false;
    }
  }

  Future<bool> editCourt(int id, Map<String, String> fields) async {
    try {
      final response = await request.post(
        _buildUrl('/court/api/court/$id/edit/'),
        fields,
      );

      return response is Map && response['success'] == true;
    } catch (e) {
       debugPrint("Error Edit Court: $e");
       return false;
    }
  }

  Future<bool> deleteCourt(int id) async {
    try {
      final response = await request.post(
        _buildUrl('/court/api/court/$id/delete/'),
        {}, // Body kosong
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception("Gagal menghapus court: $e");
    }
  }
}
