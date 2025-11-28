import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
// Ganti import ini dengan cara Anda mengambil token di project utama
// import 'package:movebuddy/auth/auth_service.dart'; 

class CourtApiHelper {
  // Ganti URL ini sesuai IP komputer/server Anda
  // Emulator Android: 10.0.2.2:8000
  static const String baseUrl = "http://10.0.2.2:8000"; 

  // Fungsi helper untuk mengambil token auth dari storage/session
  Future<String?> _getToken() async {
    // Implementasi contoh:
    // return await AuthService.getToken();
    return "YOUR_AUTH_TOKEN_HERE"; 
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Authorization": "Bearer $token",
    };
  }

  // --- GET DATA ---

  Future<List<dynamic>> fetchCourts({String query = "", String sport = "", String location = ""}) async {
    final uri = Uri.parse("$baseUrl/court/api/court/search/").replace(queryParameters: {
      'q': query,
      'sport': sport,
      'location': location,
    });

    final headers = await _getHeaders();
    // Tambahkan header Content-Type json biasa untuk GET
    headers['Content-Type'] = "application/json";

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['court']; 
    } else {
      throw Exception("Gagal memuat data court: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> fetchCourtDetail(int id) async {
    final url = "$baseUrl/court/api/court/$id/";
    final headers = await _getHeaders();
    headers['Content-Type'] = "application/json";
    
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('court')) {
        return data['court'];
      }
      throw Exception("Format respon tidak valid");
    } else {
      throw Exception("Gagal memuat detail court");
    }
  }

  Future<bool> checkAvailability(int id, String dateStr) async {
    final uri = Uri.parse("$baseUrl/court/api/court/$id/availability/").replace(queryParameters: {
      'date': dateStr,
    });
    
    final headers = await _getHeaders();
    headers['Content-Type'] = "application/json";

    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['available'] ?? false;
    }
    return false;
  }

  // --- POST DATA (Booking) ---

  Future<Map<String, dynamic>> createBooking(int courtId, String dateStr) async {
    final url = "$baseUrl/court/api/court/bookings/";
    final headers = await _getHeaders();
    headers['Content-Type'] = "application/json";

    final body = json.encode({
      "court_id": courtId,
      "date": dateStr, 
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    final data = json.decode(response.body);
    
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? "Booking gagal");
    }
  }

  // --- MULTIPART REQUESTS (Add & Edit) ---

  Future<bool> addCourt(Map<String, String> fields, File? imageFile) async {
    var uri = Uri.parse("$baseUrl/court/api/court/add/");
    var request = http.MultipartRequest('POST', uri);

    // Header Auth
    final token = await _getToken();
    request.headers['Authorization'] = "Bearer $token";

    // Masukkan semua text fields
    request.fields.addAll(fields);

    // Masukkan File Gambar
    if (imageFile != null) {
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image', 
        stream, 
        length,
        filename: imageFile.path.split('/').last
      );
      request.files.add(multipartFile);
    }

    var response = await request.send();
    
    // Perlu membaca respon body untuk error handling yang baik
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error Add Court: $respStr");
      throw Exception("Gagal menambah lapangan. Cek log.");
    }
  }

  Future<bool> editCourt(int id, Map<String, String> fields, File? imageFile) async {
    // Endpoint edit: /api/court/<id>/edit/
    var uri = Uri.parse("$baseUrl/court/api/court/$id/edit/");
    var request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    request.headers['Authorization'] = "Bearer $token";

    request.fields.addAll(fields);

    if (imageFile != null) {
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image', 
        stream, 
        length,
        filename: imageFile.path.split('/').last
      );
      request.files.add(multipartFile);
    }

    var response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return true;
    } else {
       print("Error Edit Court: $respStr");
       throw Exception("Gagal mengedit lapangan.");
    }
  }

  Future<bool> deleteCourt(int id) async {
    final url = "$baseUrl/court/api/court/$id/delete/";
    final headers = await _getHeaders();
    // Headers standard cukup untuk delete
    final response = await http.post(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Gagal menghapus court");
    }
  }
}