import 'package:flutter/material.dart';
import 'pages/splash_page.dart';
import 'theme/y2k_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: Y2K.theme(),
      home: const SplashPage(),
    );
  }
}


