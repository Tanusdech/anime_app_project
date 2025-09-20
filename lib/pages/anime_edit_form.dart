// lib/pages/anime_edit_form.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.anime.title);
    _yearController = TextEditingController(text: widget.anime.year);
    _genreController = TextEditingController(text: widget.anime.genre);
    _descriptionController = TextEditingController(
      text: widget.anime.description,
    );
    _episodeController = TextEditingController(
      text: widget.anime.episode.toString(),
    );
    _seasonController = TextEditingController(
      text: widget.anime.season.toString(),
    );
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

  /// ฟังก์ชันคำนวณ Document ID จากชื่อเรื่อง + ซีซั่น + ตอน
  String _generateDocId(Anime anime) {
    final cleanTitle = anime.title.replaceAll(' ', '_');
    return '${cleanTitle}_S${anime.season}_E${anime.episode}';
  }

  Future<void> _onUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    File? imageFile;
    if (_pickedImage != null) {
      imageFile = File(_pickedImage!.path);
    }

    final updatedAnime = widget.anime.copyWith(
      title: _titleController.text.trim(),
      year: _yearController.text.trim(),
      genre: _genreController.text.trim(),
      description: _descriptionController.text.trim(),
      episode: int.tryParse(_episodeController.text.trim()) ?? 0,
      season: int.tryParse(_seasonController.text.trim()) ?? 0,
      rating: double.parse(_rating.toStringAsFixed(1)),
    );

    final oldDocId = widget.anime.id;
    final newDocId = _generateDocId(updatedAnime);

    try {
      await ref
          .read(animeControllerProvider.notifier)
          .updateAnime(
            updatedAnime.copyWith(id: newDocId),
            imageFile: imageFile,
            previousDocId: oldDocId,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลเรียบร้อย')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// ปรับให้รองรับ step 0.5 (ครึ่งดาว)
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
              size: 32,
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
              _rating = double.parse(value.toStringAsFixed(1));
            });
          },
        ),
        Text(
          'คะแนน: ${_rating.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Anime',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.deepPurple,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_pickedImage != null ||
                      widget.anime.imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _pickedImage != null
                          ? Image.file(
                              File(_pickedImage!.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              widget.anime.imageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                size: 48,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('เลือกภาพ'),
                    ),
                  ],
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
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _genreController,
                          decoration: const InputDecoration(
                            labelText: 'ประเภท',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'คำอธิบาย',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        _buildStarRating(),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onUpdate,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('บันทึกการแก้ไข'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lottie overlay loading full screen
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(128, 0, 0, 0),
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
