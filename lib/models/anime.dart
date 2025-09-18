// lib/models/anime.dart

class Anime {
  final String id;
  final String title;
  final int episode;
  final int season;
  final double rating;
  final String year;
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

  /// สร้าง Anime จาก Firestore Map
  factory Anime.fromMap(Map<String, dynamic> map, String documentId) {
    return Anime(
      id: map['id'] != null && map['id'] != '' ? map['id'] : documentId,
      title: map['title'] ?? '',
      episode: map['episode']?.toInt() ?? 1,
      season: map['season']?.toInt() ?? 1,
      rating: (map['rating'] ?? 0.0).toDouble(),
      year: map['year'] ?? '',
      description: map['description'] ?? '',
      genre: map['genre'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  /// แปลง Anime เป็น Map สำหรับส่ง Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  /// copyWith สำหรับสร้าง object ใหม่โดยแก้บาง field
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
