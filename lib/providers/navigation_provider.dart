import 'package:flutter/foundation.dart';

import '../pages/shell/app_destination.dart';

/// بخش فعال برنامه. هر صفحه‌ای می‌تواند به بخش دیگر برود
/// (مثلاً «مشاهده انبار» در هشدار داشبورد).
class NavigationProvider extends ChangeNotifier {
  AppDestination _current = AppDestination.dashboard;
  AppDestination get current => _current;

  void select(AppDestination destination) {
    if (destination == _current) return;
    _current = destination;
    notifyListeners();
  }
}
