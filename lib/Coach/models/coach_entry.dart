// To parse this JSON data, do
//
//     final coach = coachFromJson(jsonString);

import 'dart:convert';

List<Coach> coachFromJson(String str) => List<Coach>.from(json.decode(str).map((x) => Coach.fromJson(x)));

String coachToJson(List<Coach> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Coach {
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
        id: json["id"] ?? "",
        title: json["title"] ?? "",
        description: json["description"] ?? "",
        category: json["category"] ?? "",
        location: json["location"] ?? "",
        address: json["address"] ?? "",
        price: json["price"] ?? 0,
        date: json["date"] != null ? DateTime.parse(json["date"]) : DateTime.now(),
        startTime: json["startTime"] ?? "",
        endTime: json["endTime"] ?? "",
        rating: json["rating"] ?? 0,
        isBooked: json["isBooked"] ?? false,
        userId: json["user_id"] ?? "",
        userName: json["user_name"] ?? "",
        imageUrl: json["image_url"],
        instagramLink: json["instagram_link"] ?? "",
        mapsLink: json["mapsLink"] ?? "",
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
