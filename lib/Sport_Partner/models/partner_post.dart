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
    bool isCreator;

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
        required this.isCreator,
    });

    factory PartnerPost.fromJson(Map<String, dynamic> json) => PartnerPost(
        // toString() adalah pengaman. Walaupun backend kirim int, UUID, atau string, ini akan tetap jalan.
        postId: json["post_id"]?.toString() ?? "",
        creatorName: json["creator_name"]?.toString() ?? "Unknown",
        creatorId: json["creator_id"]?.toString() ?? "0",
        title: json["title"]?.toString() ?? "No Title",
        description: json["description"]?.toString() ?? "-",
        category: json["category"]?.toString() ?? "General",
        // Parsing tanggal dengan fallback ke waktu sekarang jika gagal/null
        tanggal: json["tanggal"] != null 
            ? DateTime.tryParse(json["tanggal"].toString()) ?? DateTime.now() 
            : DateTime.now(),
        jamMulai: json["jam_mulai"]?.toString() ?? "00:00",
        jamSelesai: json["jam_selesai"]?.toString() ?? "00:00",
        lokasi: json["lokasi"]?.toString() ?? "-",
        // Pastikan angka benar-benar integer
        totalParticipants: int.tryParse(json["total_participants"]?.toString() ?? "0") ?? 0,
        isParticipant: json["is_participant"] == true,
        isCreator: json["is_creator"] == true,
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