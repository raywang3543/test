import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';
import '../utils/uid_utils.dart';
import 'user_detail_page.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool _isLoading = true;
  List<_EventItem> _completedMine = [];
  List<_EventItem> _iCompleted = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final currentUid = await UserStorage.getCurrentUid();
    final db = DatabaseHelper();

    if (currentUid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final creatorEvents = await db.getEventsByCreatorUid(currentUid);
    final Map<String, Map<String, dynamic>> answererMap = {};
    for (final e in creatorEvents) {
      final uid = e['answererUid'] as String;
      if (uid == currentUid) continue;
      if (!answererMap.containsKey(uid)) answererMap[uid] = e;
    }

    final answererEvents = await db.getEventsByAnswererUid(currentUid);
    final Map<String, Map<String, dynamic>> creatorMap = {};
    for (final e in answererEvents) {
      final uid = e['creatorUid'] as String;
      if (uid == currentUid) continue;
      if (!creatorMap.containsKey(uid)) creatorMap[uid] = e;
    }

    Future<_EventItem> toItem(String uid, int totalScore) async {
      final info = await db.getUserInfo(uid);
      final profile = info != null
          ? UserProfile(
              basicInfo: info['basicInfo'] as String? ?? '',
              detailedInfo: info['detailedInfo'] as String? ?? '',
              passingScore: info['passingScore'] as int?,
            )
          : const UserProfile();
      return _EventItem(uid: uid, profile: profile, totalScore: totalScore);
    }

    final completedMine = await Future.wait(answererMap.entries
        .map((e) => toItem(e.key, e.value['totalScore'] as int)));
    final iCompleted = await Future.wait(creatorMap.entries
        .map((e) => toItem(e.key, e.value['totalScore'] as int)));

    if (mounted) {
      setState(() {
        _completedMine = completedMine;
        _iCompleted = iCompleted;
        _isLoading = false;
      });
    }
  }

  void _goToDetail(_EventItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailPage(
          uid: item.uid,
          profile: item.profile,
          lastScore: item.totalScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Y2KScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Y2K.ink, strokeWidth: 3))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: Y2K.ink,
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        children: [
                          _buildSection(
                            indexLabel: '01',
                            title: '完成我的测试',
                            subtitle: 'INCOMING · 他人的成绩',
                            accent: Y2K.pink,
                            iconColor: Colors.white,
                            icon: Icons.people_alt_outlined,
                            items: _completedMine,
                            emptyText: '暂无用户完成你的测试题',
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            indexLabel: '02',
                            title: '我完成的测试',
                            subtitle: 'OUTGOING · 我的答题',
                            accent: Y2K.lime,
                            iconColor: Y2K.ink,
                            icon: Icons.assignment_turned_in_outlined,
                            items: _iCompleted,
                            emptyText: '你还没有完成任何测试题',
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Y2KChip(
            label: '← 返回',
            background: Colors.transparent,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EVENTS · 事件流',
                    style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                const Text(
                  '答题记录',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Y2K.ink),
                ),
              ],
            ),
          ),
          Y2KButton(
            label: '刷新',
            icon: Icons.refresh_rounded,
            kind: Y2KButtonKind.dark,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            fontSize: 13,
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String indexLabel,
    required String title,
    required String subtitle,
    required Color accent,
    required Color iconColor,
    required IconData icon,
    required List<_EventItem> items,
    required String emptyText,
  }) {
    return Column(
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
                  color: iconColor,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: Y2K.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Y2K.ink),
                  ),
                  Text(subtitle,
                      style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                ],
              ),
            ),
            Y2KTag(label: '${items.length}', background: Y2K.card),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _buildEmpty(emptyText)
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildItemCard(item),
              )),
      ],
    );
  }

  Widget _buildEmpty(String text) {
    return Y2KCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Y2K.gold,
              shape: BoxShape.circle,
              border: Border.all(color: Y2K.ink, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.inbox_rounded,
                size: 22, color: Y2K.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 14,
                  color: Y2K.ink2,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(_EventItem item) {
    final basicInfo = item.profile.basicInfo;
    final isPassed = item.profile.passingScore != null &&
        item.totalScore >= item.profile.passingScore!;

    return Y2KCard(
      onTap: () => _goToDetail(item),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isPassed ? Y2K.lime : Y2K.blue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Y2K.ink, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_outline,
                  color: isPassed ? Y2K.ink : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UID',
                        style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                    const SizedBox(height: 2),
                    Text(
                      truncateUid(item.uid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Y2K.ink,
                        fontFamily: 'monospace',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPassed)
                const Y2KTag(label: 'PASSED', background: Y2K.lime),
            ],
          ),
          const SizedBox(height: 12),
          const Y2KDashedDivider(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Y2K.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  basicInfo.isNotEmpty ? basicInfo : '未填写基础信息',
                  style: TextStyle(
                    fontSize: 13,
                    color: basicInfo.isNotEmpty ? Y2K.ink2 : Y2K.muted,
                    fontStyle: basicInfo.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Y2KTag(
                label: '${item.totalScore} 分',
                background: Y2K.pink,
                foreground: Colors.white,
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Y2K.ink),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventItem {
  final String uid;
  final UserProfile profile;
  final int totalScore;

  const _EventItem({
    required this.uid,
    required this.profile,
    required this.totalScore,
  });
}
