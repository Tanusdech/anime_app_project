// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/anime_providers.dart';
import 'pages/anime_page.dart';
import 'pages/anime_edit_form.dart';
import 'models/anime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AnimeHomePage(),
    );
  }
}

class AnimeHomePage extends ConsumerWidget {
  const AnimeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animesAsync = ref.watch(animeListProvider);

    Future<void> _showEditDialog(Anime anime) async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: AnimeEditForm(anime: anime),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Anime App Home'),
      ),
      body: animesAsync.when(
        data: (animes) {
          if (animes.isEmpty) return const Center(child: Text('ไม่พบรายการ Anime'));

          return ListView.builder(
            itemCount: animes.length,
            itemBuilder: (context, index) {
              final anime = animes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: anime.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            anime.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        )
                      : CircleAvatar(
                          child: Text(anime.title.isNotEmpty ? anime.title[0].toUpperCase() : '?'),
                        ),
                  title: Text(anime.title),
                  subtitle: Text(
                      'ตอนที่ ${anime.episode} • ซีซั่น ${anime.season} • ${anime.genre} • ⭐ ${anime.rating.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(anime),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content: Text('ต้องการลบ "${anime.title}" หรือไม่?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(c).pop(false),
                                  child: const Text('ยกเลิก'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(c).pop(true),
                                  child: const Text('ลบ'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(animeControllerProvider.notifier).deleteAnime(anime.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnimePage()),
          );
        },
        tooltip: 'Add Anime',
        child: const Icon(Icons.add),
      ),
    );
  }
}
