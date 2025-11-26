// To parse this JSON data, do
//
//     final coach = coachFromJson(jsonString);

import 'dart:convert';

List<Coach> coachFromJson(String str) => List<Coach>.from(json.decode(str).map((x) => Coach.fromJson(x)));

String coachToJson(List<Coach> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Coach {
    // categoryDisplay is optional label from backend (e.g., get_category_display)
    final String? categoryDisplay;
    String id;
    String title;
    String description;
    String category;
    String location;
    String address;
    int price;
    DateTime date;
    String startTime;
    String endTime;
    int rating;
    bool isBooked;
    String userId;
    String userName;
    String? imageUrl;
    String instagramLink;
    String mapsLink;

    Coach({
        this.categoryDisplay,
        required this.id,
        required this.title,
        required this.description,
        required this.category,
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
        this.imageUrl,
        required this.instagramLink,
        required this.mapsLink,
    });

    factory Coach.fromJson(Map<String, dynamic> json) => Coach(
        categoryDisplay: json["category_display"] as String?,
        id: json["id"]?.toString() ?? "",
        title: json["title"] ?? "",
        description: json["description"] ?? "",
        category: json["category"] ?? "",
        location: json["location"] ?? "",
        address: json["address"] ?? "",
        price: _parseInt(json["price"]),
        date: json["date"] != null ? DateTime.parse(json["date"]) : DateTime.now(),
        startTime: json["startTime"] ?? json["start_time"] ?? "",
        endTime: json["endTime"] ?? json["end_time"] ?? "",
        rating: _parseInt(json["rating"]),
        isBooked: json["isBooked"] ?? json["is_booked"] ?? false,
        userId: json["user_id"]?.toString() ?? "",
        userName: json["user_name"] ?? "",
        imageUrl: json["image_url"],
        instagramLink: json["instagram_link"] ?? "",
        mapsLink: json["mapsLink"] ?? json["maps_link"] ?? "",
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "category": category,
        "location": location,
        "address": address,
        "price": price,
        "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "startTime": startTime,
        "endTime": endTime,
        "rating": rating,
        "isBooked": isBooked,
        "user_id": userId,
        "user_name": userName,
        "image_url": imageUrl,
        "instagram_link": instagramLink,
        "mapsLink": mapsLink,
    };
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
