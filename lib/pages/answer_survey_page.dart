import 'package:flutter/material.dart';
import '../models/analysis_result_model.dart';
import '../models/survey_model.dart';
import '../services/kimi_service.dart';
import '../services/survey_result_storage.dart';

class AnswerSurveyPage extends StatefulWidget {
  final Survey survey;

  const AnswerSurveyPage({super.key, required this.survey});

  @override
  State<AnswerSurveyPage> createState() => _AnswerSurveyPageState();
}

class _AnswerSurveyPageState extends State<AnswerSurveyPage> {
  // 每题答案：单选为 int?（选项下标），多选为 Set<int>
  late List<dynamic> _answers;
  bool _submitted = false;
  bool _isAnalyzing = false;
  PersonalityAnalysisResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    _answers = widget.survey.questions.map<dynamic>((q) {
      return q.isMultiChoice ? <int>{} : null;
    }).toList();
  }

  int get _answeredCount {
    return _answers.where((a) {
      if (a is Set<int>) return a.isNotEmpty;
      return a != null;
    }).length;
  }

  bool get _allAnswered => _answeredCount == widget.survey.questions.length;

  Future<void> _submit() async {
    // 先进入分析中状态
    setState(() {
      _isAnalyzing = true;
      _submitted = true;
    });

    // 调用 Kimi API 进行详细分析
    final result = await KimiService.analyzePersonalityDetailed(
      survey: widget.survey,
      answers: _answers,
    );

    // 保存答题结果到本地 event 表
    // answererUid: 当前用户（答题人），creatorUid: 出题人
    await SurveyResultStorage.saveResult(
      creatorUid: widget.survey.uid,
      totalScore: result.totalScore,
    );

    if (mounted) {
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.survey.questions.length;
    final answered = _answeredCount;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? answered / total : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_submitted ? '测试结果' : '情感测试'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: _submitted
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _buildProgressBar(answered, total, progress),
              ),
      ),
      body: _submitted ? _buildResultView() : _buildQuestionsView(),
      bottomNavigationBar: !_submitted && _allAnswered
          ? _buildSubmitBar()
          : null,
    );
  }

  Widget _buildProgressBar(int answered, int total, double progress) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已完成 $answered / $total 题',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white30,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('提交答案', style: TextStyle(fontSize: 16)),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildQuestionsView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: widget.survey.questions.length,
      itemBuilder: (context, index) => _buildQuestionCard(index),
    );
  }

  Widget _buildQuestionCard(int qIndex) {
    final question = widget.survey.questions[qIndex];
    final answer = _answers[qIndex];
    final isAnswered = answer is Set<int> ? answer.isNotEmpty : answer != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAnswered ? Colors.green.shade300 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目标签行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAnswered ? Colors.green : colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '第 ${qIndex + 1} 题',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${question.questionScore}分',
                    style: TextStyle(
                      color: Colors.pink.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (question.isMultiChoice) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '多选',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isAnswered
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 22, key: ValueKey('checked'))
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 22, key: const ValueKey('unchecked')),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 题目
            Text(
              question.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
            ),

            if (question.isMultiChoice)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '可选择多个选项',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                ),
              ),
            const SizedBox(height: 12),

            // 选项列表
            ...question.options.asMap().entries.map(
              (e) => _buildOptionTile(qIndex, e.key, e.value, question.isMultiChoice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(int qIndex, int oIndex, SurveyOption option, bool isMultiChoice) {
    final answer = _answers[qIndex];
    final isSelected = isMultiChoice
        ? (answer as Set<int>).contains(oIndex)
        : answer == oIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isMultiChoice) {
            final set = _answers[qIndex] as Set<int>;
            if (set.contains(oIndex)) {
              set.remove(oIndex);
            } else {
              set.add(oIndex);
            }
          } else {
            _answers[qIndex] = oIndex;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 单选/多选图标
            SizedBox(
              width: 24,
              height: 24,
              child: isMultiChoice
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    )
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.circle, color: Colors.white, size: 10)
                          : null,
                    ),
            ),
            const SizedBox(width: 10),

            // 选项字母标签
            Text(
              '${String.fromCharCode(65 + oIndex)}.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? colorScheme.primary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 6),

            // 选项内容
            Expanded(
              child: Text(
                option.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? colorScheme.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ── 结果视图 ───────────────────────────────────────────────────────────────

  Widget _buildResultView() {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 分析中状态
    if (_isAnalyzing) {
      return _buildAnalyzingView(colorScheme);
    }
    
    if (_analysisResult == null) {
      return const Center(child: Text('分析失败，请重试'));
    }
    
    // 显示完整结果
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // 总分卡片
          _buildScoreCard(colorScheme),
          const SizedBox(height: 20),
          
          // 性格分析卡片
          _buildPersonalityCard(colorScheme),
          const SizedBox(height: 20),

          // 每题详情标题
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '每题得分详情',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // 每题结果（包含匹配度和得分原因）
          ..._analysisResult!.questionResults.map(
            (result) => _buildQuestionResultCard(result, colorScheme),
          ),
          
          const SizedBox(height: 20),
          
          // 确认按钮 - 返回首页
          _buildConfirmButton(colorScheme),
        ],
      ),
    );
  }

  /// 确认按钮
  Widget _buildConfirmButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('确认', style: TextStyle(fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// 分析中加载视图
  Widget _buildAnalyzingView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '正在分析您的答题...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI 正在计算匹配度和得分',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 总分卡片
  Widget _buildScoreCard(ColorScheme colorScheme) {
    final result = _analysisResult!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 12),
            const Text(
              '答题完成！',
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              '${result.totalScore}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            Text(
              '/ ${result.fullTotalScore} 分',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            // 总体匹配度
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '总体匹配度: ${result.overallMatchPercentage}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreStat('共 ${result.questionResults.length} 题', Icons.quiz_outlined),
                const SizedBox(width: 24),
                _scoreStat('全部作答', Icons.check_circle_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 性格分析卡片（包含出题者、做题者分析及合适度）
  Widget _buildPersonalityCard(ColorScheme colorScheme) {
    final result = _analysisResult!;
    final isError = result.creatorAnalysis.startsWith('⚠️');
    
    return Column(
      children: [
        // 出题者性格分析
        _buildAnalysisSection(
          title: '出题者性格分析',
          icon: Icons.edit_note,
          iconColor: Colors.blue,
          bgColor: Colors.blue.shade50,
          content: result.creatorAnalysis,
        ),
        const SizedBox(height: 12),
        
        // 做题者性格分析
        _buildAnalysisSection(
          title: '做题者性格分析',
          icon: Icons.person_outline,
          iconColor: Colors.green,
          bgColor: Colors.green.shade50,
          content: result.playerAnalysis,
        ),
        const SizedBox(height: 12),
        
        // 同性合适度
        _buildAnalysisSection(
          title: '同性朋友合适度',
          icon: Icons.people_outline,
          iconColor: Colors.orange,
          bgColor: Colors.orange.shade50,
          content: result.sameGenderCompatibility,
        ),
        const SizedBox(height: 12),
        
        // 异性合适度
        _buildAnalysisSection(
          title: '异性伴侣合适度',
          icon: Icons.favorite_outline,
          iconColor: Colors.pink,
          bgColor: Colors.pink.shade50,
          content: result.oppositeGenderCompatibility,
          showAiBadge: !isError,
        ),
      ],
    );
  }

  /// 分析区块组件
  Widget _buildAnalysisSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String content,
    bool showAiBadge = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor.withAlpha(220),
                  ),
                ),
                if (showAiBadge) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.purple.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 每题结果卡片（包含匹配度和得分原因）
  Widget _buildQuestionResultCard(QuestionAnalysisResult result, ColorScheme colorScheme) {
    // 根据匹配度选择颜色
    Color matchColor;
    if (result.matchPercentage >= 80) {
      matchColor = Colors.green;
    } else if (result.matchPercentage >= 50) {
      matchColor = Colors.orange;
    } else {
      matchColor = Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '第 ${result.questionIndex + 1} 题',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                // 匹配度标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: matchColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: matchColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.compare_arrows,
                        size: 14,
                        color: matchColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '匹配 ${result.matchPercentage}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: matchColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 得分标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${result.actualScore}/${result.fullScore}分',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // 题目内容
            Text(
              result.questionTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            
            // 答案对比
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '出题者: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          result.creatorAnswer,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '做题者: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          result.playerAnswer,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // 得分原因
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: matchColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: matchColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: matchColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreStat(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
