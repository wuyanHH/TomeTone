import 'package:flutter/material.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/ui/app_shell.dart';

/// 应用根 widget（UI 层）：只装配 `MaterialApp` 与主题，不含业务策略。
class TomeToneApp extends StatelessWidget {
  /// 创建应用根 widget。
  const TomeToneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8C6A3F)),
      ),
      home: const AppShell(),
    );
  }
}
