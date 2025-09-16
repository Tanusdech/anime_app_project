// lib/repositories/anime_repository.dart

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/anime.dart';

class AnimeRepository {
  final CollectionReference _animeCollection = FirebaseFirestore.instance
      .collection('animes');

  // Cloudinary config
  final String cloudName = 'dkl67w9p3';
  final String uploadPreset = 'anime_upload';
  final String apiKey = '819521121367424';
  final String apiSecret = 'B85Tpz2_jlApzGIociMztXoaa3k';
  final String fallbackImageUrl = 'https://via.placeholder.com/150';

  /// Upload file ไป Cloudinary
  Future<String> _uploadToCloudinary(File? file) async {
    if (file == null) return fallbackImageUrl;

    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final resStr = await response.stream.bytesToString();
      print('Cloudinary response: $resStr');

      if (response.statusCode == 200) {
        final jsonRes = json.decode(resStr);
        return jsonRes['secure_url'] ?? fallbackImageUrl;
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        return fallbackImageUrl;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return fallbackImageUrl;
    }
  }

  /// ลบรูปจาก Cloudinary ด้วย public_id
  Future<void> _deleteFromCloudinary(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || imageUrl == fallbackImageUrl) return;

      // ดึง public_id จาก URL
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      if (segments.isEmpty) return;

      final fileNameWithExt = segments.last;
      final publicId = fileNameWithExt.split('.').first;

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();

      // สร้าง signature ตาม Cloudinary API
      final signatureString =
          'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      final deleteUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );

      final response = await http.post(
        deleteUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      print('Cloudinary delete response: ${response.body}');
    } catch (e) {
      print('Cloudinary delete error: $e');
    }
  }

  /// สร้าง documentId จาก title + season + episode
  String generateDocumentId(Anime anime) {
    final safeTitle = anime.title.isNotEmpty ? anime.title : 'Untitled';
    final safeSeason = anime.season > 0 ? anime.season : 1;
    final safeEpisode = anime.episode > 0 ? anime.episode : 1;
    return '${safeTitle}_S${safeSeason}_E${safeEpisode}';
  }

  /// Add Anime (Cloudinary + custom docId)
  Future<void> addAnime(Anime anime, {File? imageFile}) async {
    print('Repository: addAnime called');
    final imageUrl = await _uploadToCloudinary(imageFile);
    final animeWithImage = anime.copyWith(imageUrl: imageUrl);

    final docId = generateDocumentId(animeWithImage);
    final animeWithId = animeWithImage.copyWith(id: docId);

    print(
      'Adding anime: ${animeWithId.title}, docId: $docId, imageUrl: $imageUrl',
    );

    await _animeCollection.doc(docId).set(animeWithId.toMap());
    print('Anime added to Firestore successfully');
  }

  /// Stream - ดึง Anime แบบเรียลไทม์
  Stream<List<Anime>> getAnimeStream() {
    return _animeCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Anime.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Update Anime (รองรับสร้าง Document ใหม่ + ลบ Document เก่า)
  Future<void> updateAnime(
    Anime anime, {
    File? imageFile,
    String? previousDocId,
  }) async {
    print('Repository: updateAnime called for ${anime.title}');

    final oldDocId =
        previousDocId ??
        (anime.id.isNotEmpty ? anime.id : generateDocumentId(anime));
    final newDocId = generateDocumentId(anime);

    String imageUrl = anime.imageUrl;
    if ((imageUrl.isEmpty || imageUrl == fallbackImageUrl) &&
        oldDocId.isNotEmpty) {
      final oldDoc = await _animeCollection.doc(oldDocId).get();
      if (oldDoc.exists) {
        final data = oldDoc.data() as Map<String, dynamic>;
        imageUrl = data['imageUrl'] ?? fallbackImageUrl;
        print('Fetched old imageUrl from Firestore: $imageUrl');
      }
    }

    if (imageFile != null) {
      imageUrl = await _uploadToCloudinary(imageFile);
    }

    final updatedAnime = anime.copyWith(imageUrl: imageUrl);
    final updatedAnimeWithId = updatedAnime.copyWith(id: newDocId);

    if (oldDocId != newDocId) {
      print('Document ID changed: $oldDocId → $newDocId');
      await _animeCollection.doc(newDocId).set(updatedAnimeWithId.toMap());
      await _animeCollection.doc(oldDocId).delete();
      print('Updated anime with new docId and deleted old doc');
    } else {
      await _animeCollection
          .doc(oldDocId)
          .set(updatedAnimeWithId.toMap(), SetOptions(merge: true));
      print('Updated anime with existing docId');
    }
  }

  /// Delete Anime + ลบรูปจาก Cloudinary
  Future<void> deleteAnime(Anime anime) async {
    final docId = anime.id.isNotEmpty ? anime.id : generateDocumentId(anime);
    print('Deleting anime: ${anime.title}, docId: $docId');

    // ดึง imageUrl ก่อนลบ Document
    String imageUrl = anime.imageUrl;
    if ((imageUrl.isEmpty || imageUrl == fallbackImageUrl) &&
        docId.isNotEmpty) {
      final doc = await _animeCollection.doc(docId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        imageUrl = data['imageUrl'] ?? fallbackImageUrl;
      }
    }

    // ลบรูปจาก Cloudinary
    await _deleteFromCloudinary(imageUrl);

    // ลบ Document Firestore
    await _animeCollection.doc(docId).delete();
    print('Anime deleted successfully');
  }
}
