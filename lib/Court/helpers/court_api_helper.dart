import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/court_models.dart';

class CourtApiHelper {
  final CookieRequest request;

  // Gunakan 10.0.2.2 untuk Emulator Android
  // Gunakan IP Laptop (misal 192.168.x.x) untuk HP Fisik
  static const String baseUrl = "http://127.0.0.1:8000";

  CourtApiHelper(this.request);

  String _buildUrl(String path) {
    return '$baseUrl$path';
  }

  // --- GET DATA ---

  Future<List<Court>> fetchCourts({String query = "", String sport = "", String location = ""}) async {
    try {
      // Menyusun Query Parameters
      final params = <String, String>{};
      if (query.isNotEmpty) params['q'] = query;
      if (sport.isNotEmpty) params['sport'] = sport;
      if (location.isNotEmpty) params['location'] = location;
      
      String queryString = "";
      if (params.isNotEmpty) {
        queryString = "?" + params.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
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

  Future<bool> checkAvailability(int id, String dateStr) async {
    try {
      final response = await request.get(
        _buildUrl('/court/api/court/$id/availability/?date=$dateStr'),
      );
      
      if (response != null && response is Map) {
        return response['available'] == true;
      }
      return false;
    } catch (e) {
      return false; 
    }
  }

  // --- POST DATA (Booking & CRUD) ---

  Future<String?> generateWhatsappLink(int courtId, {String? dateStr, String? timeStr}) async {
    try {
      final response = await request.postJson(
        _buildUrl('/court/api/court/whatsapp/'),
        jsonEncode({
          "court_id": courtId,
          "date": dateStr,
          "time": timeStr,
        }),
      );

      if (response is Map && response['success'] == true) {
        return response['whatsapp_link'] ?? response['link'];
      }
    } catch (e) {
      // ignore and return null so caller can fallback
    }
    return null;
  }

  Future<Map<String, dynamic>> _postMultipart(
    String path,
    Map<String, String> fields, {
    File? imageFile,
  }) async {
    await request.init();

    final uri = Uri.parse(_buildUrl(path));
    final multipart = http.MultipartRequest('POST', uri);
    multipart.fields.addAll(fields);

    if (imageFile != null) {
      multipart.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    // Copy existing headers (including cookies) to keep session
    multipart.headers.addAll(Map<String, String>.from(request.headers));

    final streamed = await multipart.send();
    final resp = await http.Response.fromStream(streamed);
    try {
      final data = json.decode(resp.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      // fallthrough to default map below
    }
    return {"success": false, "error": "Invalid response"};
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
  
  Future<bool> addCourt(Map<String, String> fields, {File? imageFile}) async {
    try {
      final response = await _postMultipart('/court/api/court/add/', fields, imageFile: imageFile);

      return response is Map && response['success'] == true;
    } catch (e) {
      print("Error Add Court: $e");
      return false;
    }
  }

  Future<bool> editCourt(int id, Map<String, String> fields, {File? imageFile}) async {
    try {
      final response = await _postMultipart('/court/api/court/$id/edit/', fields, imageFile: imageFile);

      return response is Map && response['success'] == true;
    } catch (e) {
       print("Error Edit Court: $e");
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
