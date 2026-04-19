import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';
import 'user_detail_page.dart';

/// 用户列表页面 - 显示所有答题用户列表
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<UserListItem> _users = [];
  List<UserListItem> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final currentUid = await UserStorage.getCurrentUid();
    final allUsers = await UserStorage.loadAll();
    final db = DatabaseHelper();

    final userList = <UserListItem>[];
    for (final row in allUsers) {
      final uid = row['uid'] as String;
      if (uid == currentUid) continue;
      final passingScore = row['passingScore'] as int?;

      int? lastScore;
      if (currentUid != null) {
        final events =
            await db.getEventsByAnswererAndCreatorUid(currentUid, uid);
        if (events.isNotEmpty) {
          lastScore = events.first['totalScore'] as int;
        }
      }

      userList.add(UserListItem(
        uid: uid,
        profile: UserProfile(
          basicInfo: row['basicInfo'] as String? ?? '',
          detailedInfo: row['detailedInfo'] as String? ?? '',
          passingScore: passingScore,
        ),
        lastScore: lastScore,
      ));
    }

    if (mounted) {
      setState(() {
        _users = userList;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredUsers = _users.where((user) {
        return user.uid.toLowerCase().contains(query) ||
            user.profile.basicInfo.toLowerCase().contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _applyFilter();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _applyFilter();
    });
  }

  void _goToUserDetail(UserListItem user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailPage(
          uid: user.uid,
          profile: user.profile,
          lastScore: user.lastScore,
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
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Y2K.ink, strokeWidth: 3))
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                Text('USERS · 人格图鉴', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                const Text(
                  '用户列表',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Y2K.ink),
                ),
              ],
            ),
          ),
          Y2KButton(
            label: '刷新',
            icon: Icons.refresh_rounded,
            kind: Y2KButtonKind.dark,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            fontSize: 13,
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Y2K.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Y2K.ink, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 14, color: Y2K.ink, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '搜索 UID 或基础信息…',
            hintStyle: Y2K.monoSm.copyWith(color: Y2K.muted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Y2K.ink),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close, color: Y2K.ink, size: 18),
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_users.isEmpty) {
      return _buildEmpty('暂无用户', '还没有用户答题记录');
    }
    if (_filteredUsers.isEmpty) {
      return _buildEmpty('未找到', '试试其他搜索词');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Y2K.ink,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(_filteredUsers[index]),
        ),
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Y2K.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Y2K.ink, width: 2),
                boxShadow: Y2K.shadow(offset: 4),
              ),
              child: const Icon(Icons.people_outline_rounded, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Y2K.ink)),
            const SizedBox(height: 6),
            Text(subtitle, style: Y2K.bodyMuted, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserListItem userInfo) {
    final displayUid = _highlightMatch(userInfo.uid, _searchQuery);
    final basicInfo = userInfo.profile.basicInfo;
    final isPassed = userInfo.lastScore != null &&
        userInfo.profile.passingScore != null &&
        userInfo.lastScore! >= userInfo.profile.passingScore!;

    return Y2KCard(
      onTap: () => _goToUserDetail(userInfo),
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
                  color: isPassed ? Y2K.lime : Y2K.gold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Y2K.ink, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person_outline, color: Y2K.ink, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UID', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                    const SizedBox(height: 2),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Y2K.ink,
                          fontFamily: 'monospace',
                        ),
                        children: displayUid,
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
                    fontStyle: basicInfo.isNotEmpty ? FontStyle.normal : FontStyle.italic,
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
              if (userInfo.lastScore != null) ...[
                Y2KTag(label: '${userInfo.lastScore} 分', background: Y2K.pink, foreground: Colors.white),
                const SizedBox(width: 8),
              ],
              if (userInfo.lastSubmitTime != null)
                Text(_formatDate(userInfo.lastSubmitTime!), style: Y2K.monoSm.copyWith(color: Y2K.muted)),
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Y2K.ink),
            ],
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightMatch(String text, String query) {
    if (query.isEmpty) return [TextSpan(text: text)];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Y2K.lime,
          fontWeight: FontWeight.w800,
          color: Y2K.ink,
        ),
      ));
      start = index + query.length;
    }
    return spans;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return '刚刚';
        return '${diff.inMinutes} 分钟前';
      }
      return '${diff.inHours} 小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class UserListItem {
  final String uid;
  final UserProfile profile;
  final DateTime? lastSubmitTime;
  final int? lastScore;

  const UserListItem({
    required this.uid,
    required this.profile,
    this.lastSubmitTime,
    this.lastScore,
  });
}
