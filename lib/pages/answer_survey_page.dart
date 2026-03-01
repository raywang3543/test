import 'package:flutter/material.dart';
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
  int _totalScore = 0;
  String _personalityAnalysis = '';

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

  int _calculateScore() {
    int total = 0;
    for (int i = 0; i < widget.survey.questions.length; i++) {
      final q = widget.survey.questions[i];
      final answer = _answers[i];
      if (answer is Set<int>) {
        for (final idx in answer) {
          total += q.options[idx].score;
        }
      } else if (answer is int) {
        total += q.options[answer].score;
      }
    }
    return total;
  }

  Future<void> _submit() async {
    final score = _calculateScore();
    
    // 先进入分析中状态
    setState(() {
      _totalScore = score;
      _isAnalyzing = true;
      _submitted = true;
    });

    // 保存答题结果到本地
    await SurveyResultStorage.saveResult(
      survey: widget.survey,
      answers: _answers,
      totalScore: score,
    );

    // 调用 Kimi API 进行性格分析
    final analysis = await KimiService.analyzePersonality(
      survey: widget.survey,
      answers: _answers,
      totalScore: score,
    );

    if (mounted) {
      setState(() {
        _personalityAnalysis = analysis;
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

          // 详情标题
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '答题详情',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // 每题结果
          ...widget.survey.questions.asMap().entries.map(
            (e) => _buildResultQuestionCard(e.key, e.value),
          ),
        ],
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
            'Kimi AI 正在为您生成性格分析报告',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          // 分数预览
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '总分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalScore',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 总分卡片
  Widget _buildScoreCard(ColorScheme colorScheme) {
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
              '$_totalScore',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            const Text(
              '总分',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreStat('共 ${widget.survey.questions.length} 题', Icons.quiz_outlined),
                const SizedBox(width: 24),
                _scoreStat('全部作答', Icons.check_circle_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 性格分析卡片
  Widget _buildPersonalityCard(ColorScheme colorScheme) {
    final isError = _personalityAnalysis.startsWith('⚠️');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isError 
                ? [Colors.orange.shade100, Colors.orange.shade50]
                : [Colors.pink.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError ? Icons.warning_amber_rounded : Icons.psychology,
                  color: isError ? Colors.orange : Colors.purple,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isError ? '提示' : '性格分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isError ? Colors.orange.shade800 : Colors.purple.shade800,
                  ),
                ),
                if (!isError) ...[
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
                          'Kimi AI',
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
              _personalityAnalysis,
              style: TextStyle(
                fontSize: 15,
                height: 1.8,
                color: isError ? Colors.orange.shade900 : Colors.black87,
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

  Widget _buildResultQuestionCard(int qIndex, SurveyQuestion question) {
    final answer = _answers[qIndex];
    final colorScheme = Theme.of(context).colorScheme;

    int questionScore = 0;
    if (answer is Set<int>) {
      for (final idx in answer) {
        questionScore += question.options[idx].score;
      }
    } else if (answer is int) {
      questionScore = question.options[answer].score;
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
            // 题目头
            Row(
              children: [
                Text(
                  '第 ${qIndex + 1} 题',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (question.isMultiChoice)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '多选',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '得 $questionScore 分',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 题目文字
            Text(
              question.title,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 10),

            // 选项结果
            ...question.options.asMap().entries.map((e) {
              final oIndex = e.key;
              final option = e.value;
              final isSelected = answer is Set<int>
                  ? answer.contains(oIndex)
                  : answer == oIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + oIndex)}. ${option.content}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
