import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/survey_result_storage.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';
import 'edit_user_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserProfile _profile = const UserProfile();
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await UserStorage.load();
    final uid = await UserStorage.getOrCreateUid();
    await SurveyResultStorage.loadCurrentUserLatestResult();
    if (mounted) {
      setState(() {
        _profile = profile ?? const UserProfile();
        _uid = uid;
      });
    }
  }

  Future<void> _copyUid(String uid) async {
    await Clipboard.setData(ClipboardData(text: uid));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UID 已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Y2KScaffold(
      dots: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildHero(),
              const SizedBox(height: 22),
              _buildUidCard(),
              const SizedBox(height: 12),
              _buildInfoCard(
                indexLabel: '01',
                title: '基础信息',
                accent: Y2K.lime,
                content: _profile.basicInfo,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                indexLabel: '02',
                title: '详细信息',
                accent: Y2K.blue,
                content: _profile.detailedInfo,
                icon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 12),
              _buildPassingScoreCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Y2KChip(
          label: '← 返回',
          background: Colors.transparent,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        Y2KButton(
          label: '编辑',
          icon: Icons.edit_outlined,
          kind: Y2KButtonKind.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          fontSize: 13,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditUserPage(profile: _profile)),
          ).then((_) => _loadData()),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROFILE · 我的资料', style: Y2K.mono.copyWith(color: Y2K.muted)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Y2K.pink,
                shape: BoxShape.circle,
                border: Border.all(color: Y2K.ink, width: 2),
                boxShadow: Y2K.shadow(offset: 4),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, color: Colors.white, size: 38),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '你的档案',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: Y2K.ink, height: 1),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: const [
                      Y2KChip(label: '本地加密'),
                      Y2KChip(label: 'UID · UNIQUE', background: Y2K.lime),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUidCard() {
    return Y2KCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Y2K.gold,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Y2K.ink, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.tag_rounded, size: 20, color: Y2K.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UID', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                const SizedBox(height: 2),
                Text(
                  _uid.isEmpty ? '...' : _uid,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Y2K.ink,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Y2KButton(
            label: '复制',
            icon: Icons.copy_rounded,
            kind: Y2KButtonKind.dark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fontSize: 12,
            onPressed: _uid.isEmpty ? null : () => _copyUid(_uid),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String indexLabel,
    required String title,
    required Color accent,
    required String content,
    required IconData icon,
  }) {
    final isEmpty = content.trim().isEmpty;
    return Y2KCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Y2K.ink, width: 1.5),
                ),
                child: Text(
                  indexLabel,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: accent == Y2K.blue ? Colors.white : Y2K.ink,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: Y2K.ink),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Y2K.ink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Y2KDashedDivider(),
          const SizedBox(height: 12),
          Text(
            isEmpty ? '未填写' : content,
            style: TextStyle(
              fontSize: 14.5,
              color: isEmpty ? Y2K.muted : Y2K.ink2,
              height: 1.6,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassingScoreCard() {
    final score = _profile.passingScore;

    return Y2KCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Y2K.pink,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Y2K.ink, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '合格分数',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Y2K.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  score == null ? '未设置' : '答题达 $score 分视为合格',
                  style: Y2K.bodyMuted,
                ),
              ],
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Y2K.ink,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Y2K.ink, width: 2),
              ),
              child: Text(
                '$score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Y2K.lime,
                  letterSpacing: -0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
