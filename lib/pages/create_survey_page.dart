import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/survey_model.dart';
import '../services/kimi_service.dart';
import '../services/survey_storage.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';

class _OptionData {
  final TextEditingController contentController;

  _OptionData() : contentController = TextEditingController();

  void dispose() {
    contentController.dispose();
  }
}

class _QuestionData {
  final TextEditingController titleController;
  final TextEditingController scoreController;
  bool isMultiChoice;
  final List<_OptionData> options;
  dynamic correctAnswer;

  _QuestionData()
      : titleController = TextEditingController(),
        scoreController = TextEditingController(),
        isMultiChoice = false,
        options = [_OptionData()],
        correctAnswer = null;

  void dispose() {
    titleController.dispose();
    scoreController.dispose();
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
  bool _isGenerating = false;

  @override
  void dispose() {
    for (final q in _questions) {
      q.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showGenerateDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI 生成题目'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '可输入主题或要求，例如：围绕旅行偏好出题（可留空）',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          Y2KButton(
            label: '取消',
            kind: Y2KButtonKind.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          Y2KButton(
            label: '开始生成',
            kind: Y2KButtonKind.primary,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _autoGenerate(userInput: controller.text);
    }
    controller.dispose();
  }

  Future<void> _autoGenerate({String? userInput}) async {
    setState(() => _isGenerating = true);
    try {
      final raw = await KimiService.generateSurveyQuestions(userInput: userInput);
      for (final q in _questions) {
        q.dispose();
      }
      setState(() {
        _questions.clear();
        for (final item in raw) {
          final q = _QuestionData();
          q.titleController.text = item['title'] as String;
          q.isMultiChoice = item['isMultiChoice'] as bool;
          final ca = item['correctAnswer'];
          if (q.isMultiChoice) {
            q.correctAnswer = Set<int>.from((ca as List).cast<int>());
          } else {
            q.correctAnswer = ca as int;
          }
          q.scoreController.text = '${item['score'] ?? 10}';
          for (final opt in q.options) {
            opt.dispose();
          }
          q.options.clear();
          for (final optText in (item['options'] as List)) {
            final o = _OptionData();
            o.contentController.text = optText as String;
            q.options.add(o);
          }
          _questions.add(q);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionData());
    });
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

      if (!question.isMultiChoice) {
        if (question.correctAnswer == optionIndex) {
          question.correctAnswer = null;
        } else if (question.correctAnswer != null &&
            question.correctAnswer > optionIndex) {
          question.correctAnswer = (question.correctAnswer as int) - 1;
        }
      } else {
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
      SnackBar(content: Text(message)),
    );
  }

  void _setSingleCorrectAnswer(int qIndex, int oIndex) {
    setState(() {
      _questions[qIndex].correctAnswer = oIndex;
    });
  }

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

  String _getCorrectAnswerText(_QuestionData question) {
    if (question.correctAnswer == null) return '未设置';
    if (!question.isMultiChoice) {
      final idx = question.correctAnswer as int;
      if (idx >= 0 && idx < question.options.length) {
        return String.fromCharCode(65 + idx);
      }
      return '无效';
    } else {
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
      final scoreText = q.scoreController.text.trim();
      if (scoreText.isEmpty) {
        _showSnackBar('请设置第 ${i + 1} 题的分值');
        return false;
      }
      if (int.tryParse(scoreText) == null || int.parse(scoreText) <= 0) {
        _showSnackBar('第 ${i + 1} 题的分值必须为正整数');
        return false;
      }
      for (int j = 0; j < q.options.length; j++) {
        final o = q.options[j];
        if (o.contentController.text.trim().isEmpty) {
          _showSnackBar('第 ${i + 1} 题第 ${j + 1} 个选项的内容不能为空');
          return false;
        }
      }
      if (q.correctAnswer == null) {
        _showSnackBar('请为第 ${i + 1} 题设置我的答案');
        return false;
      }
    }
    return true;
  }

  Future<void> _startSurvey() async {
    if (_isGenerating) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('题目生成中'),
          content: const Text('题目正在自动生成，生成完成后才能提交测试。'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            Y2KButton(
              label: '知道了',
              kind: Y2KButtonKind.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }
    if (!_validate()) return;

    final uid = await UserStorage.getOrCreateUid();
    final userProfile = await UserStorage.load();
    final creatorBasicInfo = userProfile?.basicInfo ?? '';

    debugPrint('创建测试 - UID: $uid');
    debugPrint('创建测试 - 基础信息: "$creatorBasicInfo"');

    final survey = Survey(
      uid: uid,
      createdAt: DateTime.now(),
      creatorBasicInfo: creatorBasicInfo,
      questions: _questions.map((q) {
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
          questionScore: int.parse(q.scoreController.text.trim()),
          options: q.options.map((o) {
            return SurveyOption(
              content: o.contentController.text.trim(),
              score: 0,
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
    return Y2KScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemCount: _questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == _questions.length) return _buildAddQuestionButton();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _buildQuestionCard(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
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
                Text('CREATE · 出题', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                const Text(
                  '新建测试',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Y2K.ink),
                ),
              ],
            ),
          ),
          _isGenerating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Y2K.ink),
                )
              : Y2KButton(
                  label: 'AI 生成',
                  icon: Icons.auto_awesome_rounded,
                  kind: Y2KButtonKind.accent,
                  onPressed: _showGenerateDialog,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  fontSize: 13,
                ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        color: Y2K.bg,
        border: Border(top: BorderSide(color: Y2K.ink, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Y2KButton(
          label: '保存并发布 →',
          icon: Icons.check_rounded,
          kind: Y2KButtonKind.primary,
          block: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          fontSize: 16,
          onPressed: _startSurvey,
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Y2KButton(
        label: '+ 添加问题',
        kind: Y2KButtonKind.ghost,
        block: true,
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: _addQuestion,
      ),
    );
  }

  Widget _buildQuestionCard(int qIndex) {
    final question = _questions[qIndex];
    final hasCorrectAnswer = question.correctAnswer != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Y2KCard(
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Y2KTag(
                    label: 'SCORE',
                    background: Y2K.gold,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: question.scoreController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '10',
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Y2K.ink),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('分', style: Y2K.monoSm),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _removeQuestion(qIndex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Y2K.danger.withValues(alpha: 0.18),
                          border: Border.all(color: Y2K.ink, width: 1.5),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Y2K.ink),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: question.titleController,
                decoration: const InputDecoration(
                  labelText: '题目',
                  hintText: '输入题目内容…',
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildMultiToggle(question),
              const SizedBox(height: 12),
              _buildCorrectAnswerBanner(question, hasCorrectAnswer),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('OPTIONS', style: Y2K.mono.copyWith(fontSize: 10, color: Y2K.muted)),
                  const SizedBox(width: 6),
                  Text('· ${question.options.length}', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                ],
              ),
              const SizedBox(height: 8),
              ...question.options.asMap().entries.map(
                    (e) => _buildOptionRow(qIndex, e.key, e.value),
                  ),
              const SizedBox(height: 4),
              Y2KButton(
                label: '+ 添加选项',
                kind: Y2KButtonKind.ghost,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                fontSize: 13,
                onPressed: () => _addOption(qIndex),
              ),
            ],
          ),
        ),
        Positioned(
          top: -12,
          left: 16,
          child: Y2KChip(
            label: 'QUESTION ${(qIndex + 1).toString().padLeft(2, '0')}',
            background: Y2K.blue,
            foreground: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiToggle(_QuestionData question) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Y2K.chip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Y2K.ink, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            question.isMultiChoice ? Icons.check_box_outlined : Icons.radio_button_checked,
            size: 18,
            color: Y2K.ink,
          ),
          const SizedBox(width: 8),
          const Text('允许多选', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Y2K.ink)),
          const Spacer(),
          Switch(
            value: question.isMultiChoice,
            activeThumbColor: Y2K.pink,
            activeTrackColor: Y2K.pink.withValues(alpha: 0.4),
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
    );
  }

  Widget _buildCorrectAnswerBanner(_QuestionData question, bool hasCorrectAnswer) {
    final Color bg = hasCorrectAnswer ? Y2K.lime : Y2K.gold;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Y2K.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, size: 16, color: Y2K.ink),
              const SizedBox(width: 6),
              const Text(
                '我的答案',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Y2K.ink),
              ),
              const Spacer(),
              Y2KTag(
                label: _getCorrectAnswerText(question),
                background: Y2K.ink,
                foreground: Y2K.bg,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '点击下方选项字母来设置标准答案（用于匹配度计算）',
            style: Y2K.monoSm.copyWith(color: Y2K.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int qIndex, int oIndex, _OptionData option) {
    final label = String.fromCharCode(65 + oIndex);
    final question = _questions[qIndex];

    final isCorrectAnswer = !question.isMultiChoice
        ? question.correctAnswer == oIndex
        : (question.correctAnswer as Set<int>?)?.contains(oIndex) ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                color: isCorrectAnswer ? Y2K.ink : Y2K.card,
                shape: BoxShape.circle,
                border: Border.all(color: Y2K.ink, width: 1.5),
              ),
              child: isCorrectAnswer
                  ? const Icon(Icons.check, color: Y2K.lime, size: 16)
                  : Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Y2K.ink,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: option.contentController,
              decoration: InputDecoration(
                hintText: '选项 $label 内容',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _removeOption(qIndex, oIndex),
            icon: const Icon(Icons.close, size: 16),
            color: Y2K.ink,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
