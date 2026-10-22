import 'package:flutter/material.dart';
import 'package:tometone/ui/pages/settings/cache_settings_section.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 存储与缓存二级页面。
class CacheSettingsPage extends StatelessWidget {
  const CacheSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储与缓存'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
            child: const CacheSettingsSection(),
          ),
        ),
      ),
    );
  }
}
