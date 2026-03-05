import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';
import 'user_detail_page.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool _isLoading = true;
  List<_EventItem> _completedMine = [];   // 完成我的测试题的用户
  List<_EventItem> _iCompleted = [];       // 我完成的测试题的用户

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

    // 完成我的测试题的用户（creatorUid = me，按 answererUid 分组取最新）
    final creatorEvents = await db.getEventsByCreatorUid(currentUid);
    final Map<String, Map<String, dynamic>> answererMap = {};
    for (final e in creatorEvents) {
      final uid = e['answererUid'] as String;
      if (!answererMap.containsKey(uid)) answererMap[uid] = e;
    }

    // 我完成的测试题（answererUid = me，按 creatorUid 分组取最新）
    final answererEvents = await db.getEventsByAnswererUid(currentUid);
    final Map<String, Map<String, dynamic>> creatorMap = {};
    for (final e in answererEvents) {
      final uid = e['creatorUid'] as String;
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

  Future<void> _clearEvents({required bool isCreator}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: Text(isCreator ? '确定清空"完成我测试题的用户"的所有记录？' : '确定清空"我完成的测试题"的所有记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final currentUid = await UserStorage.getCurrentUid();
    if (currentUid == null) return;
    final db = DatabaseHelper();
    if (isCreator) {
      await db.deleteEventsByCreatorUid(currentUid);
    } else {
      await db.deleteEventsByAnswererUid(currentUid);
    }
    await _loadData();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('事件'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(
                    colorScheme: colorScheme,
                    title: '完成我的测试',
                    icon: Icons.people_alt_outlined,
                    items: _completedMine,
                    emptyText: '暂无用户完成你的测试题',
                    onClear: _completedMine.isEmpty ? null : () => _clearEvents(isCreator: true),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    colorScheme: colorScheme,
                    title: '我完成的测试',
                    icon: Icons.assignment_turned_in_outlined,
                    items: _iCompleted,
                    emptyText: '你还没有完成任何测试题',
                    onClear: _iCompleted.isEmpty ? null : () => _clearEvents(isCreator: false),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required ColorScheme colorScheme,
    required String title,
    required IconData icon,
    required List<_EventItem> items,
    required String emptyText,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const Spacer(),
            if (onClear != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('清空', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          )
        else
          ...items.map((item) => _buildItemCard(item, colorScheme)),
      ],
    );
  }

  Widget _buildItemCard(_EventItem item, ColorScheme colorScheme) {
    final basicInfo = item.profile.basicInfo;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _goToDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：图标 + UID
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UID',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.uid,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // 基础信息 + 分数
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      basicInfo.isNotEmpty ? basicInfo : '未填写基础信息',
                      style: TextStyle(
                        fontSize: 14,
                        color: basicInfo.isNotEmpty
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        fontStyle: basicInfo.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.profile.passingScore != null &&
                      item.totalScore >= item.profile.passingScore!)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        '合格',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.totalScore} 分',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
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
