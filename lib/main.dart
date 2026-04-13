import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/pages/permission_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MiaoMiaoApp(),
    ),
  );
}

class MiaoMiaoApp extends StatelessWidget {
  const MiaoMiaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '喵喵补光灯',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      // Initially showing the Permission/Onboarding page
      home: const PermissionPage(),
    );
  }
}
