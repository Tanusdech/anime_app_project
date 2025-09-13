// lib/pages/anime_edit_form.dart

import 'dart:io'; // เพิ่มบรรทัดนี้
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../models/anime.dart';
import '../providers/anime_providers.dart';

class AnimeEditForm extends ConsumerStatefulWidget {
  final Anime anime;
  const AnimeEditForm({super.key, required this.anime});

  @override
  ConsumerState<AnimeEditForm> createState() => _AnimeEditFormState();
}

class _AnimeEditFormState extends ConsumerState<AnimeEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _yearController;
  late TextEditingController _genreController;
  late TextEditingController _descriptionController;
  late TextEditingController _episodeController;
  late TextEditingController _seasonController;
  double _rating = 0.0;

  XFile? _pickedImage;
  bool _isSubmitting = false;

  final cloudinary = CloudinaryPublic('dkl67w9p3', 'anime_upload', cache: false);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.anime.title);
    _yearController = TextEditingController(text: widget.anime.year.toString());
    _genreController = TextEditingController(text: widget.anime.genre);
    _descriptionController = TextEditingController(text: widget.anime.description);
    _episodeController = TextEditingController(text: widget.anime.episode.toString());
    _seasonController = TextEditingController(text: widget.anime.season.toString());
    _rating = widget.anime.rating;
  }

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

  Future<String> _uploadImage(XFile file) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('อัปโหลดภาพล้มเหลว: $e');
      return widget.anime.imageUrl; // fallback
    }
  }

  Future<void> _onUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String imageUrl = widget.anime.imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
    }

    final updatedAnime = widget.anime.copyWith(
      title: _titleController.text.trim(),
      year: _yearController.text.trim(),
      genre: _genreController.text.trim(),
      description: _descriptionController.text.trim(),
      episode: int.tryParse(_episodeController.text.trim()) ?? 0,
      season: int.tryParse(_seasonController.text.trim()) ?? 0,
      rating: double.parse(_rating.toStringAsFixed(2)),
      imageUrl: imageUrl,
    );

    try {
      await ref.read(animeControllerProvider.notifier).updateAnime(updatedAnime);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลเรียบร้อย')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')));
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

  Widget _buildImagePreview() {
    if (_pickedImage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_pickedImage!.path), // <-- ใช้งาน File ได้แล้ว
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (widget.anime.imageUrl.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.anime.imageUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('แก้ไข Anime',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildImagePreview(),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'ชื่อเรื่อง'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อเรื่อง' : null,
                    ),
                    const SizedBox(height: 8),
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
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(labelText: 'ปี'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _genreController,
                      decoration: const InputDecoration(labelText: 'ประเภท'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                      maxLines: 2,
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _onUpdate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('บันทึกการแก้ไข', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
