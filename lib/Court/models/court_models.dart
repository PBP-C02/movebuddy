class Court {
  final int id;
  final String name;
  final String sportType;
  final String location;
  final String address;
  final double price;
  final double rating;
  final String? imageUrl;
  final String facilities;
  final bool isAvailableToday;
  final bool ownedByUser; // Field penting untuk hak akses edit/delete

  Court({
    required this.id,
    required this.name,
    required this.sportType,
    required this.location,
    required this.address,
    required this.price,
    required this.rating,
    this.imageUrl,
    required this.facilities,
    required this.isAvailableToday,
    required this.ownedByUser,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'],
      name: json['name'],
      sportType: json['sport_type'],
      location: json['location'] ?? "",
      address: json['address'] ?? "",
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      imageUrl: json['image'], // Django mengirim URL relatif atau absolute tergantung setting
      facilities: json['facilities'] ?? "",
      isAvailableToday: json['is_available'] ?? false,
      ownedByUser: json['owned_by_user'] ?? false,
    );
  }
}

class CourtDetail {
  final Court basicInfo;
  final String description;
  final String ownerName;
  final String ownerPhone;
  final bool ownedByUser;

  CourtDetail({
    required this.basicInfo,
    required this.description,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownedByUser,
  });

  factory CourtDetail.fromJson(Map<String, dynamic> json) {
    return CourtDetail(
      basicInfo: Court.fromJson(json),
      description: json['description'] ?? "",
      ownerName: json['owner_name'] ?? "",
      ownerPhone: json['owner_phone'] ?? "",
      ownedByUser: json['owned_by_user'] ?? false,
    );
  }
}