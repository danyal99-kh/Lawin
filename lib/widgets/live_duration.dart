import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/persian_format.dart';

/// مدت زمان زنده از [since] تا اکنون (مثل ۰۱:۳۳:۰۵) که هر ثانیه به‌روز می‌شود.
/// فقط همین Text دوباره ساخته می‌شود، نه کل صفحه.
class LiveDuration extends StatefulWidget {
  const LiveDuration({super.key, required this.since, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  State<LiveDuration> createState() => _LiveDurationState();
}

class _LiveDurationState extends State<LiveDuration> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since);
    return Text(
      PersianFormat.clockDuration(elapsed.isNegative ? Duration.zero : elapsed),
      style: widget.style,
    );
  }
}