import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';

/// جزئیات را در دسکتاپ به‌صورت Dialog و در موبایل/تبلت به‌صورت Bottom Sheet نشان می‌دهد.
/// محتوای [builder] باید خودش Scroll داشته باشد.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxDialogWidth = 520,
}) {
  if (context.isDesktop) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: builder(ctx),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}