import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/contracts/sources/source_import_loader.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 导入弹层的稳定测试键。
abstract final class SourceImportSheetKeys {
  static const Key urlFieldKey = Key('source-import-url');
  static const Key loadUrlButtonKey = Key('source-import-load-url');
  static const Key pickFileButtonKey = Key('source-import-pick-file');
  static const Key pasteFieldKey = Key('source-import-paste');
  static const Key importButtonKey = Key('source-import-submit');
  static const Key overwriteSwitchKey = Key('source-import-overwrite');
  static const Key errorKey = Key('source-import-error');
  static const Key resultsKey = Key('source-import-results');
  static const Key closeButtonKey = Key('source-import-close');
  static const Key doneButtonKey = Key('source-import-done');
}

Future<bool?> showSourceImportSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const SourceImportSheet(),
  );
}

/// 书源导入弹层：URL / 文件 / 粘贴三条输入路径。
class SourceImportSheet extends ConsumerStatefulWidget {
  const SourceImportSheet({super.key});

  @override
  ConsumerState<SourceImportSheet> createState() => _SourceImportSheetState();
}

class _SourceImportSheetState extends ConsumerState<SourceImportSheet> {
  final TextEditingController _url = TextEditingController();
  final TextEditingController _paste = TextEditingController();

  bool _overwrite = false;
  bool _loading = false;
  bool _importing = false;
  int _tabIndex = 0;
  String? _fileLabel;
  String? _loadedText;
  int? _loadedTab;
  String? _error;
  List<SourceImportOutcome>? _outcomes;
  bool _hasSuccess = false;

  @override
  void dispose() {
    _url.dispose();
    _paste.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top;
    final height = math.min(availableHeight * 0.9, 720.0);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.lgValue),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: height,
          child: DefaultTabController(
            length: 3,
            child: Builder(
              builder: (BuildContext context) {
                final controller = DefaultTabController.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        0,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '导入书源',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            key: SourceImportSheetKeys.closeButtonKey,
                            tooltip: '关闭',
                            onPressed: () =>
                                Navigator.of(context).pop(_hasSuccess),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      onTap: (int index) {
                        setState(() => _tabIndex = index);
                      },
                      tabs: const <Widget>[
                        Tab(text: 'URL'),
                        Tab(text: '文件'),
                        Tab(text: '粘贴'),
                      ],
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: controller,
                        builder: (BuildContext context, Widget? child) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _tabContent(_tabIndex),
                                const SizedBox(height: AppSpacing.md),
                                SwitchListTile(
                                  key: SourceImportSheetKeys.overwriteSwitchKey,
                                  contentPadding: EdgeInsets.zero,
                                  value: _overwrite,
                                  onChanged: _importing
                                      ? null
                                      : (bool value) {
                                          setState(() => _overwrite = value);
                                        },
                                  title: const Text('覆盖同 URL 书源'),
                                  subtitle: const Text('关闭时，已存在的书源会显示为已跳过。'),
                                ),
                                if (_error != null) ...<Widget>[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _error!,
                                    key: SourceImportSheetKeys.errorKey,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ],
                                if (_outcomes != null) ...<Widget>[
                                  const SizedBox(height: AppSpacing.md),
                                  _ImportResults(
                                    outcomes: _outcomes!,
                                    hasSuccess: _hasSuccess,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton(
                                key: SourceImportSheetKeys.importButtonKey,
                                onPressed: _importing ? null : _import,
                                child: _importing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('导入'),
                              ),
                            ),
                            if (_outcomes != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              OutlinedButton(
                                key: SourceImportSheetKeys.doneButtonKey,
                                onPressed: () =>
                                    Navigator.of(context).pop(_hasSuccess),
                                child: Text(_hasSuccess ? '完成' : '关闭'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabContent(int index) {
    return switch (index) {
      0 => _buildUrlTab(),
      1 => _buildFileTab(),
      _ => _buildPasteTab(),
    };
  }

  Widget _buildUrlTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: SourceImportSheetKeys.urlFieldKey,
          controller: _url,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '书源 JSON URL',
            hintText: 'https://example.com/source.json',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: SourceImportSheetKeys.loadUrlButtonKey,
            onPressed: _loading ? null : _loadUrl,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('读取'),
          ),
        ),
        if (_loadedTab == 0) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '已读取 ${_loadedText?.length ?? 0} 个字符，可以导入。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildFileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton.icon(
          key: SourceImportSheetKeys.pickFileButtonKey,
          onPressed: _loading ? null : _pickFile,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_open_rounded),
          label: const Text('选择 JSON 文件'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _loadedTab == 1 && _fileLabel != null ? '已选择：$_fileLabel' : '未选择文件',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPasteTab() {
    return TextField(
      key: SourceImportSheetKeys.pasteFieldKey,
      controller: _paste,
      minLines: 6,
      maxLines: 10,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        labelText: '书源 JSON',
        hintText: '粘贴 Legado 听书源 JSON',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Future<void> _loadUrl() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = '请输入书源 URL。');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _loadedTab = null;
      _loadedText = null;
    });
    try {
      final content = await ref
          .read(sourceImportLoaderProvider)
          .loadFromUrl(url);
      if (!mounted) {
        return;
      }
      if (content.trim().isEmpty) {
        setState(() => _error = '读取到的内容为空。');
        return;
      }
      setState(() {
        _loadedText = content;
        _loadedTab = 0;
        _fileLabel = null;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = _readableError(error, fallback: '读取失败，请检查地址后重试。'),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SourceImportFile? file = await ref
          .read(sourceImportLoaderProvider)
          .pickJsonFile();
      if (!mounted) {
        return;
      }
      if (file == null) {
        return;
      }
      if (file.content.trim().isEmpty) {
        setState(() => _error = '所选文件内容为空。');
        return;
      }
      setState(() {
        _fileLabel = file.name;
        _loadedText = file.content;
        _loadedTab = 1;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _readableError(error, fallback: '文件读取失败，请重新选择。'));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _import() async {
    final String text;
    if (_tabIndex == 2) {
      text = _paste.text;
    } else if (_loadedTab == _tabIndex) {
      text = _loadedText ?? '';
    } else {
      text = '';
    }
    if (text.trim().isEmpty) {
      setState(() => _error = '请先读取或粘贴书源 JSON。');
      return;
    }

    setState(() {
      _importing = true;
      _error = null;
      _outcomes = null;
      _hasSuccess = false;
    });
    try {
      final outcomes = await ref
          .read(bookSourceServiceProvider)
          .importText(text, overwrite: _overwrite);
      if (!mounted) {
        return;
      }
      setState(() {
        _outcomes = outcomes;
        _hasSuccess = outcomes.any(
          (outcome) => outcome.status != SourceImportStatus.invalid,
        );
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _error = '导入失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  String _readableError(Object error, {required String fallback}) {
    if (error is ArgumentError) {
      return '只支持 http(s) 书源地址。';
    }
    if (error is FormatException) {
      return error.message;
    }
    if (error is TimeoutException) {
      return '读取超时，请检查网络后重试。';
    }
    if (error is HttpException) {
      final match = RegExp(r'HTTP\s+(\d{3})').firstMatch(error.message);
      return match == null ? '下载书源失败，请稍后重试。' : '下载书源失败：HTTP ${match.group(1)}';
    }
    return fallback;
  }
}

class _ImportResults extends StatelessWidget {
  const _ImportResults({required this.outcomes, required this.hasSuccess});

  final List<SourceImportOutcome> outcomes;
  final bool hasSuccess;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: SourceImportSheetKeys.resultsKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          hasSuccess ? '导入结果' : '导入失败',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final outcome in outcomes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: _OutcomeRow(outcome: outcome),
          ),
      ],
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.outcome});

  final SourceImportOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, String label, Color color) = switch (outcome.status) {
      SourceImportStatus.imported => (
        Icons.check_circle_outline,
        '已导入',
        scheme.primary,
      ),
      SourceImportStatus.updated => (Icons.sync_rounded, '已更新', scheme.primary),
      SourceImportStatus.skipped => (
        Icons.skip_next_rounded,
        '已跳过（已存在）',
        scheme.onSurfaceVariant,
      ),
      SourceImportStatus.invalid => (
        Icons.error_outline,
        '失败：${outcome.message ?? '未知错误'}',
        scheme.error,
      ),
    };
    final name = outcome.name?.trim();
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (name != null && name.isNotEmpty)
                Text(
                  name,
                  style: bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              Text(label, style: bodySmall?.copyWith(color: color)),
            ],
          ),
        ),
      ],
    );
  }
}
