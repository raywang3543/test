import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/survey_result_storage.dart';
import '../services/user_storage.dart';
import 'edit_user_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserProfile _profile = const UserProfile();
  int? _lastScore;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await UserStorage.load();
    final uid = await UserStorage.getOrCreateUid();
    // 从答题结果存储中获取当前用户的最新得分
    final latestResult = await SurveyResultStorage.loadCurrentUserLatestResult();
    if (mounted) {
      setState(() {
        _profile = profile ?? const UserProfile();
        _uid = uid;
        _lastScore = latestResult?.totalScore;
      });
    }
  }

  bool get _showDetailedInfo {
    final passing = _profile.passingScore;
    if (passing == null) return true;
    if (_lastScore == null) return false;
    return _lastScore! >= passing;
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
        title: const Text('个人信息'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditUserPage(profile: _profile),
              ),
            ).then((_) => _loadData()),
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
          ),
        ],
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
            if (_showDetailedInfo)
              _buildInfoCard(
                title: '详细信息',
                icon: Icons.info_outline_rounded,
                content: _profile.detailedInfo,
                colorScheme: colorScheme,
              ),
            const SizedBox(height: 12),
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
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
              child: Icon(Icons.tune_rounded, color: colorScheme.primary, size: 24),
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
                      color: score == null ? Colors.grey.shade400 : Colors.grey.shade600,
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
