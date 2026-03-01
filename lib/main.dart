import 'package:flutter/material.dart';
import 'models/survey_model.dart';
import 'pages/create_survey_page.dart';
import 'pages/answer_survey_page.dart';
import 'pages/user_profile_page.dart';
import 'services/survey_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '情感测试',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F6BED)),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Survey? _survey;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    final survey = await SurveyStorage.load();
    if (mounted) setState(() => _survey = survey);
  }

  void _goToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSurveyPage()),
    ).then((_) => _loadSurvey());
  }

  void _goToAnswer() {
    if (_survey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先创建情感测试'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnswerSurveyPage(survey: _survey!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            centerTitle: true,
            backgroundColor: colorScheme.primary,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                ),
                icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                tooltip: '个人信息',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, size: 72, color: Colors.white30),
                      SizedBox(height: 10),
                      Text(
                        '情感测试',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '欢迎使用情感测试系统',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '创建测试题目，探索你的情感世界',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _FeatureCard(
                    icon: Icons.edit_note_rounded,
                    color: colorScheme.primary,
                    title: '创建测试',
                    description: '添加题目，设置选项内容与分数，支持单选和多选',
                    onTap: _goToCreate,
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.play_circle_outline_rounded,
                    color: _survey != null ? Colors.pink.shade400 : Colors.grey.shade400,
                    title: '开始测试',
                    description: _survey != null
                        ? '共 ${_survey!.questions.length} 题，点击开始答题'
                        : '暂无测试内容，请先创建测试',
                    onTap: _goToAnswer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
