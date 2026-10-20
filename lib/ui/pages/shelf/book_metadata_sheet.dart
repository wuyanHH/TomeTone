import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/book_metadata_service.dart';
import 'package:tometone/app/providers/metadata_providers.dart';
import 'package:tometone/contracts/storage/book_metadata_file_store.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 打开元数据编辑弹层；保存成功返回 `true`，取消 / 失败返回 `false` 或 null。
Future<bool?> showBookMetadataSheet(
  BuildContext context, {
  required BookSummary book,
  required String rootUri,
  required BookMetadataDraft initial,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return _BookMetadataSheet(book: book, rootUri: rootUri, initial: initial);
    },
  );
}

class _BookMetadataSheet extends ConsumerStatefulWidget {
  const _BookMetadataSheet({
    required this.book,
    required this.rootUri,
    required this.initial,
  });

  final BookSummary book;
  final String rootUri;
  final BookMetadataDraft initial;

  @override
  ConsumerState<_BookMetadataSheet> createState() => _BookMetadataSheetState();
}

class _BookMetadataSheetState extends ConsumerState<_BookMetadataSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _narrator;
  late final TextEditingController _series;
  late final TextEditingController _seriesIndex;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  bool _saving = false;
  List<String> _tagPreview = const <String>[];

  @override
  void initState() {
    super.initState();
    final BookMetadataDraft initial = widget.initial.normalized();
    _title = TextEditingController(text: initial.title ?? widget.book.title);
    _author = TextEditingController(text: initial.author ?? '');
    _narrator = TextEditingController(text: initial.narrator ?? '');
    _series = TextEditingController(text: initial.seriesName ?? '');
    _seriesIndex = TextEditingController(
      text: initial.seriesIndex?.toString() ?? '',
    );
    _description = TextEditingController(text: initial.description ?? '');
    _tags = TextEditingController(text: initial.tags.join('，'));
    _tagPreview = normalizeTags(initial.tags);
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _narrator.dispose();
    _series.dispose();
    _seriesIndex.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String? seriesText = _trimmedOrNull(_seriesIndex.text);
    final int? seriesIndex = seriesText == null
        ? null
        : int.tryParse(seriesText);
    if (seriesText != null && seriesIndex == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('系列序号必须是数字')));
      return;
    }

    final BookMetadataDraft draft = BookMetadataDraft(
      title: _title.text,
      author: _author.text,
      narrator: _narrator.text,
      seriesName: _series.text,
      seriesIndex: seriesIndex,
      description: _description.text,
      tags: normalizeTags(<String>[_tags.text]),
    ).normalized();

    setState(() => _saving = true);
    try {
      final MetadataSaveResult result = await ref
          .read(bookMetadataServiceProvider)
          .save(book: widget.book, rootUri: widget.rootUri, draft: draft);
      if (!mounted) {
        return;
      }
      final String message = switch (result.sidecarStatus) {
        BookMetadataWriteStatus.written => '已保存到应用与书根',
        BookMetadataWriteStatus.unsupported => '已保存到应用内，书根文件未写入',
        BookMetadataWriteStatus.failed => '已保存到应用内，书根写入失败',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存失败，请稍后再试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final EdgeInsets insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('编辑元数据', style: text.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '只改应用内记录，并尽力同步到书根',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '书名 *',
                  hintText: '例如：长夜行舟',
                ),
                validator: (String? value) =>
                    (value ?? '').trim().isEmpty ? '书名不能为空' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _author,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: '作者'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _narrator,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: '演播'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _series,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: '系列'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _seriesIndex,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: '序号'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _tags,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '标签',
                  hintText: '用逗号分隔，如 武侠, 长篇',
                ),
                onChanged: (String value) {
                  setState(() {
                    _tagPreview = normalizeTags(<String>[value]);
                  });
                },
              ),
              if (_tagPreview.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    for (final String tag in _tagPreview)
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: '简介',
                  alignLabelWithHint: true,
                  hintText: '一句话或一段话，方便在书架快速认出这本书',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '保存后会刷新书架与详情页',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? '保存中…' : '保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _trimmedOrNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
