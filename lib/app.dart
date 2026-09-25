import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'pages/shell/app_shell.dart';
import 'providers/app_providers.dart';

class CafeBookAdminApp extends StatelessWidget {
  const CafeBookAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // کاملاً فارسی و RTL
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          // جلوگیری از Overflow ناشی از بزرگ‌کردن بیش‌ازحد فونت سیستم.
          final mq = MediaQuery.of(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AppShell(),
      ),
    );
  }
}
