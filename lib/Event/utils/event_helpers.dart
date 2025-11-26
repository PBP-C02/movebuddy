import 'package:intl/intl.dart';

class EventHelpers {
  static String formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  static String formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static String getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'tennis': return '🎾';
      case 'basketball': return '🏀';
      case 'soccer': return '⚽';
      case 'badminton': return '🏸';
      case 'volleyball': return '🏐';
      case 'futsal': return '⚽';
      case 'table_tennis': return '🏓';
      case 'paddle': return '🎾';
      case 'swimming': return '🏊';
      default: return '🏃';
    }
  }

  static const List<Map<String, String>> sportTypes = [
    {'value': 'tennis', 'label': 'Tennis'},
    {'value': 'basketball', 'label': 'Basketball'},
    {'value': 'soccer', 'label': 'Soccer'},
    {'value': 'badminton', 'label': 'Badminton'},
    {'value': 'volleyball', 'label': 'Volleyball'},
    {'value': 'futsal', 'label': 'Futsal'},
    {'value': 'table_tennis', 'label': 'Table Tennis'},
    {'value': 'paddle', 'label': 'Paddle'},
    {'value': 'swimming', 'label': 'Swimming'},
  ];

  static const List<String> cities = [
    'Jakarta', 'Surabaya', 'Bandung', 'Medan', 'Bekasi',
    'Semarang', 'Tangerang', 'Depok', 'Palembang', 'Makassar',
    'Denpasar', 'Yogyakarta', 'Balikpapan', 'Malang', 'Batam',
  ];

  static String getSportDisplayName(String sportType) {
    return sportType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}