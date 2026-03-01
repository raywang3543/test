import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/user_storage.dart';

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
    final profile = UserProfile(
      basicInfo: _basicInfoCtrl.text,
      detailedInfo: _detailedInfoCtrl.text,
      passingScore: int.tryParse(_passingScoreCtrl.text.trim()),
    );
    await UserStorage.save(profile);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('编辑信息'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('保存'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _buildSection(
            title: '基础信息',
            icon: Icons.person_outline_rounded,
            child: TextField(
              controller: _basicInfoCtrl,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '在此填写基础信息...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '详细信息',
            icon: Icons.info_outline_rounded,
            child: TextField(
              controller: _detailedInfoCtrl,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '在此填写详细信息...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '测试设置',
            icon: Icons.tune_rounded,
            child: TextField(
              controller: _passingScoreCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: '合格分数',
                hintText: '输入合格分数线',
                helperText: '答题结果达到该分数视为合格',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
