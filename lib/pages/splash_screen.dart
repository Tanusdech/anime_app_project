// lib/pages/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _lottieController;
  bool _showLottie = false;

  @override
  void initState() {
    super.initState();

    // 1️⃣ ตั้งค่า Video Player
    _videoController =
        VideoPlayerController.asset(
            'assets/videos/Illuminated_Circles_Intro_free.mp4',
          )
          ..initialize().then((_) {
            setState(() {});
            _videoController.play();
          });

    // ตรวจสอบเมื่อวิดีโอเล่นจบ
    _videoController.addListener(() {
      if (_videoController.value.isInitialized &&
          !_showLottie &&
          _videoController.value.position >= _videoController.value.duration) {
        // วิดีโอจบ → แสดง Lottie
        setState(() {
          _showLottie = true;
        });
        _videoController.pause();
        _videoController.dispose();

        _playLottieAnimation();
      }
    });
  }

  void _playLottieAnimation() {
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Lottie จบ → ไปหน้า Home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AnimeHomePage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    if (!_showLottie) {
      _videoController.dispose();
    }
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _showLottie
            ? Lottie.asset(
                'assets/lottie/CamelCase.json',
                controller: _lottieController,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                  _lottieController.forward();
                },
              )
            : (_videoController.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                  : const SizedBox.shrink()),
      ),
    );
  }
}
