import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';
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

    final userList = <UserListItem>[];
    for (final row in allUsers) {
      final uid = row['uid'] as String;
      if (uid == currentUid) continue;
      final passingScore = row['passingScore'] as int?;

      userList.add(UserListItem(
        uid: uid,
        profile: UserProfile(
          basicInfo: row['basicInfo'] as String? ?? '',
          detailedInfo: row['detailedInfo'] as String? ?? '',
          passingScore: passingScore,
        ),
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

  /// 应用搜索过滤
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

  /// 处理搜索输入变化
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _applyFilter();
    });
  }

  /// 清除搜索
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('用户列表'),
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
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(colorScheme),
          // 内容区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(colorScheme),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索 UID 或基础信息...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon:
              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(Icons.clear,
                      color: Colors.white.withValues(alpha: 0.7)),
                  tooltip: '清除',
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(ColorScheme colorScheme) {
    if (_users.isEmpty) {
      return _buildEmptyView(colorScheme, '暂无用户', '还没有用户答题记录');
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyView(colorScheme, '未找到匹配的用户', '请尝试其他搜索词');
    }

    return _buildListView(colorScheme);
  }

  /// 构建空状态视图
  Widget _buildEmptyView(ColorScheme colorScheme, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_outlined
                : Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) =>
            _buildUserCard(_filteredUsers[index], colorScheme),
      ),
    );
  }

  Widget _buildUserCard(UserListItem userInfo, ColorScheme colorScheme) {
    final displayUid = _highlightMatch(userInfo.uid, _searchQuery);
    final basicInfo = userInfo.profile.basicInfo;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _goToUserDetail(userInfo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：UID
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontFamily: 'monospace',
                            ),
                            children: displayUid,
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
              // 基础信息
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
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
                ],
              ),
              const SizedBox(height: 8),
              // 最后答题时间和得分
              Row(
                children: [
                  if (userInfo.lastScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${userInfo.lastScore} 分',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (userInfo.lastSubmitTime != null)
                    Text(
                      _formatDate(userInfo.lastSubmitTime!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 高亮匹配的文字
  List<TextSpan> _highlightMatch(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      // 添加匹配前的文本
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // 添加高亮的匹配文本
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFFFFF00),
          fontWeight: FontWeight.bold,
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
        if (diff.inMinutes == 0) {
          return '刚刚';
        }
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

/// 用户列表项数据
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
