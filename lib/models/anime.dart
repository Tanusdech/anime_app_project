// lib/models/anime.dart

class Anime {
  final String id;
  final String title;
  final int episode;       // ตอนที่
  final int season;        // ซีซั่น
  final double rating;     // คะแนน 0.0 - 5.0, ทศนิยม 2 ตำแหน่ง
  final String year;       // ปีที่ออกฉาย (option)
  final String description;
  final String genre;
  final String imageUrl;

  Anime({
    required this.id,
    required this.title,
    required this.episode,
    required this.season,
    required this.rating,
    this.year = '',
    this.description = '',
    this.genre = '',
    this.imageUrl = '',
  });

  // สร้าง Anime จาก Firestore Map
  factory Anime.fromMap(Map<String, dynamic> map, String documentId) {
    return Anime(
      id: documentId,
      title: map['title'] ?? '',
      episode: map['episode'] ?? 0,
      season: map['season'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      year: map['year'] ?? '',
      description: map['description'] ?? '',
      genre: map['genre'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // แปลง Anime เป็น Map สำหรับส่ง Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'episode': episode,
      'season': season,
      'rating': rating,
      'year': year,
      'description': description,
      'genre': genre,
      'imageUrl': imageUrl,
    };
  }

  // copyWith สำหรับสร้าง object ใหม่โดยแก้บาง field
  Anime copyWith({
    String? id,
    String? title,
    int? episode,
    int? season,
    double? rating,
    String? year,
    String? description,
    String? genre,
    String? imageUrl,
  }) {
    return Anime(
      id: id ?? this.id,
      title: title ?? this.title,
      episode: episode ?? this.episode,
      season: season ?? this.season,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
