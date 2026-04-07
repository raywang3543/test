import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';

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

  /// 检查当前用户是否有权查看详细信息：
  /// 需完成该用户的测试，且分数达到合格线（未设合格线则完成即可）
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

  /// 复制 UID 到剪贴板
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('用户信息'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        // 注意：没有编辑按钮
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(
              title: '基础信息',
              icon: Icons.person_outline_rounded,
              content: _profile.basicInfo,
              colorScheme: colorScheme,
              uid: _uid,
            ),
            const SizedBox(height: 12),
            if (_showDetailedInfo) ...[
              _buildInfoCard(
                title: '详细信息',
                icon: Icons.info_outline_rounded,
                content: _profile.detailedInfo,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),
            ],
            _buildPassingScoreCard(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
    required ColorScheme colorScheme,
    String? uid,
  }) {
    final isEmpty = content.trim().isEmpty;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (uid != null && uid.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'UID',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      uid,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // 复制 UID 按钮
                  IconButton(
                    onPressed: () => _copyUid(uid),
                    icon: Icon(
                      Icons.copy_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    tooltip: '复制 UID',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            Text(
              isEmpty ? '未填写' : content,
              style: TextStyle(
                fontSize: 15,
                color: isEmpty ? Colors.grey.shade400 : Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassingScoreCard(ColorScheme colorScheme) {
    final score = _profile.passingScore;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.tune_rounded, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '合格分数',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score == null ? '未设置' : '答题达到 $score 分视为合格',
                    style: TextStyle(
                      fontSize: 13,
                      color: score == null
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (score != null)
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
