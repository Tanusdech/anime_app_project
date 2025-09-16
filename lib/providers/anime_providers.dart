// lib/providers/anime_providers.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anime.dart';
import '../repositories/anime_repository.dart';

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository();
});

final animeListProvider = StreamProvider.autoDispose<List<Anime>>((ref) {
  return ref.watch(animeRepositoryProvider).getAnimeStream();
});

class AnimeController extends AsyncNotifier<void> {
  late final AnimeRepository repository;

  @override
  Future<void> build() async {
    repository = ref.watch(animeRepositoryProvider);
  }

  /// เพิ่ม Anime
  Future<void> addAnime(Anime anime, {File? imageFile}) async {
    state = const AsyncLoading();
    try {
      print('Controller: addAnime called for ${anime.title}');
      await repository.addAnime(anime, imageFile: imageFile);
      print('Controller: addAnime completed successfully');
      state = const AsyncData(null);
    } catch (e, st) {
      print('Controller AddAnime error: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// แก้ไข Anime (รองรับเปลี่ยน Document ID)
  Future<void> updateAnime(
    Anime anime, {
    File? imageFile,
    String? previousDocId,
  }) async {
    state = const AsyncLoading();
    try {
      if (anime.title.isEmpty) {
        throw Exception('Anime title ว่าง ไม่สามารถอัปเดตได้');
      }

      print('Controller: updateAnime called for ${anime.title}');
      print('Controller: imageFile path: ${imageFile?.path ?? "No new image"}');

      await repository.updateAnime(
        anime,
        imageFile: imageFile,
        previousDocId: previousDocId,
      );

      print('Controller: updateAnime completed successfully');
      state = const AsyncData(null);
    } catch (e, st) {
      print('Controller UpdateAnime error: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// ลบ Anime
  Future<void> deleteAnime(Anime anime) async {
    state = const AsyncLoading();
    try {
      print('Controller: deleteAnime called for ${anime.title}');
      await repository.deleteAnime(anime);
      print('Controller: deleteAnime completed successfully');
      state = const AsyncData(null);
    } catch (e, st) {
      print('Controller DeleteAnime error: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final animeControllerProvider = AsyncNotifierProvider<AnimeController, void>(
  () => AnimeController(),
);
