import 'package:flutter/material.dart';
import 'pages/create_survey_page.dart';
import 'pages/event_page.dart';
import 'pages/test_list_page.dart';
import 'pages/user_list_page.dart';
import 'pages/user_profile_page.dart';
import 'services/onboarding_service.dart';
import 'services/server_config.dart';
import 'services/survey_storage.dart';
import 'services/user_storage.dart';
import 'theme/y2k_theme.dart';
import 'theme/y2k_widgets.dart';
import 'widgets/onboarding_overlay.dart';

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
  String _thinkMode = 'disabled';
  int _onboardingStep = 0; // 0 = hidden, 1-3 = active step

  final GlobalKey _createCardKey = GlobalKey();
  final GlobalKey _profileIconKey = GlobalKey();
  final GlobalKey _eventIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    String? url = await ServerConfig.getBaseUrl();
    if (url == null || url.isEmpty) {
      await ServerConfig.setBaseUrl(ServerConfig.defaultUrl);
      url = ServerConfig.defaultUrl;
    }
    final thinkMode = await ServerConfig.getThinkMode();
    setState(() {
      _serverUrl = url!;
      _thinkMode = thinkMode;
    });
    await _checkUserSurvey();
    if (await OnboardingService.shouldShow()) {
      await OnboardingService.markDone();
      if (mounted) setState(() => _onboardingStep = 1);
    }
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
    String tempThinkMode = _thinkMode;

    await showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '服务器地址',
                style: TextStyle(fontSize: 13, color: Y2K.muted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'http://192.168.x.x:8000',
                  errorText: error,
                  prefixIcon: const Icon(Icons.dns_outlined, color: Y2K.ink),
                ),
                keyboardType: TextInputType.url,
                autofocus: true,
                onChanged: (_) {
                  if (error != null) setDialogState(() => error = null);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'AI 模式',
                style: TextStyle(fontSize: 13, color: Y2K.muted),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tempThinkMode,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.psychology_outlined, color: Y2K.ink),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'disabled',
                    child: Text('快速'),
                  ),
                  DropdownMenuItem(
                    value: 'enabled',
                    child: Text('思考'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => tempThinkMode = value);
                  }
                },
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            if (canDismiss)
              Y2KButton(
                label: '取消',
                kind: Y2KButtonKind.ghost,
                onPressed: () => Navigator.pop(ctx),
              ),
            Y2KButton(
              label: '确定',
              kind: Y2KButtonKind.primary,
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
                await ServerConfig.setThinkMode(tempThinkMode);
                if (ctx.mounted) {
                  setState(() {
                    _serverUrl = url;
                    _thinkMode = tempThinkMode;
                  });
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _advanceOnboarding(int fromStep) {
    if (_onboardingStep != fromStep) return;
    setState(() {
      _onboardingStep = fromStep >= 3 ? 0 : fromStep + 1;
    });
  }

  void _skipOnboarding() {
    setState(() => _onboardingStep = 0);
  }

  void _goToCreate() {
    _advanceOnboarding(1);
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
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          Y2KButton(
            label: '取消',
            kind: Y2KButtonKind.ghost,
            onPressed: () => Navigator.pop(context, false),
          ),
          Y2KButton(
            label: '删除',
            kind: Y2KButtonKind.accent,
            customBg: Y2K.danger,
            onPressed: () => Navigator.pop(context, true),
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
          const SnackBar(content: Text('测试题已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Y2KScaffold(
      dots: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 28),
              _buildHero(),
              const SizedBox(height: 20),
              _buildStatBadge(),
              const SizedBox(height: 20),
              _FeatureCard(
                key: _createCardKey,
                index: '01',
                title: '新建测试',
                description: '创建性格匹配题目，设置选项与分数',
                accent: Y2K.lime,
                icon: Icons.edit_note_rounded,
                onTap: _goToCreate,
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                index: '02',
                title: '开始测试',
                description: '选择测试题目，测试你们的匹配程度',
                accent: Y2K.blue,
                foreground: Colors.white,
                icon: Icons.play_arrow_rounded,
                onTap: _goToTestList,
              ),
              if (_hasOwnSurvey) ...[
                const SizedBox(height: 12),
                _FeatureCard(
                  index: '03',
                  title: '删除测试',
                  description: '移除您创建的性格匹配题目',
                  accent: Y2K.danger,
                  foreground: Colors.white,
                  icon: Icons.delete_outline_rounded,
                  onTap: _deleteOwnSurvey,
                ),
              ],
              const SizedBox(height: 26),
              const Y2KMarquee(
                text: 'MATCH  ✦  CONNECT  ✦  DISCOVER  ✦  Y2K  ✦  2026',
              ),
            ],
          ),
        ),
      ),
    );

    if (_onboardingStep == 0) return scaffold;

    final steps = {
      1: (
        _createCardKey,
        Y2K.lime,
        false,
        'STEP 1 / 3 · 新建测试',
        '出一道属于你的题',
        '点击进入 → AI 生成题目 → 保存发布',
      ),
      2: (
        _profileIconKey,
        Y2K.pink,
        true,
        'STEP 2 / 3 · 你的档案',
        '完善你的个人信息',
        '进入档案 → 编辑资料 → 保存',
      ),
      3: (
        _eventIconKey,
        Y2K.blue,
        true,
        'STEP 3 / 3 · 答题记录',
        '查看答题记录',
        '查看别人对你测试的结果',
      ),
    };

    final s = steps[_onboardingStep]!;

    return Stack(
      children: [
        scaffold,
        OnboardingOverlay(
          step: _onboardingStep,
          targetKey: s.$1,
          accentColor: s.$2,
          isCircle: s.$3,
          stepLabel: s.$4,
          title: s.$5,
          subtitle: s.$6,
          onSkip: _skipOnboarding,
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Y2KChip(label: 'v2.6 · BETA'),
        const Spacer(),
        _iconChip(Icons.event_note_outlined, () {
          _advanceOnboarding(3);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventPage()),
          );
        }, key: _eventIconKey),
        const SizedBox(width: 8),
        _iconChip(Icons.people_outline_rounded, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserListPage()),
          );
        }),
        const SizedBox(width: 8),
        _iconChip(Icons.person_outline_rounded, () {
          _advanceOnboarding(2);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfilePage()),
          );
        }, key: _profileIconKey),
        const SizedBox(width: 8),
        _iconChip(Icons.dns_outlined, () => _showServerConfigDialog()),
      ],
    );
  }

  Widget _iconChip(IconData icon, VoidCallback onTap, {Key? key}) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Y2K.card,
            shape: BoxShape.circle,
            border: Border.all(color: Y2K.ink, width: 1.5),
          ),
          child: Icon(icon, size: 18, color: Y2K.ink),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性格 · 匹配 · 测试',
          style: Y2K.mono.copyWith(color: Y2K.muted),
        ),
        const SizedBox(height: 14),
        const Text(
          '你们是',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            height: 0.95,
            letterSpacing: -1.6,
            color: Y2K.ink,
          ),
        ),
        const Text(
          '怎样的',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            height: 0.95,
            letterSpacing: -1.6,
            color: Y2K.ink,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Y2KHighlight(text: '灵魂搭档？', fontSize: 52),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          '出题 · 作答 · 解析匹配度，\n用直觉发现彼此。',
          style: Y2K.bodyMuted,
        ),
      ],
    );
  }

  Widget _buildStatBadge() {
    return Y2KCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Y2K.blue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Y2K.ink, width: Y2K.borderWidth),
            ),
            alignment: Alignment.center,
            child: const Sparkle(size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已有很多人在用这里测彼此',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'TOP · 最近活跃 · 本地安全',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Y2K.muted,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String index;
  final String title;
  final String description;
  final Color accent;
  final Color foreground;
  final IconData icon;
  final VoidCallback? onTap;

  const _FeatureCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.foreground = Y2K.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Y2KCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Y2K.ink, width: Y2K.borderWidth),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: foreground, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      index,
                      style: Y2K.monoSm.copyWith(color: Y2K.pink, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Y2K.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Y2K.ink2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 20, color: Y2K.ink),
        ],
      ),
    );
  }
}
