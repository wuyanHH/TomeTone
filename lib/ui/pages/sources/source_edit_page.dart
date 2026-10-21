import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 编辑页的稳定测试键。
abstract final class SourceEditPageKeys {
  static const Key nameFieldKey = Key('source-edit-name');
  static const Key groupFieldKey = Key('source-edit-group');
  static const Key rawFieldKey = Key('source-edit-raw');
  static const Key enabledSwitchKey = Key('source-edit-enabled');
  static const Key exploreSwitchKey = Key('source-edit-explore');
  static const Key saveButtonKey = Key('source-edit-save');
  static const Key errorKey = Key('source-edit-error');
}

/// 编辑单个书源的可变元数据。
///
/// 原始 JSON 是规则的唯一事实来源；名称/分组/启用状态是表单覆盖层。
/// URL 是身份，不允许在这里修改；header 不单独展示，只保留在原始 JSON 中。
class SourceEditPage extends ConsumerStatefulWidget {
  const SourceEditPage({super.key, required this.source});

  final BookSource source;

  @override
  ConsumerState<SourceEditPage> createState() => _SourceEditPageState();
}

class _SourceEditPageState extends ConsumerState<SourceEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _group;
  late final TextEditingController _raw;
  late bool _enabled;
  late bool _enabledExplore;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.source.name);
    _group = TextEditingController(text: widget.source.groupName ?? '');
    _raw = TextEditingController(text: _prettyJson(widget.source.rawJson));
    _enabled = widget.source.enabled;
    _enabledExplore = widget.source.enabledExplore;
  }

  @override
  void dispose() {
    _name.dispose();
    _group.dispose();
    _raw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑书源'),
        actions: <Widget>[
          TextButton(
            key: SourceEditPageKeys.saveButtonKey,
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '保存'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                key: SourceEditPageKeys.nameFieldKey,
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: SourceEditPageKeys.groupFieldKey,
                controller: _group,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '分组',
                  hintText: '留空表示未分组',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                key: SourceEditPageKeys.enabledSwitchKey,
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (bool value) => setState(() => _enabled = value),
                title: const Text('启用书源'),
                subtitle: const Text('停用后不再出现在发现与搜索中。'),
              ),
              SwitchListTile(
                key: SourceEditPageKeys.exploreSwitchKey,
                contentPadding: EdgeInsets.zero,
                value: _enabledExplore,
                onChanged: (bool value) {
                  setState(() => _enabledExplore = value);
                },
                title: const Text('在发现页启用'),
                subtitle: const Text('只影响发现分类，不影响搜索。'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('原始 JSON', style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '完整保存 Legado 规则。header 等敏感字段不会在这里单独展示。',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: SourceEditPageKeys.rawFieldKey,
                controller: _raw,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  key: SourceEditPageKeys.errorKey,
                  style: text.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '名称不能为空。');
      return;
    }
    final raw = _raw.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = '原始 JSON 不能为空。');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref.read(bookSourceServiceProvider).parse(raw);
      if (!mounted) {
        return;
      }
      if (result.candidates.length != 1) {
        setState(() {
          _error = result.issues.isNotEmpty
              ? result.issues.first.message
              : '原始 JSON 必须恰好包含一个书源。';
        });
        return;
      }
      if (result.issues.isNotEmpty) {
        setState(() => _error = result.issues.first.message);
        return;
      }

      final candidate = result.candidates.single;
      if (candidate.draft.sourceUrl != widget.source.sourceUrl) {
        setState(() => _error = '书源 URL 是身份，不能在这里修改');
        return;
      }

      final group = _group.text.trim();
      final draft = BookSourceDraft(
        name: name,
        sourceUrl: candidate.draft.sourceUrl,
        sourceType: candidate.draft.sourceType,
        rawJson: candidate.draft.rawJson,
        header: candidate.draft.header,
        groupName: group.isEmpty ? null : group,
        exploreUrl: candidate.draft.exploreUrl,
        searchUrl: candidate.draft.searchUrl,
        jsLib: candidate.draft.jsLib,
        enabled: _enabled,
        enabledExplore: _enabledExplore,
        customOrder: candidate.draft.customOrder,
        concurrentRate: candidate.draft.concurrentRate,
      );
      await ref
          .read(bookSourceServiceProvider)
          .updateFromDraft(widget.source.id, draft);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = '保存失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } on FormatException {
      return raw;
    }
  }
}
