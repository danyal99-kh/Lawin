import 'package:cafe_book_admin/widgets/state_views.dart';
import 'package:flutter/material.dart';

import '../../core/utils/persian_format.dart';
import 'app_destination.dart';

/// جایگزین موقت بخش‌هایی که هنوز پیاده‌سازی نشده‌اند.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.destination});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: destination.icon,
        title: destination.label,
        message:
            'این بخش در مرحله‌ی ${PersianFormat.digits(destination.plannedStage)} پیاده‌سازی می‌شود.',
      );
}
