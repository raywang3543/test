import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/survey_model.dart';
import '../services/survey_storage.dart';

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

  _QuestionData()
      : titleController = TextEditingController(),
        isMultiChoice = false,
        options = [_OptionData()];

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
      _questions[questionIndex].options[optionIndex].dispose();
      _questions[questionIndex].options.removeAt(optionIndex);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
    }
    return true;
  }

  Future<void> _startSurvey() async {
    if (!_validate()) return;

    final survey = Survey(
      questions: _questions.map((q) {
        return SurveyQuestion(
          title: q.titleController.text.trim(),
          isMultiChoice: q.isMultiChoice,
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
                    onChanged: (value) => setState(() => question.isMultiChoice = value),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

            // 选项
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 选项标签
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colorScheme.primary,
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
