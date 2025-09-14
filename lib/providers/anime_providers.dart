// lib/providers/anime_providers.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anime.dart';
import '../repositories/anime_repository.dart';

// Repository provider
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository();
});

// StreamProvider สำหรับดึงรายการแบบเรียลไทม์
final animeListProvider = StreamProvider.autoDispose<List<Anime>>((ref) {
  return ref.watch(animeRepositoryProvider).getAnimeStream();
});

// AsyncNotifier สำหรับจัดการ action (add / delete / update)
class AnimeController extends AsyncNotifier<void> {
  late final AnimeRepository repository;

  @override
  Future<void> build() async {
    repository = ref.watch(animeRepositoryProvider);
  }

  /// เพิ่ม Anime พร้อมรองรับ imageFile
  Future<void> addAnime(Anime anime, {File? imageFile}) async {
    state = const AsyncLoading();
    try {
      await repository.addAnime(anime, imageFile: imageFile);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// ลบ Anime
  Future<void> deleteAnime(Anime anime) async {
    state = const AsyncLoading();
    try {
      await repository.deleteAnime(anime);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// อัปเดต Anime พร้อมรองรับ imageFile
  Future<void> updateAnime(Anime anime, {File? imageFile}) async {
    state = const AsyncLoading();
    try {
      // ตรวจสอบว่า id ไม่ว่าง
      if (anime.id.isEmpty) {
        throw Exception('Anime id ว่าง ไม่สามารถอัปเดตได้');
      }
      await repository.updateAnime(anime, imageFile: imageFile);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// Provider สำหรับ Controller
final animeControllerProvider = AsyncNotifierProvider<AnimeController, void>(
  () {
    return AnimeController();
  },
);
