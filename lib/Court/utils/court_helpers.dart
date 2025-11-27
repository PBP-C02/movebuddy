// lib/court/utils/court_helpers.dart

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CourtHelpers {
  static Future<void>? _localeInit;

  /// Ensure locale data is loaded for Indonesian date formatting
  static Future<void> ensureLocaleData() {
    _localeInit ??= initializeDateFormatting('id_ID', null);
    return _localeInit!;
  }

  /// Format price to Indonesian Rupiah format
  static String formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  /// Format rating to 1 decimal place
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Format date to Indonesian format
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  /// Format date to short format
  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  /// Format date to ISO format for API
  static String formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.pow(math.sin(dLat / 2), 2).toDouble() +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2).toDouble();
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Format distance to readable string
  static String formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Get sport icon based on sport type
  static String getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'tennis':
        return '🎾';
      case 'basketball':
        return '🏀';
      case 'soccer':
        return '⚽';
      case 'badminton':
        return '🏸';
      case 'volleyball':
        return '🏐';
      case 'futsal':
        return '⚽';
      case 'table_tennis':
        return '🏓';
      case 'paddle':
        return '🎾';
      default:
        return '🏟️';
    }
  }

  /// List of all sport types
  static const List<Map<String, String>> sportTypes = [
    {'value': 'tennis', 'label': 'Tennis'},
    {'value': 'basketball', 'label': 'Basketball'},
    {'value': 'soccer', 'label': 'Soccer'},
    {'value': 'badminton', 'label': 'Badminton'},
    {'value': 'volleyball', 'label': 'Volleyball'},
    {'value': 'futsal', 'label': 'Futsal'},
    {'value': 'table_tennis', 'label': 'Table Tennis'},
    {'value': 'paddle', 'label': 'Paddle'},
  ];

  /// List of Indonesian cities
  static const List<String> cities = [
    'Jakarta',
    'Surabaya',
    'Bandung',
    'Medan',
    'Bekasi',
    'Semarang',
    'Tangerang',
    'Depok',
    'Palembang',
    'South Tangerang',
    'Makassar',
    'Denpasar',
    'Yogyakarta',
    'Balikpapan',
    'Pontianak',
    'Batam',
    'Banjarmasin',
    'Malang',
  ];

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon wajib diisi';
    }

    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 8) {
      return 'Nomor telepon terlalu pendek';
    }

    if (digits.length > 20) {
      return 'Nomor telepon terlalu panjang';
    }

    return null;
  }

  /// Sanitize phone number (remove non-digits)
  static String sanitizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  /// Validate price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harga wajib diisi';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Harga harus berupa angka';
    }

    if (price < 0) {
      return 'Harga tidak boleh negatif';
    }

    return null;
  }

  /// Validate rating
  static String? validateRating(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Rating is optional
    }

    final rating = double.tryParse(value);
    if (rating == null) {
      return 'Rating harus berupa angka';
    }

    if (rating < 1 || rating > 5) {
      return 'Rating harus antara 1 dan 5';
    }

    return null;
  }

  /// Parse coordinates from Google Maps link
  static Map<String, double?>? parseMapCoordinates(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      // Pattern 1: ?q=lat,lng
      final qPattern = RegExp(r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
      final qMatch = qPattern.firstMatch(url);
      if (qMatch != null) {
        return {
          'latitude': double.parse(qMatch.group(1)!),
          'longitude': double.parse(qMatch.group(2)!),
        };
      }

      // Pattern 2: @lat,lng,zoom
      final atPattern = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*),');
      final atMatch = atPattern.firstMatch(url);
      if (atMatch != null) {
        return {
          'latitude': double.parse(atMatch.group(1)!),
          'longitude': double.parse(atMatch.group(2)!),
        };
      }

      // Pattern 3: !3dlat!4dlng
      final bangPattern = RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)');
      final bangMatch = bangPattern.firstMatch(url);
      if (bangMatch != null) {
        return {
          'latitude': double.parse(bangMatch.group(1)!),
          'longitude': double.parse(bangMatch.group(2)!),
        };
      }

      return null;
    } catch (e) {
      developer.log('Error parsing coordinates: $e', name: 'CourtHelpers');
      return null;
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in the future
  static bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  /// Get minimum selectable date (today)
  static DateTime getMinDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get maximum selectable date (90 days from now)
  static DateTime getMaxDate() {
    return DateTime.now().add(const Duration(days: 90));
  }
}
