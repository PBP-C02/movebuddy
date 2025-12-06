import 'dart:convert';
import 'package:move_buddy/Sport_Partner/constants.dart';

List<EventEntry> eventEntryFromJson(String str) => 
    List<EventEntry>.from(json.decode(str).map((x) => EventEntry.fromJson(x)));

String eventEntryToJson(List<EventEntry> data) => 
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class EventEntry {
  String id;
  String name;
  String sportType;
  String description;
  String city;
  String fullAddress;
  String googleMapsLink;
  String entryPrice;
  String activities;
  String rating;
  String photoUrl;
  String status;
  String category;
  int organizerId;
  String organizerName;
  DateTime createdAt;
  bool isOrganizer;
  bool isRegistered;
  List<EventSchedule>? schedules;
  List<String>? userSchedules;

  EventEntry({
    required this.id,
    required this.name,
    required this.sportType,
    required this.description,
    required this.city,
    required this.fullAddress,
    required this.googleMapsLink,
    required this.entryPrice,
    required this.activities,
    required this.rating,
    required this.photoUrl,
    required this.status,
    required this.category,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
    required this.isOrganizer,
    required this.isRegistered,
    this.schedules,
    this.userSchedules,
  });

  factory EventEntry.fromJson(Map<String, dynamic> json) {
    final rawPhotoUrl = json["photo_url"] ?? "";
    final resolvedPhotoUrl = (rawPhotoUrl.startsWith("http") || rawPhotoUrl.startsWith("data:"))
        ? rawPhotoUrl
        : rawPhotoUrl.isNotEmpty
            ? "$baseUrl$rawPhotoUrl"
            : "";

    return EventEntry(
      id: (json["id"] ?? "").toString(),
      name: json["name"] ?? "",
      sportType: json["sport_type"] ?? "",
      description: json["description"] ?? "",
      city: json["city"] ?? "",
      fullAddress: json["full_address"] ?? "",
      googleMapsLink: json["google_maps_link"] ?? "",
      entryPrice: json["entry_price"]?.toString() ?? "0",
      activities: json["activities"] ?? "",
      rating: json["rating"]?.toString() ?? "0",
      photoUrl: resolvedPhotoUrl,
      status: json["status"] ?? "",
      category: json["category"] ?? "",
      organizerId: _asInt(json["organizer_id"]),
      organizerName: json["organizer_name"] ??
          json["organizer"] ??
          "",
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"]) ?? DateTime.now()
          : DateTime.now(),
      isOrganizer: json["is_organizer"] ?? false,
      isRegistered: json["is_registered"] ?? false,
      schedules: json["schedules"] != null
          ? List<EventSchedule>.from(
              json["schedules"].map((x) => EventSchedule.fromJson(x)))
          : null,
      userSchedules: json["user_schedules"] != null
          ? List<String>.from(json["user_schedules"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "sport_type": sportType,
        "description": description,
        "city": city,
        "full_address": fullAddress,
        "entry_price": entryPrice,
        "activities": activities,
        "rating": rating,
        "status": status,
        "category": category,
      };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class EventSchedule {
  String id;
  DateTime date;

  EventSchedule({
    required this.id,
    required this.date,
  });

  factory EventSchedule.fromJson(Map<String, dynamic> json) => EventSchedule(
        id: json["id"],
        date: DateTime.parse(json["date"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      };
}
