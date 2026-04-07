import 'package:flutter/material.dart';
import '../models/survey_model.dart';
import '../services/survey_storage.dart';
import '../services/user_storage.dart';
import 'answer_survey_page.dart';

/// 测试题列表页面 - 显示所有保存在本地的 UID 和用户基础信息
class TestListPage extends StatefulWidget {
  const TestListPage({super.key});

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  List<SurveyUserInfo> _surveyUsers = [];
  List<SurveyUserInfo> _filteredUsers = [];
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
    
    // 加载所有测试题
    final allSurveys = await SurveyStorage.loadAll();
    final currentUid = await UserStorage.getCurrentUid();

    // 构建用户信息列表
    final List<SurveyUserInfo> userInfos = [];
    for (final survey in allSurveys) {
      if (survey.uid == currentUid) continue;
      // 从Survey中获取创建者的基础信息
      debugPrint('加载测试 - UID: ${survey.uid}');
      debugPrint('加载测试 - 基础信息: "${survey.creatorBasicInfo}"');
      userInfos.add(SurveyUserInfo(
        uid: survey.uid,
        survey: survey,
        basicInfo: survey.creatorBasicInfo,
        createdAt: survey.createdAt,
      ));
    }
    
    // 按创建时间倒序排列
    userInfos.sort((a, b) => 
      (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    
    if (mounted) {
      setState(() {
        _surveyUsers = userInfos;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  /// 应用搜索过滤
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_surveyUsers);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredUsers = _surveyUsers.where((user) {
        return user.uid.toLowerCase().contains(query);
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



  void _goToAnswerSurvey(Survey survey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerSurveyPage(survey: survey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('选择测试'),
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
          hintText: '搜索 UID...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7)),
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
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(ColorScheme colorScheme) {
    if (_surveyUsers.isEmpty) {
      return _buildEmptyView(colorScheme, '暂无测试题', '请先创建测试题');
    }
    
    if (_filteredUsers.isEmpty) {
      return _buildEmptyView(colorScheme, '未找到匹配的 UID', '请尝试其他搜索词');
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
            _searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.quiz_outlined,
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
        itemBuilder: (context, index) => _buildUserCard(
          _filteredUsers[index],
          colorScheme,
        ),
      ),
    );
  }

  Widget _buildUserCard(SurveyUserInfo userInfo, ColorScheme colorScheme) {
    // 高亮匹配的 UID 部分
    final displayUid = _highlightMatch(userInfo.uid, _searchQuery);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _goToAnswerSurvey(userInfo.survey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：UID 和题目数量
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
                      userInfo.basicInfo.isNotEmpty ? userInfo.basicInfo : '未填写基础信息',
                      style: TextStyle(
                        fontSize: 14,
                        color: userInfo.basicInfo.isNotEmpty 
                            ? Colors.grey.shade600 
                            : Colors.grey.shade400,
                        fontStyle: userInfo.basicInfo.isNotEmpty 
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
              
              // 题目数量和创建时间
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${userInfo.survey.questions.length} 题',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (userInfo.createdAt != null)
                    Text(
                      _formatDate(userInfo.createdAt!),
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

/// 测试题用户信息
class SurveyUserInfo {
  final String uid;
  final Survey survey;
  final String basicInfo;
  final DateTime? createdAt;

  const SurveyUserInfo({
    required this.uid,
    required this.survey,
    required this.basicInfo,
    this.createdAt,
  });
}
