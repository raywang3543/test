import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart';
import '../theme/y2k_theme.dart';

class SplashPage extends StatefulWidget {
  final Widget nextPage;

  const SplashPage({super.key, this.nextPage = const HomePage()});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 3100), () {
      _controller.duration = const Duration(milliseconds: 500);
      _controller.reverse().then((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => widget.nextPage),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Y2K.bg,
      body: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('icon_source.png', width: 60, height: 60),
              const SizedBox(height: 24),
              const Text('Pulse', style: Y2K.displayMd),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Y2K.pink,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
