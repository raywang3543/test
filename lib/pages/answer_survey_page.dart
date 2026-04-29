import 'package:flutter/material.dart';
import '../models/analysis_result_model.dart';
import '../models/survey_model.dart';
import '../services/deepseek_server.dart';
import '../services/survey_result_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';

class AnswerSurveyPage extends StatefulWidget {
  final Survey survey;

  const AnswerSurveyPage({super.key, required this.survey});

  @override
  State<AnswerSurveyPage> createState() => _AnswerSurveyPageState();
}

class _AnswerSurveyPageState extends State<AnswerSurveyPage> {
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
    setState(() {
      _isAnalyzing = true;
      _submitted = true;
    });

    final result = await DeepseekServer.analyzePersonalityDetailed(
      survey: widget.survey,
      answers: _answers,
    );

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
    return Y2KScaffold(
      dots: !_submitted,
      body: _submitted ? _buildResultScreen() : _buildQuizScreen(),
      bottomNavigationBar:
          !_submitted && _allAnswered ? _buildSubmitBar() : null,
    );
  }

  // ── Quiz ────────────────────────────────────────────────────────────────

  Widget _buildQuizScreen() {
    final total = widget.survey.questions.length;
    final answered = _answeredCount;
    final progress = total > 0 ? answered / total : 0.0;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Y2KChip(
                  label: '← 退出',
                  background: Colors.transparent,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  '${answered.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                  style: Y2K.mono.copyWith(fontSize: 13),
                ),
                const SizedBox(width: 10),
                Y2KChip(
                  label: '${(progress * 100).toStringAsFixed(0)}%',
                  background: Y2K.lime,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Y2KSegBar(total: total, current: answered),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('已答 $answered / $total', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                Text('凭直觉作答 →', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: widget.survey.questions.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: _buildQuestionCard(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int qIndex) {
    final question = widget.survey.questions[qIndex];
    final answer = _answers[qIndex];
    final isAnswered = answer is Set<int> ? answer.isNotEmpty : answer != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Y2KCard(
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Y2KTag(
                    label: '${question.questionScore} PT',
                    background: Y2K.gold,
                  ),
                  const SizedBox(width: 6),
                  if (question.isMultiChoice)
                    const Y2KTag(
                      label: 'MULTI',
                      background: Y2K.pink,
                      foreground: Colors.white,
                    ),
                  const Spacer(),
                  if (isAnswered)
                    const Icon(Icons.check_circle, color: Y2K.ink, size: 22)
                  else
                    const Icon(Icons.circle_outlined, color: Y2K.muted, size: 22),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '"想一个最近的日常场景……"',
                style: Y2K.serifItalic,
              ),
              const SizedBox(height: 8),
              Text(
                question.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  color: Y2K.ink,
                ),
              ),
              if (question.isMultiChoice)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '可多选',
                    style: Y2K.monoSm.copyWith(color: Y2K.pink),
                  ),
                ),
              const SizedBox(height: 14),
              ...question.options.asMap().entries.map(
                    (e) => _buildOptionTile(qIndex, e.key, e.value, question.isMultiChoice),
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

  Widget _buildOptionTile(int qIndex, int oIndex, SurveyOption option, bool isMultiChoice) {
    final answer = _answers[qIndex];
    final isSelected = isMultiChoice
        ? (answer as Set<int>).contains(oIndex)
        : answer == oIndex;

    final accents = [Y2K.lime, Y2K.pink, Y2K.blue, Y2K.gold];
    final accent = accents[oIndex % accents.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accent : Y2K.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Y2K.ink, width: 1.5),
            boxShadow: isSelected ? Y2K.shadow(offset: 3) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Y2K.ink : Y2K.card,
                  shape: isMultiChoice ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isMultiChoice ? BorderRadius.circular(6) : null,
                  border: Border.all(color: Y2K.ink, width: 1.5),
                ),
                child: Text(
                  String.fromCharCode(65 + oIndex),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Y2K.bg : Y2K.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: Y2K.ink,
                    height: 1.4,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, size: 20, color: Y2K.ink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: const BoxDecoration(
        color: Y2K.bg,
        border: Border(top: BorderSide(color: Y2K.ink, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Y2KButton(
          label: '提交答案 →',
          icon: Icons.send_rounded,
          kind: Y2KButtonKind.primary,
          block: true,
          fontSize: 16,
          padding: const EdgeInsets.symmetric(vertical: 16),
          onPressed: _submit,
        ),
      ),
    );
  }

  // ── Result ──────────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    if (_isAnalyzing) {
      return _buildAnalyzingView();
    }
    if (_analysisResult == null) {
      return const Center(child: Text('分析失败，请重试'));
    }

    final result = _analysisResult!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResultHero(result),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAnalysisSection(
                    indexLabel: '01',
                    title: '出题者性格分析',
                    accent: Y2K.blue,
                    content: result.creatorAnalysis,
                  ),
                  const SizedBox(height: 14),
                  _buildAnalysisSection(
                    indexLabel: '02',
                    title: '做题者性格分析',
                    accent: Y2K.lime,
                    content: result.playerAnalysis,
                  ),
                  const SizedBox(height: 14),
                  _buildAnalysisSection(
                    indexLabel: '03',
                    title: '朋友匹配度',
                    accent: Y2K.gold,
                    content: result.sameGenderCompatibility,
                  ),
                  const SizedBox(height: 14),
                  _buildAnalysisSection(
                    indexLabel: '04',
                    title: '伴侣匹配度',
                    accent: Y2K.pink,
                    aiBadge: !result.creatorAnalysis.startsWith('⚠️'),
                    content: result.oppositeGenderCompatibility,
                  ),
                  const SizedBox(height: 22),
                  Text('每题得分详情', style: Y2K.mono.copyWith(color: Y2K.muted)),
                  const SizedBox(height: 10),
                  ...result.questionResults.map(_buildQuestionResultCard),
                  const SizedBox(height: 24),
                  Y2KButton(
                    label: '完成 · 回到首页',
                    kind: Y2KButtonKind.primary,
                    block: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    fontSize: 16,
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHero(PersonalityAnalysisResult result) {
    final pct = result.overallMatchPercentage;
    Color rarityColor;
    String rarityLabel;
    if (pct >= 80) {
      rarityColor = Y2K.lime;
      rarityLabel = 'RARE · 天作之合';
    } else if (pct >= 50) {
      rarityColor = Y2K.gold;
      rarityLabel = 'NORMAL · 默契满满';
    } else {
      rarityColor = Y2K.pink;
      rarityLabel = 'UNIQUE · 互补型';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Y2K.lime,
        border: Border(bottom: BorderSide(color: Y2K.ink, width: Y2K.borderWidth)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Y2KChip(
                label: '← 关闭',
                background: Y2K.bg,
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const Spacer(),
              const Y2KChip(label: 'RESULT · 2026', background: Y2K.bg),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.rotate(
                angle: -0.05,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                  decoration: BoxDecoration(
                    color: Y2K.ink,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Y2K.ink, width: 3),
                  ),
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      color: Y2K.bg,
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Sparkle(size: 18, color: Y2K.pink),
              const SizedBox(width: 8),
              Text(
                '你们的总体匹配度',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Y2K.ink),
              ),
              const SizedBox(width: 8),
              const Sparkle(size: 18, color: Y2K.blue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '总分 ${result.totalScore} / ${result.fullTotalScore} · 共 ${result.questionResults.length} 题',
            style: Y2K.mono.copyWith(color: Y2K.ink2, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Y2KChip(label: rarityLabel, background: rarityColor),
              const Y2KChip(label: '本地结果 · 可删除', background: Y2K.bg),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String indexLabel,
    required String title,
    required Color accent,
    required String content,
    bool aiBadge = false,
  }) {
    return Y2KCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Y2K.ink, width: 1.5),
                ),
                child: Text(
                  indexLabel,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: accent == Y2K.pink || accent == Y2K.blue ? Colors.white : Y2K.ink,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Y2K.ink,
                  ),
                ),
              ),
              if (aiBadge) const Y2KTag(label: '✦ AI', background: Y2K.blue, foreground: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          const Y2KDashedDivider(),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.75,
              color: Y2K.ink2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResultCard(QuestionAnalysisResult result) {
    Color matchColor;
    if (result.matchPercentage >= 80) {
      matchColor = Y2K.lime;
    } else if (result.matchPercentage >= 50) {
      matchColor = Y2K.gold;
    } else {
      matchColor = Y2K.pink;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Y2KCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Y2KChip(
                  label: 'Q${(result.questionIndex + 1).toString().padLeft(2, '0')}',
                  background: Y2K.ink,
                  foreground: Y2K.bg,
                ),
                const Spacer(),
                Y2KTag(label: '匹配 ${result.matchPercentage}%', background: matchColor, foreground: matchColor == Y2K.pink ? Colors.white : Y2K.ink),
                const SizedBox(width: 6),
                Y2KTag(label: '${result.actualScore}/${result.fullScore}', background: Y2K.blue, foreground: Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.questionTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4, color: Y2K.ink),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Y2K.chip,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Y2K.ink, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kvRow('出题者', result.creatorAnswer, Y2K.blue),
                  const SizedBox(height: 6),
                  _kvRow('做题者', result.playerAnswer, Y2K.pink),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: matchColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Y2K.ink, width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Y2K.ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.reason,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Y2K.ink2),
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

  Widget _kvRow(String k, String v, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$k  ', style: Y2K.monoSm.copyWith(color: Y2K.muted)),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(fontSize: 12.5, color: Y2K.ink, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SpinningRing(),
            const SizedBox(height: 28),
            Text('ANALYZING · …', style: Y2K.mono.copyWith(color: Y2K.muted)),
            const SizedBox(height: 10),
            const Text(
              '正在解码你们的匹配度',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Y2K.ink, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text('AI 正在比对答案、计算契合度…', style: Y2K.bodyMuted),
          ],
        ),
      ),
    );
  }
}

class _SpinningRing extends StatefulWidget {
  const _SpinningRing();

  @override
  State<_SpinningRing> createState() => _SpinningRingState();
}

class _SpinningRingState extends State<_SpinningRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.rotate(
        angle: _c.value * 6.28,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Y2K.ink, width: 3),
            gradient: const SweepGradient(
              colors: [Y2K.lime, Y2K.pink, Y2K.blue, Y2K.gold, Y2K.lime],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Y2K.bg,
              border: Border.all(color: Y2K.ink, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text(
              '?_?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Y2K.ink),
            ),
          ),
        ),
      ),
    );
  }
}
