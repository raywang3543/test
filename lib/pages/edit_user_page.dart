import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';
import '../theme/y2k_theme.dart';
import '../theme/y2k_widgets.dart';

class EditUserPage extends StatefulWidget {
  final UserProfile profile;

  const EditUserPage({super.key, required this.profile});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late final TextEditingController _basicInfoCtrl;
  late final TextEditingController _detailedInfoCtrl;
  late final TextEditingController _passingScoreCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _basicInfoCtrl = TextEditingController(text: p.basicInfo);
    _detailedInfoCtrl = TextEditingController(text: p.detailedInfo);
    _passingScoreCtrl =
        TextEditingController(text: p.passingScore?.toString() ?? '');
  }

  @override
  void dispose() {
    _basicInfoCtrl.dispose();
    _detailedInfoCtrl.dispose();
    _passingScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final profile = UserProfile(
        basicInfo: _basicInfoCtrl.text,
        detailedInfo: _detailedInfoCtrl.text,
        passingScore: int.tryParse(_passingScoreCtrl.text.trim()),
      );

      await UserStorage.save(profile);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('保存失败: $e');
      debugPrint('堆栈: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Y2K.pink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Y2KScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildHero(),
              const SizedBox(height: 22),
              _buildSection(
                indexLabel: '01',
                title: '基础信息',
                subtitle: 'PUBLIC · 所有人可见',
                accent: Y2K.lime,
                icon: Icons.person_outline_rounded,
                child: _buildTextField(
                  controller: _basicInfoCtrl,
                  hint: '在此填写基础信息…',
                  maxLines: 6,
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                indexLabel: '02',
                title: '详细信息',
                subtitle: 'PRIVATE · 合格后可见',
                accent: Y2K.blue,
                icon: Icons.lock_outline_rounded,
                child: _buildTextField(
                  controller: _detailedInfoCtrl,
                  hint: '在此填写详细信息…',
                  maxLines: 6,
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                indexLabel: '03',
                title: '合格分数',
                subtitle: 'SCORE · 解锁条件',
                accent: Y2K.gold,
                icon: Icons.tune_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _passingScoreCtrl,
                      hint: '输入合格分数线',
                      maxLines: 1,
                      keyboardType:
                          const TextInputType.numberWithOptions(signed: true),
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('答题达到该分数即视为合格', style: Y2K.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Y2KChip(
          label: '← 返回',
          background: Colors.transparent,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        Y2KButton(
          label: '保存',
          icon: Icons.check_rounded,
          kind: Y2KButtonKind.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          fontSize: 13,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EDIT · 编辑资料', style: Y2K.mono.copyWith(color: Y2K.muted)),
        const SizedBox(height: 10),
        const Text(
          '你的信息',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Y2K.ink,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: const [
            Y2KChip(label: '本地加密'),
            Y2KChip(label: 'EDITABLE', background: Y2K.lime),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String indexLabel,
    required String title,
    required String subtitle,
    required Color accent,
    required IconData icon,
    required Widget child,
  }) {
    return Y2KCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    color: accent == Y2K.blue ? Colors.white : Y2K.ink,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: Y2K.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Y2K.ink,
                      ),
                    ),
                    Text(subtitle,
                        style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Y2KDashedDivider(),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Y2K.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Y2K.ink, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: const TextStyle(
          fontSize: 14.5,
          color: Y2K.ink,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Y2K.monoSm.copyWith(color: Y2K.muted, fontSize: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
