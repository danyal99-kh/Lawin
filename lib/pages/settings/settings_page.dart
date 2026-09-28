import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/state_views.dart';
import 'widgets/settings_form.dart';

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
      if (mounted) context.read<SettingsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: AsyncStateView<AppSettings>(
        state: provider.state,
        onRetry: provider.load,
        builder: (context, settings) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            maxWidth: 760,
            child: SettingsForm(settings: settings),
          ),
        ),
      ),
    );
  }
}
