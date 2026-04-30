import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';


/// 用户详情页面 - 显示指定用户的个人信息（只读）
class UserDetailPage extends StatefulWidget {
  final String uid;
  final UserProfile profile;
  final int? lastScore;

  const UserDetailPage({
    super.key,
    required this.uid,
    required this.profile,
    this.lastScore,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late UserProfile _profile;
  late String _uid;
  int? _lastScore;
  bool _showDetailedInfo = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _uid = widget.uid;
    _lastScore = widget.lastScore;
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final currentUid = await UserStorage.getCurrentUid();
    if (currentUid == null) return;

    final db = DatabaseHelper();
    final events =
        await db.getEventsByAnswererAndCreatorUid(currentUid, _uid);

    if (events.isEmpty) return;

    final score = events.first['totalScore'] as int;
    final passingScore = _profile.passingScore;
    final passed = passingScore == null || score >= passingScore;

    if (mounted) {
      setState(() {
        _lastScore = score;
        _showDetailedInfo = passed;
      });
    }
  }

  Future<void> _copyUid(String uid) async {
    await Clipboard.setData(ClipboardData(text: uid));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UID 已复制到剪贴板'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final passingScore = _profile.passingScore;
    final isPassed = _lastScore != null &&
        passingScore != null &&
        _lastScore! >= passingScore;

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
              _buildHero(isPassed: isPassed),
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
              if (_showDetailedInfo)
                _buildInfoCard(
                  indexLabel: '02',
                  title: '详细信息',
                  accent: Y2K.blue,
                  content: _profile.detailedInfo,
                  icon: Icons.info_outline_rounded,
                )
              else
                _buildLockedCard(),
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
        const Y2KChip(label: 'READ ONLY', background: Y2K.gold),
      ],
    );
  }

  Widget _buildHero({required bool isPassed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROFILE · 用户详情', style: Y2K.mono.copyWith(color: Y2K.muted)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: isPassed ? Y2K.lime : Y2K.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Y2K.ink, width: 2),
                boxShadow: Y2K.shadow(offset: 4),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person,
                color: isPassed ? Y2K.ink : Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '他的档案',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: Y2K.ink,
                        height: 1),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_lastScore != null)
                        Y2KChip(
                          label: '你的得分 · $_lastScore',
                          background: Y2K.pink,
                          foreground: Colors.white,
                        ),
                      if (isPassed)
                        const Y2KChip(label: 'PASSED', background: Y2K.lime),
                      if (_lastScore != null && !isPassed)
                        const Y2KChip(label: 'LOCKED', background: Y2K.gold),
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
                  _uid,
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
            onPressed: () => _copyUid(_uid),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Y2K.ink),
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

  Widget _buildLockedCard() {
    final passingScore = _profile.passingScore;
    final hint = _lastScore == null
        ? '完成 TA 的测试才能解锁详细信息'
        : '你的 $_lastScore 分还不够 · 需要 $passingScore 分';

    return Y2KCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Y2K.ink,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Y2K.ink, width: 1.5),
                ),
                child: const Text(
                  '02',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Y2K.gold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.lock_outline_rounded, size: 18, color: Y2K.ink),
              const SizedBox(width: 8),
              const Text(
                '详细信息 · LOCKED',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Y2K.ink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Y2KDashedDivider(),
          const SizedBox(height: 12),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 14.5,
              color: Y2K.ink2,
              height: 1.6,
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
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Y2K.ink),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
