import 'package:flutter/material.dart';
import 'pages/create_survey_page.dart';
import 'pages/event_page.dart';
import 'pages/test_list_page.dart';
import 'pages/user_list_page.dart';
import 'pages/user_profile_page.dart';
import 'services/server_config.dart';
import 'services/survey_storage.dart';
import 'services/user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '性格匹配测试',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF48FB1)),
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
  bool _hasOwnSurvey = false;
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final url = await ServerConfig.getBaseUrl();
    if (url == null || url.isEmpty) {
      if (mounted) await _showServerConfigDialog(canDismiss: false);
    } else {
      setState(() => _serverUrl = url);
    }
    await _checkUserSurvey();
  }

  Future<void> _checkUserSurvey() async {
    try {
      final uid = await UserStorage.getOrCreateUid();
      final hasSurvey = await SurveyStorage.hasSurvey(uid);
      if (mounted) setState(() => _hasOwnSurvey = hasSurvey);
    } catch (_) {}
  }

  Future<void> _showServerConfigDialog({bool canDismiss = true}) async {
    final controller = TextEditingController(text: _serverUrl);
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('服务器地址'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请输入局域网服务器地址（含端口号）',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'http://192.168.x.x:8000',
                  border: const OutlineInputBorder(),
                  errorText: error,
                  prefixIcon: const Icon(Icons.dns_outlined),
                ),
                keyboardType: TextInputType.url,
                autofocus: true,
                onChanged: (_) {
                  if (error != null) setDialogState(() => error = null);
                },
              ),
            ],
          ),
          actions: [
            if (canDismiss)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
            FilledButton(
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isEmpty) {
                  setDialogState(() => error = '请输入服务器地址');
                  return;
                }
                if (!url.startsWith('http')) {
                  setDialogState(() => error = '地址需以 http:// 或 https:// 开头');
                  return;
                }
                await ServerConfig.setBaseUrl(url);
                if (ctx.mounted) {
                  setState(() => _serverUrl = url);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _goToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSurveyPage()),
    ).then((_) => _checkUserSurvey());
  }

  void _goToTestList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TestListPage()),
    );
  }

  Future<void> _deleteOwnSurvey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除您创建的测试题吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = await UserStorage.getOrCreateUid();
      await SurveyStorage.deleteByUid(uid);
      await _checkUserSurvey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测试题已删除'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            leading: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventPage()),
              ),
              icon: const Icon(Icons.event_note_outlined, color: Colors.white),
              tooltip: '事件',
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserListPage()),
                ),
                icon: const Icon(Icons.people_outline_rounded,
                    color: Colors.white),
                tooltip: '用户列表',
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                ),
                icon: const Icon(Icons.person_outline_rounded,
                    color: Colors.white),
                tooltip: '个人信息',
              ),
              IconButton(
                onPressed: () =>
                    _showServerConfigDialog(canDismiss: true),
                icon: const Icon(Icons.dns_outlined, color: Colors.white),
                tooltip: '服务器设置',
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
                      Icon(Icons.psychology_rounded,
                          size: 72, color: Colors.white30),
                      SizedBox(height: 10),
                      Text(
                        '性格匹配测试',
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
                    '欢迎使用性格匹配测试',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '创建测试题目，发现你们的性格契合度',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _FeatureCard(
                    icon: Icons.edit_note_rounded,
                    color: Colors.pink.shade400,
                    title: '新建测试',
                    description: '创建性格匹配题目，设置选项与分数',
                    onTap: _goToCreate,
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.play_circle_outline_rounded,
                    color: Colors.pink.shade400,
                    title: '开始测试',
                    description: '选择性格测试题目，测试你们的匹配程度',
                    onTap: _goToTestList,
                  ),
                  if (_hasOwnSurvey) ...[
                    const SizedBox(height: 16),
                    _FeatureCard(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      title: '删除测试',
                      description: '删除您创建的性格匹配题目',
                      onTap: _deleteOwnSurvey,
                    ),
                  ],
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
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
