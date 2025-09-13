import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/anime.dart';

class AnimeRepository {
  final CollectionReference _animeCollection =
      FirebaseFirestore.instance.collection('anime');

  // Add
  Future<void> addAnime(Anime anime) async {
    await _animeCollection.add(anime.toMap());
  }

  // Stream
  Stream<List<Anime>> getAnimeStream() {
    return _animeCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Anime.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Update
  Future<void> updateAnime(Anime anime) async {
    await _animeCollection.doc(anime.id).update(anime.toMap());
  }

  // Delete
  Future<void> deleteAnime(String id) async {
    await _animeCollection.doc(id).delete();
  }
}
