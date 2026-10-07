import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/state_views.dart';
import 'widgets/security_settings_card.dart';
import 'widgets/settings_form.dart';
import 'widgets/welcome_settings_card.dart';

/// تنظیمات کلی برنامه: اطلاعات کافه، رفتار چاپ و هشدارها.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SettingsProvider>();
      provider.load();
      provider.loadWelcome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final theme = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () => Future.wait([provider.load(), provider.loadWelcome()]),
      child: AsyncStateView<AppSettings>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, settings) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsForm(settings: settings),
                const SizedBox(height: AppSpacing.xxl),
                const SecuritySettingsCard(),
                const SizedBox(height: AppSpacing.xxl),
                AsyncStateView<WelcomeSettings>(
                  state: provider.welcomeState,
                  onRetry: provider.loadWelcome,
                  builder: (context, welcome) =>
                      WelcomeSettingsCard(welcome: welcome),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Text('${AppConstants.appName} — نسخه ۰٫۱٫۰',
                      style: theme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
