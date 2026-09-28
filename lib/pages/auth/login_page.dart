import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final failure =
        await context.read<AuthProvider>().login(_user.text, _pass.text);
    if (mounted && failure != null) {
      setState(() => _error = failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.local_cafe,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(AppConstants.appName,
                    textAlign: TextAlign.center, style: theme.titleLarge),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _user,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'نام کاربری'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => busy ? null : _submit(),
                  decoration: const InputDecoration(labelText: 'رمز عبور'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!,
                      style:
                          theme.bodySmall?.copyWith(color: AppColors.danger)),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('ورود'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
