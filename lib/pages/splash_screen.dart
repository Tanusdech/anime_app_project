// lib/pages/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // เพิ่ม Listener ให้ตรวจสอบเมื่อ animation จบ
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/lottie/CamelCase.json',
          controller: _controller,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            // ตั้งเวลา duration ของ controller ตาม animation
            _controller.duration = composition.duration;
            _controller.forward(); // เริ่มเล่น animation
          },
        ),
      ),
    );
  }
}
