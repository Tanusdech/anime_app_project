// lib/pages/anime_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import '../models/anime.dart';
import '../providers/anime_providers.dart';
import 'anime_edit_form.dart';

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
    if (_pickedImage != null) imageFile = File(_pickedImage!.path);

    final anime = Anime(
      id: '',
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Untitled',
      episode: int.tryParse(_episodeController.text.trim()) ?? 1,
      season: int.tryParse(_seasonController.text.trim()) ?? 1,
      rating: double.parse(_rating.toStringAsFixed(2)),
      year: _yearController.text.trim(),
      genre: _genreController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: '',
    );

    try {
      await ref
          .read(animeControllerProvider.notifier)
          .addAnime(anime, imageFile: imageFile);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มข้อมูลเรียบร้อย')));
      _formKey.currentState!.reset();
      setState(() {
        _pickedImage = null;
        _rating = 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return Icon(
              _rating >= starValue
                  ? Icons.star
                  : (_rating >= starValue - 0.5
                        ? Icons.star_half
                        : Icons.star_border),
              color: Colors.amber,
            );
          }),
        ),
        Slider(
          value: _rating,
          min: 0,
          max: 5,
          divisions: 10,
          label: _rating.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _rating = double.parse(
                value.toStringAsFixed(1),
              );
            });
          },
        ),
      ],
    );
  }

  void _openEditForm(Anime anime) async {
    setState(() => _isSubmitting = true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnimeEditForm(anime: anime),
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _onDelete(Anime anime) async {
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
      setState(() => _isSubmitting = true);
      try {
        await ref.read(animeControllerProvider.notifier).deleteAnime(anime);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลเรียบร้อย')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final animesAsync = ref.watch(animeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Text(
              'Add Anime',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.save, color: Colors.white),
        //     onPressed: () {
        //       // TODO: ปุ่มนี้เพื่อบันทึก anime ใหม่ (ทางเลือก)
        //     },
        //   ),
        // ],
        elevation: 4,
        shadowColor: Colors.black45,
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อเรื่อง',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกชื่อเรื่อง'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _episodeController,
                              decoration: const InputDecoration(
                                labelText: 'ตอนที่',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _seasonController,
                              decoration: const InputDecoration(
                                labelText: 'ซีซั่น',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'ปีที่ฉาย',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _genreController,
                        decoration: const InputDecoration(labelText: 'ประเภท'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'คำอธิบาย',
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      _buildStarRating(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'บันทึก',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: animesAsync.when(
                    data: (animes) {
                      if (animes.isEmpty) {
                        return Center(
                          child: Lottie.asset(
                            'assets/lottie/No_Data_Animation.json',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
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
                                            const Icon(
                                              Icons.image_not_supported,
                                            ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      child: Text(
                                        a.title.isNotEmpty
                                            ? a.title[0].toUpperCase()
                                            : '?',
                                      ),
                                    ),
                              title: Text(a.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ตอนที่ ${a.episode} • ซีซั่น ${a.season} • ${a.genre}',
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(a.rating.toStringAsFixed(2)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _openEditForm(a),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _onDelete(a),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => Center(
                      child: Lottie.asset(
                        'assets/lottie/loading.json',
                        width: 150,
                        height: 150,
                        repeat: true,
                      ),
                    ),
                    error: (e, st) => Center(
                      child: Lottie.asset(
                        'assets/lottie/Error_Animation.json',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha((0.5 * 255).round()),
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/loading.json',
                    width: 150,
                    height: 150,
                    repeat: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
