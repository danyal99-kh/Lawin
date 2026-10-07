/// وضعیت باز/بسته بودن کافه، از `GET /api/v1/cafe/status/`.
///
/// **منبع حقیقت این وضعیت Backend است؛** این مدل فقط می‌خواند و نمایش می‌دهد.
/// زمان‌ها به‌صورت ISO-8601 با offset می‌آیند (همان قرارداد بقیه‌ی مدل‌ها) و
/// با [DateTime.parse].toLocal() به وقت دستگاه تبدیل می‌شوند.
class CafeStatus {
  const CafeStatus({
    required this.isOpen,
    this.openedAt,
    this.closedAt,
  });

  /// آیا کافه الان باز است؟
  final bool isOpen;

  /// زمانِ آخرین باری که کافه باز شد؛ وقتی بسته است هم برای «شروع فعالیتِ»
  /// همان روز نگه داشته می‌شود.
  final DateTime? openedAt;

  /// زمانِ آخرین باری که کافه بسته شد؛ قبل از اولین بسته‌شدن null است.
  final DateTime? closedAt;

  factory CafeStatus.fromJson(Map<String, dynamic> json) => CafeStatus(
        isOpen: json['is_open'] as bool? ?? false,
        openedAt: _time(json['opened_at']),
        closedAt: _time(json['closed_at']),
      );

  static DateTime? _time(Object? raw) =>
      raw is String && raw.isNotEmpty ? DateTime.parse(raw).toLocal() : null;
}
