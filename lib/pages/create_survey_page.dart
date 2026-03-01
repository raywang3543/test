import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/survey_model.dart';
import '../services/survey_storage.dart';
import '../services/user_storage.dart';

class _OptionData {
  final TextEditingController contentController;
  final TextEditingController scoreController;

  _OptionData()
      : contentController = TextEditingController(),
        scoreController = TextEditingController(text: '0');

  void dispose() {
    contentController.dispose();
    scoreController.dispose();
  }
}

class _QuestionData {
  final TextEditingController titleController;
  bool isMultiChoice;
  final List<_OptionData> options;
  /// 标准答案：单选为 int?（选项下标），多选为 Set&lt;int&gt;
  dynamic correctAnswer;

  _QuestionData()
      : titleController = TextEditingController(),
        isMultiChoice = false,
        options = [_OptionData()],
        correctAnswer = null;

  void dispose() {
    titleController.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class CreateSurveyPage extends StatefulWidget {
  const CreateSurveyPage({super.key});

  @override
  State<CreateSurveyPage> createState() => _CreateSurveyPageState();
}

class _CreateSurveyPageState extends State<CreateSurveyPage> {
  final List<_QuestionData> _questions = [_QuestionData()];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    for (final q in _questions) {
      q.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionData());
    });
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      _showSnackBar('至少需要一个问题');
      return;
    }
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex].options.add(_OptionData());
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    if (_questions[questionIndex].options.length <= 1) {
      _showSnackBar('每题至少需要一个选项');
      return;
    }
    setState(() {
      final question = _questions[questionIndex];
      question.options[optionIndex].dispose();
      question.options.removeAt(optionIndex);
      
      // 如果删除的是已选中的标准答案，需要更新 correctAnswer
      if (!question.isMultiChoice) {
        if (question.correctAnswer == optionIndex) {
          question.correctAnswer = null;
        } else if (question.correctAnswer != null && 
                   question.correctAnswer > optionIndex) {
          question.correctAnswer = (question.correctAnswer as int) - 1;
        }
      } else {
        // 多选题：删除对应选项，调整索引
        final newSet = <int>{};
        for (final idx in (question.correctAnswer as Set<int>? ?? {})) {
          if (idx < optionIndex) {
            newSet.add(idx);
          } else if (idx > optionIndex) {
            newSet.add(idx - 1);
          }
        }
        question.correctAnswer = newSet.isEmpty ? null : newSet;
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// 设置单选题标准答案
  void _setSingleCorrectAnswer(int qIndex, int oIndex) {
    setState(() {
      _questions[qIndex].correctAnswer = oIndex;
    });
  }

  /// 切换多选题标准答案
  void _toggleMultiCorrectAnswer(int qIndex, int oIndex) {
    setState(() {
      final question = _questions[qIndex];
      final currentSet = (question.correctAnswer as Set<int>?) ?? <int>{};
      final newSet = Set<int>.from(currentSet);
      if (newSet.contains(oIndex)) {
        newSet.remove(oIndex);
      } else {
        newSet.add(oIndex);
      }
      question.correctAnswer = newSet.isEmpty ? null : newSet;
    });
  }

  /// 获取标准答案的显示文本
  String _getCorrectAnswerText(_QuestionData question) {
    if (question.correctAnswer == null) {
      return '未设置';
    }
    if (!question.isMultiChoice) {
      // 单选题
      final idx = question.correctAnswer as int;
      if (idx >= 0 && idx < question.options.length) {
        return String.fromCharCode(65 + idx);
      }
      return '无效';
    } else {
      // 多选题
      final set = question.correctAnswer as Set<int>;
      if (set.isEmpty) return '未设置';
      final labels = set.toList()..sort();
      return labels.map((idx) => String.fromCharCode(65 + idx)).join(', ');
    }
  }

  bool _validate() {
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.titleController.text.trim().isEmpty) {
        _showSnackBar('第 ${i + 1} 题的题目不能为空');
        return false;
      }
      for (int j = 0; j < q.options.length; j++) {
        final o = q.options[j];
        if (o.contentController.text.trim().isEmpty) {
          _showSnackBar('第 ${i + 1} 题第 ${j + 1} 个选项的内容不能为空');
          return false;
        }
        if (int.tryParse(o.scoreController.text.trim()) == null) {
          _showSnackBar('第 ${i + 1} 题第 ${j + 1} 个选项的分数必须为整数');
          return false;
        }
      }
      // 检查是否设置了标准答案
      if (q.correctAnswer == null) {
        _showSnackBar('请为第 ${i + 1} 题设置标准答案');
        return false;
      }
    }
    return true;
  }

  Future<void> _startSurvey() async {
    if (!_validate()) return;

    // 获取当前用户的 UID
    final uid = await UserStorage.getOrCreateUid();

    final survey = Survey(
      uid: uid,
      createdAt: DateTime.now(),
      questions: _questions.map((q) {
        // 转换标准答案格式
        dynamic correctAnswer;
        if (!q.isMultiChoice) {
          correctAnswer = q.correctAnswer;
        } else {
          correctAnswer = (q.correctAnswer as Set<int>?)?.toList() ?? [];
        }

        return SurveyQuestion(
          title: q.titleController.text.trim(),
          isMultiChoice: q.isMultiChoice,
          correctAnswer: correctAnswer,
          options: q.options.map((o) {
            return SurveyOption(
              content: o.contentController.text.trim(),
              score: int.parse(o.scoreController.text.trim()),
            );
          }).toList(),
        );
      }).toList(),
    );

    await SurveyStorage.save(survey);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('创建测试'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _startSurvey,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('提交'),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _questions.length,
        itemBuilder: (context, index) => _buildQuestionCard(index),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add),
        label: const Text('添加问题'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildQuestionCard(int qIndex) {
    final question = _questions[qIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final hasCorrectAnswer = question.correctAnswer != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目头部
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '第 ${qIndex + 1} 题',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeQuestion(qIndex),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: '删除此题',
                  iconSize: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 题目输入
            TextField(
              controller: question.titleController,
              decoration: InputDecoration(
                labelText: '题目内容',
                hintText: '请输入题目...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // 多选开关
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    question.isMultiChoice ? Icons.check_box_outlined : Icons.radio_button_checked,
                    size: 18,
                    color: question.isMultiChoice ? colorScheme.primary : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('允许多选', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: question.isMultiChoice,
                    onChanged: (value) {
                      setState(() {
                        question.isMultiChoice = value;
                        question.correctAnswer = value ? <int>{} : null;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 标准答案区域
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasCorrectAnswer 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasCorrectAnswer 
                      ? Colors.green.shade200 
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key,
                        size: 16,
                        color: hasCorrectAnswer 
                            ? Colors.green.shade700 
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '我的答案',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasCorrectAnswer 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasCorrectAnswer 
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getCorrectAnswerText(question),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasCorrectAnswer 
                                ? Colors.green.shade800 
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击选项设置我的答案（用于性格对比分析）',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 选项列表标题
            Row(
              children: [
                const Text(
                  '选项列表',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${question.options.length})',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 选项（带标准答案选择功能）
            ...question.options.asMap().entries.map(
              (e) => _buildOptionRow(qIndex, e.key, e.value),
            ),

            // 添加选项按钮
            TextButton.icon(
              onPressed: () => _addOption(qIndex),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('添加选项'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(int qIndex, int oIndex, _OptionData option) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = String.fromCharCode(65 + oIndex); // A, B, C...
    final question = _questions[qIndex];
    
    // 检查是否为标准答案
    final isCorrectAnswer = !question.isMultiChoice
        ? question.correctAnswer == oIndex
        : (question.correctAnswer as Set<int>?)?.contains(oIndex) ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 选项标签 + 标准答案选择
          GestureDetector(
            onTap: () {
              if (!question.isMultiChoice) {
                _setSingleCorrectAnswer(qIndex, oIndex);
              } else {
                _toggleMultiCorrectAnswer(qIndex, oIndex);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCorrectAnswer 
                    ? Colors.green 
                    : colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: isCorrectAnswer
                    ? Border.all(color: Colors.green.shade700, width: 2)
                    : null,
              ),
              child: isCorrectAnswer
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // 选项内容
          Expanded(
            flex: 4,
            child: TextField(
              controller: option.contentController,
              decoration: InputDecoration(
                hintText: '选项 $label 内容',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 8),

          // 分数输入
          SizedBox(
            width: 72,
            child: TextField(
              controller: option.scoreController,
              decoration: InputDecoration(
                labelText: '分数',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 4),

          // 删除选项
          IconButton(
            onPressed: () => _removeOption(qIndex, oIndex),
            icon: const Icon(Icons.close, size: 18),
            color: Colors.red.shade300,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
