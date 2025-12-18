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

  /// IMPORTANT:
  /// - Jangan pakai trailing slash di baseUrl
  /// - Semua URL dibangun dengan _buildUrl() agar konsisten
  static const String baseUrl = "https://ari-darrell-movebuddy.pbp.cs.ui.ac.id";

  CourtApiHelper(this.request);

  // ----------------------------
  // URL HELPERS
  // ----------------------------

  String _buildUrl(String path) {
    // Pastikan path selalu diawali "/" agar tidak jadi "domaincourt/..."
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }

  /// Build a usable image URL from API value (handles absolute/relative/empty).
  static String resolveImageUrl(
    String? rawUrl, {
    String placeholder =
        "https://u7.uidownload.com/vector/866/424/vector-flat-icon-in-black-and-white-football-field-vector-ai-eps.jpg",
  }) {
    if (rawUrl == null) return placeholder;

    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return placeholder;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    // Relative path dari Django (eg: /media/xxx.jpg atau media/xxx.jpg)
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }

  /// Normalisasi link WhatsApp dari backend supaya selalu bisa di-launch dari Flutter:
  /// - Kalau backend ngasih "wa.me/..." tanpa scheme → jadikan "https://wa.me/..."
  /// - Kalau backend ngasih "api.whatsapp.com/..." tanpa scheme → jadikan "https://api.whatsapp.com/..."
  /// - Kalau sudah "https://..." / "http://..." / "whatsapp://..." → biarkan
  static String? normalizeWhatsappLink(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    final lower = s.toLowerCase();
    if (lower.startsWith('https://') || lower.startsWith('http://') || lower.startsWith('whatsapp://')) {
      return s;
    }

    if (lower.startsWith('wa.me/') || lower.startsWith('api.whatsapp.com/')) {
      return 'https://$s';
    }

    // fallback: coba paksa https (lebih baik daripada return null)
    return 'https://$s';
  }

  // ----------------------------
  // GET DATA
  // ----------------------------

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
        queryString =
            "?${params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}";
      }

      final url = _buildUrl('/court/api/court/search/$queryString');
      final response = await request.get(url);

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

      final message = response is Map ? (response['error'] ?? response['message']) : null;
      throw Exception(message ?? "Gagal memperbarui status ketersediaan");
    } catch (e) {
      throw Exception("Gagal memperbarui status ketersediaan: $e");
    } finally {
      if (csrf != null) {
        request.headers.remove('X-CSRFToken');
      }
    }
  }

  // ----------------------------
  // POST DATA (Booking & CRUD)
  // ----------------------------

  /// Generate link WA dari backend dan normalisasi supaya selalu bisa di-launch dari Flutter.
  Future<String?> generateWhatsappLink(int courtId, {String? dateStr, String? timeStr}) async {
    final payload = jsonEncode({
      "court_id": courtId,
      "date": dateStr,
      "time": timeStr,
    });

    // Coba endpoint yang mungkin ada (kamu sudah pakai csrf_exempt di BE)
    const candidates = [
      '/court/api/court/whatsapp/link/',
      '/court/api/court/whatsapp/',
    ];

    for (final path in candidates) {
      try {
        final response = await request.postJson(_buildUrl(path), payload);

        if (response is Map && response['success'] == true) {
          final raw = (response['whatsapp_link'] ?? response['link'])?.toString();
          final normalized = normalizeWhatsappLink(raw);

          if (kDebugMode) {
            debugPrint('[WA] endpoint=$path raw=$raw normalized=$normalized');
          }

          return normalized;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[WA] endpoint=$path failed: $e');
        }
        // lanjut endpoint berikutnya
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

      if (response is Map && response['success'] == true) {
        return Map<String, dynamic>.from(response);
      } else {
        final msg = (response is Map) ? (response['message'] ?? response['error']) : null;
        throw Exception(msg ?? "Booking gagal");
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
        {},
      );

      return response is Map && response['success'] == true;
    } catch (e) {
      throw Exception("Gagal menghapus court: $e");
    }
  }
}