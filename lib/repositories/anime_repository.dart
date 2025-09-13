// lib/repositories/anime_repository.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/anime.dart';

class AnimeRepository {
  final CollectionReference _animeCollection =
      FirebaseFirestore.instance.collection('anime');

  // Cloudinary config
  final String cloudName = 'dkl67w9p3';
  final String uploadPreset = 'anime_upload'; // preset ที่สร้างแบบ unsigned
  final String fallbackImageUrl =
      'https://via.placeholder.com/150'; // รูป default ถ้า user ไม่เลือก

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
      return fallbackImageUrl; // fallback ถ้า upload ไม่สำเร็จ
    }
  }

  /// Add Anime (รองรับ Cloudinary)
  Future<void> addAnime(Anime anime, {File? imageFile}) async {
    final imageUrl = await _uploadToCloudinary(imageFile);
    final animeWithImage = anime.copyWith(imageUrl: imageUrl);
    await _animeCollection.add(animeWithImage.toMap());
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
    await _animeCollection.doc(anime.id).update(updatedAnime.toMap());
  }

  /// Delete Anime
  Future<void> deleteAnime(String id) async {
    await _animeCollection.doc(id).delete();
  }
}
