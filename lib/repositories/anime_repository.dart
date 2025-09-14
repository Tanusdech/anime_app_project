// lib/repositories/anime_repository.dart

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/anime.dart';

class AnimeRepository {
  final CollectionReference _animeCollection =
      FirebaseFirestore.instance.collection('animes');

  // Cloudinary config
  final String cloudName = 'dkl67w9p3';
  final String uploadPreset = 'anime_upload'; // unsigned preset
  final String fallbackImageUrl =
      'https://via.placeholder.com/150'; // default image

  /// Upload file ไป Cloudinary
  Future<String> _uploadToCloudinary(File? file) async {
    if (file == null) return fallbackImageUrl;

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final jsonRes = json.decode(resStr);
      return jsonRes['secure_url'] ?? fallbackImageUrl;
    } else {
      return fallbackImageUrl;
    }
  }

  /// Helper: สร้าง documentId ป้องกันข้อมูลซ้ำ
  String _generateDocId(Anime anime) {
    return '${anime.title}_S${anime.season}_E${anime.episode}';
  }

  /// Add Anime (Cloudinary + custom docId)
  Future<void> addAnime(Anime anime, {File? imageFile}) async {
    final imageUrl = await _uploadToCloudinary(imageFile);
    final animeWithImage = anime.copyWith(imageUrl: imageUrl);

    final docId = _generateDocId(animeWithImage);
    await _animeCollection.doc(docId).set(animeWithImage.toMap());
  }

  /// Stream - ดึง Anime แบบเรียลไทม์
  Stream<List<Anime>> getAnimeStream() {
    return _animeCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Anime.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Update Anime
  Future<void> updateAnime(Anime anime, {File? imageFile}) async {
    String imageUrl = anime.imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadToCloudinary(imageFile);
    }
    final updatedAnime = anime.copyWith(imageUrl: imageUrl);

    final docId = _generateDocId(updatedAnime);
    await _animeCollection.doc(docId).update(updatedAnime.toMap());
  }

  /// Delete Anime
  Future<void> deleteAnime(Anime anime) async {
    final docId = _generateDocId(anime);
    await _animeCollection.doc(docId).delete();
  }
}
