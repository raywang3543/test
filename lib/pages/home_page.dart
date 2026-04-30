import 'package:flutter/material.dart';
import 'create_survey_page.dart';
import 'event_page.dart';
import 'test_list_page.dart';
import 'user_list_page.dart';
import 'user_profile_page.dart';
import '../services/server_config.dart';
import '../services/survey_storage.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasOwnSurvey = false;
  String _thinkMode = 'disabled';

  @override
  void initState() {
    super.initState();
    _checkUserSurvey();
    _loadThinkMode();
  }

  Future<void> _loadThinkMode() async {
    final mode = await ServerConfig.getThinkMode();
    if (mounted) setState(() => _thinkMode = mode);
  }

  Future<void> _setThinkMode(String mode) async {
    await ServerConfig.setThinkMode(mode);
    if (mounted) setState(() => _thinkMode = mode);
  }

  Future<void> _checkUserSurvey() async {
    try {
      final uid = await UserStorage.getOrCreateUid();
      final hasSurvey = await SurveyStorage.hasSurvey(uid);
      if (mounted) setState(() => _hasOwnSurvey = hasSurvey);
    } catch (_) {}
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
    return Y2KScaffold(
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
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Y2KChip(label: 'v2.6 · BETA'),
        const Spacer(),
        _buildThinkModeMenu(),
        const SizedBox(width: 8),
        _iconChip(Icons.event_note_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventPage()),
          );
        }),
        const SizedBox(width: 8),
        _iconChip(Icons.people_outline_rounded, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserListPage()),
          );
        }),
        const SizedBox(width: 8),
        _iconChip(Icons.person_outline_rounded, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfilePage()),
          );
        }),
      ],
    );
  }

  Widget _buildThinkModeMenu() {
    final isEnabled = _thinkMode == 'enabled';
    return PopupMenuButton<String>(
      tooltip: '思考模式',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Y2K.ink, width: 1.5),
      ),
      color: Y2K.card,
      onSelected: _setThinkMode,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'disabled',
          child: Row(
            children: [
              Icon(
                Icons.bolt_outlined,
                size: 18,
                color: _thinkMode == 'disabled' ? Y2K.ink : Y2K.muted,
              ),
              const SizedBox(width: 8),
              Text(
                '快速回复',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _thinkMode == 'disabled'
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: _thinkMode == 'disabled' ? Y2K.ink : Y2K.muted,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'enabled',
          child: Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 18,
                color: _thinkMode == 'enabled' ? Y2K.pink : Y2K.muted,
              ),
              const SizedBox(width: 8),
              Text(
                '深度思考',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _thinkMode == 'enabled'
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: _thinkMode == 'enabled' ? Y2K.pink : Y2K.muted,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isEnabled ? Y2K.pink.withValues(alpha: 0.12) : Y2K.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled ? Y2K.pink : Y2K.ink,
            width: 1.5,
          ),
        ),
        child: Icon(
          isEnabled ? Icons.psychology_outlined : Icons.bolt_outlined,
          size: 18,
          color: isEnabled ? Y2K.pink : Y2K.ink,
        ),
      ),
    );
  }

  Widget _iconChip(IconData icon, VoidCallback onTap) {
    return Material(
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
