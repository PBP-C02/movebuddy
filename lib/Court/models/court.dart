// lib/court/models/court.dart

class Court {
  final int id;
  final String name;
  final String sportType;
  final String location;
  final String address;
  final double price;
  final String facilities;
  final double rating;
  final String description;
  final String? imageUrl;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final bool ownedByUser;
  final String? ownerName;
  final String? ownerPhone;

  Court({
    required this.id,
    required this.name,
    required this.sportType,
    required this.location,
    required this.address,
    required this.price,
    required this.facilities,
    required this.rating,
    required this.description,
    this.imageUrl,
    required this.isAvailable,
    this.latitude,
    this.longitude,
    this.distance,
    required this.ownedByUser,
    this.ownerName,
    this.ownerPhone,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'] as int,
      name: json['name'] as String,
      sportType: json['sport_type'] as String,
      location: json['location'] as String,
      address: json['address'] as String? ?? '',
      price: double.parse(json['price'].toString()),
      facilities: json['facilities'] as String? ?? '',
      rating: double.parse(json['rating'].toString()),
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      latitude: json['latitude'] != null 
          ? double.parse(json['latitude'].toString()) 
          : null,
      longitude: json['longitude'] != null 
          ? double.parse(json['longitude'].toString()) 
          : null,
      distance: json['distance'] != null 
          ? double.parse(json['distance'].toString()) 
          : null,
      ownedByUser: json['owned_by_user'] as bool? ?? false,
      ownerName: json['owner_name'] as String?,
      ownerPhone: json['owner_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport_type': sportType,
      'location': location,
      'address': address,
      'price': price,
      'facilities': facilities,
      'rating': rating,
      'description': description,
      'image': imageUrl,
      'is_available': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'owned_by_user': ownedByUser,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
    };
  }

  List<String> get facilitiesList {
    if (facilities.isEmpty) return [];
    return facilities
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
  }

  String get sportDisplayName {
    return sportType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1) 
            : '')
        .join(' ');
  }

  Court copyWith({
    int? id,
    String? name,
    String? sportType,
    String? location,
    String? address,
    double? price,
    String? facilities,
    double? rating,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    double? distance,
    bool? ownedByUser,
    String? ownerName,
    String? ownerPhone,
  }) {
    return Court(
      id: id ?? this.id,
      name: name ?? this.name,
      sportType: sportType ?? this.sportType,
      location: location ?? this.location,
      address: address ?? this.address,
      price: price ?? this.price,
      facilities: facilities ?? this.facilities,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      ownedByUser: ownedByUser ?? this.ownedByUser,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }

  @override
  String toString() {
    return 'Court(id: $id, name: $name, sportType: $sportType, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Court && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}