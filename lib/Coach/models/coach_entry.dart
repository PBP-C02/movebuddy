import 'dart:convert';

List<Coach> coachFromJson(String str) =>
    List<Coach>.from(json.decode(str).map((x) => Coach.fromJson(x)));

String coachToJson(List<Coach> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Coach {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? categoryDisplay;
  final String location;
  final String address;
  final int price;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double rating;
  final bool isBooked;
  final String userId;
  final String userName;
  final String userPhone;
  final String whatsappLink;
  final String formattedPhone;
  final String? imageUrl;
  final String instagramLink;
  final String mapsLink;
  final bool isOwner;
  final String? participantId;
  final String? participantName;
  final bool bookedByMe;

  const Coach({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.categoryDisplay,
    required this.location,
    required this.address,
    required this.price,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rating,
    required this.isBooked,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.whatsappLink,
    required this.formattedPhone,
    this.imageUrl,
    required this.instagramLink,
    required this.mapsLink,
    this.isOwner = false,
    this.participantId,
    this.participantName,
    this.bookedByMe = false,
  });

  factory Coach.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final pesertaId = json['peserta_id']?.toString();
    final ownerId = (json['user_id'] ?? '').toString();
    final isOwnerById =
        currentUserId != null && ownerId.isNotEmpty && ownerId == currentUserId;
    return Coach(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      categoryDisplay: json['category_display'],
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      price: _parseInt(json['price']),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      startTime: json['startTime'] ?? json['start_time'] ?? '',
      endTime: json['endTime'] ?? json['end_time'] ?? '',
      rating: _parseDouble(json['rating']),
      isBooked: json['isBooked'] ?? json['is_booked'] ?? false,
      userId: ownerId,
      userName: json['user_name'] ?? '',
      userPhone:
          (json['user_phone'] ?? json['phone'] ?? json['contact_phone'] ?? '')
              .toString(),
      whatsappLink: (json['whatsapp_link'] ??
              json['whatsappLink'] ??
              json['whatsapp'] ??
              '')
          .toString(),
      formattedPhone:
          (json['formatted_phone'] ?? json['formattedPhone'] ?? '').toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      instagramLink:
          (json['instagram_link'] ?? json['instagramLink'] ?? json['instagram'] ?? '')
              .toString(),
      mapsLink: (json['mapsLink'] ??
              json['maps_link'] ??
              json['maps'] ??
              json['google_maps_link'] ??
              '')
          .toString(),
      isOwner: json['is_owner'] == true ||
          json['isOwner'] == true ||
          isOwnerById,
      participantId: pesertaId,
      participantName: json['peserta_name']?.toString(),
      bookedByMe: json['booked_by_me'] == true ||
          json['is_booked_by_me'] == true ||
          json['bookedByMe'] == true ||
          (pesertaId != null && currentUserId != null && pesertaId == currentUserId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'category_display': categoryDisplay,
        'location': location,
        'address': address,
        'price': price,
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'startTime': startTime,
        'endTime': endTime,
        'rating': rating,
        'isBooked': isBooked,
        'user_id': userId,
        'user_name': userName,
        'user_phone': userPhone,
        'whatsapp_link': whatsappLink,
        'formatted_phone': formattedPhone,
        'image_url': imageUrl,
        'instagram_link': instagramLink,
        'mapsLink': mapsLink,
        'is_owner': isOwner,
        'peserta_id': participantId,
        'peserta_name': participantName,
        'booked_by_me': bookedByMe,
      };

  Coach copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? address,
    int? price,
    DateTime? date,
    String? startTime,
    String? endTime,
    double? rating,
    bool? isBooked,
    String? userId,
    String? userName,
    String? userPhone,
    String? whatsappLink,
    String? formattedPhone,
    String? imageUrl,
    String? instagramLink,
    String? mapsLink,
    bool? isOwner,
    String? participantId,
    String? participantName,
    bool? bookedByMe,
  }) {
    return Coach(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryDisplay: categoryDisplay,
      location: location ?? this.location,
      address: address ?? this.address,
      price: price ?? this.price,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rating: rating ?? this.rating,
      isBooked: isBooked ?? this.isBooked,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      formattedPhone: formattedPhone ?? this.formattedPhone,
      imageUrl: imageUrl ?? this.imageUrl,
      instagramLink: instagramLink ?? this.instagramLink,
      mapsLink: mapsLink ?? this.mapsLink,
      isOwner: isOwner ?? this.isOwner,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      bookedByMe: bookedByMe ?? this.bookedByMe,
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
typedef ProductEntry = Coach;
