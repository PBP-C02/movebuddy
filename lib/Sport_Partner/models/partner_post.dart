import 'dart:convert';

List<PartnerPost> partnerPostFromJson(String str) => List<PartnerPost>.from(json.decode(str).map((x) => PartnerPost.fromJson(x)));

String partnerPostToJson(List<PartnerPost> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PartnerPost {
    String postId;
    String creatorName;
    String creatorId;
    String title;
    String description;
    String category;
    DateTime tanggal;
    String jamMulai;
    String jamSelesai;
    String lokasi;
    int totalParticipants;
    bool isParticipant;

    PartnerPost({
        required this.postId,
        required this.creatorName,
        required this.creatorId,
        required this.title,
        required this.description,
        required this.category,
        required this.tanggal,
        required this.jamMulai,
        required this.jamSelesai,
        required this.lokasi,
        required this.totalParticipants,
        required this.isParticipant,
    });

    factory PartnerPost.fromJson(Map<String, dynamic> json) => PartnerPost(
        postId: json["post_id"],
        creatorName: json["creator_name"] ?? "Unknown",
        creatorId: json["creator_id"].toString(),
        title: json["title"],
        description: json["description"],
        category: json["category"],
        tanggal: DateTime.parse(json["tanggal"]),
        jamMulai: json["jam_mulai"],
        jamSelesai: json["jam_selesai"],
        lokasi: json["lokasi"],
        totalParticipants: json["total_participants"] ?? 0,
        isParticipant: json["is_participant"] ?? false,
    );

    Map<String, dynamic> toJson() => {
        "post_id": postId,
        "title": title,
        "description": description,
        "category": category,
        "tanggal": "${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
        "jam_mulai": jamMulai,
        "jam_selesai": jamSelesai,
        "lokasi": lokasi,
    };
}