import 'package:flutter/material.dart';
import 'package:tometone/app/app_info.dart';

/// 应用外壳。
///
/// 目标形态（《架构需求文档》3.1）：手机纵屏单列 + 底部 MiniPlayer + 底 3 栏
/// （书架 / 纪年 / 设置）。真实页面在 Step 6 落地；此处仅保留最小骨架，
/// 用于打通"装配 → 首屏"链路并作为冒烟测试锚点。
class AppShell extends StatelessWidget {
  /// 创建应用外壳。
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(AppInfo.appName, style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(AppInfo.appNameLatin, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(
              'v${AppInfo.version} · ${AppInfo.channel.label}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
