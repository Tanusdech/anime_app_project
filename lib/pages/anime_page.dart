// lib/pages/anime_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/anime.dart';
import '../providers/anime_providers.dart';

class AnimePage extends ConsumerStatefulWidget {
  const AnimePage({Key? key}) : super(key: key);

  @override
  ConsumerState<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends ConsumerState<AnimePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _episodeController = TextEditingController();
  final _seasonController = TextEditingController();
  double _rating = 0.0;

  XFile? _pickedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _episodeController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _onAdd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    File? imageFile;
    if (_pickedImage != null) {
      imageFile = File(_pickedImage!.path);
    }

    final anime = Anime(
      id: '',
      title: _titleController.text.trim(),
      year: _yearController.text.trim(),
      genre: _genreController.text.trim(),
      description: _descriptionController.text.trim(),
      episode: int.tryParse(_episodeController.text.trim()) ?? 0,
      season: int.tryParse(_seasonController.text.trim()) ?? 0,
      imageUrl: '', // จะถูกแทนด้วย Cloudinary URL ใน repository
      rating: double.parse(_rating.toStringAsFixed(2)),
    );

    try {
      await ref.read(animeControllerProvider.notifier).addAnime(anime, imageFile: imageFile);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('เพิ่มข้อมูลเรียบร้อย')));
      _formKey.currentState!.reset();
      setState(() {
        _pickedImage = null;
        _rating = 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          icon: Icon(
            _rating >= starValue
                ? Icons.star
                : (_rating > starValue - 1 ? Icons.star_half : Icons.star_border),
            color: Colors.amber,
          ),
          onPressed: () => setState(() => _rating = starValue.toDouble()),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animesAsync = ref.watch(animeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่ม Anime'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // ชื่อเรื่อง
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'ชื่อเรื่อง'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อเรื่อง' : null,
                  ),
                  const SizedBox(height: 8),
                  // Episode + Season
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _episodeController,
                          decoration: const InputDecoration(labelText: 'ตอนที่'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _seasonController,
                          decoration: const InputDecoration(labelText: 'ซีซั่น'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ปี
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'ปี'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  // ประเภท
                  TextFormField(
                    controller: _genreController,
                    decoration: const InputDecoration(labelText: 'ประเภท'),
                  ),
                  const SizedBox(height: 8),
                  // คำอธิบาย
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                  ),
                  const SizedBox(height: 8),
                  // ปุ่มเลือกรูป
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('เลือกรูปภาพ'),
                      ),
                      const SizedBox(width: 12),
                      if (_pickedImage != null)
                        Expanded(
                          child: Text(
                            _pickedImage!.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  _buildStarRating(),
                  const SizedBox(height: 12),
                  // ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('บันทึก Anime', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // รายการ Anime
            Expanded(
              child: animesAsync.when(
                data: (animes) {
                  if (animes.isEmpty) return const Center(child: Text('ไม่มีรายการ Anime'));
                  return ListView.builder(
                    itemCount: animes.length,
                    itemBuilder: (context, i) {
                      final a = animes[i];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: a.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    a.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                )
                              : CircleAvatar(
                                  child: Text(
                                    a.title.isNotEmpty ? a.title[0].toUpperCase() : '?',
                                  ),
                                ),
                          title: Text(a.title),
                          subtitle: Text(
                              'ตอนที่ ${a.episode} • ซีซั่น ${a.season} • ${a.genre} • ⭐ ${a.rating.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('ยืนยันการลบ'),
                                  content: Text('ต้องการลบ "${a.title}" หรือไม่?'),
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
                                await ref.read(animeControllerProvider.notifier).deleteAnime(a.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
