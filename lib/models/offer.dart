/// نوع آفر: روی یک محصول یا کل یک دسته‌بندی.
enum OfferScope {
  product('product', 'محصول'),
  category('category', 'دسته‌بندی');

  const OfferScope(this.wire, this.label);

  /// مقدار مورد انتظار Backend در فیلد `scope`.
  final String wire;
  final String label;

  static OfferScope fromWire(String? value) =>
      value == 'category' ? OfferScope.category : OfferScope.product;
}

/// یک آفر فعال/غیرفعال که از Backend خوانده می‌شود.
class Offer {
  const Offer({
    required this.id,
    required this.scope,
    required this.percent,
    this.productId,
    this.productName,
    this.categoryId,
    this.categoryName,
    this.isActive = true,
    this.startsAt,
    this.endsAt,
    this.createdAt,
  });

  final int id;
  final OfferScope scope;
  final int percent;
  final int? productId;
  final String? productName;
  final int? categoryId;
  final String? categoryName;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;

  /// نام چیزی که آفر روی آن اعمال می‌شود (محصول یا دسته‌بندی).
  String get targetName =>
      scope == OfferScope.product ? (productName ?? '—') : (categoryName ?? '—');

  Offer copyWith({bool? isActive, DateTime? endsAt}) => Offer(
        id: id,
        scope: scope,
        percent: percent,
        productId: productId,
        productName: productName,
        categoryId: categoryId,
        categoryName: categoryName,
        isActive: isActive ?? this.isActive,
        startsAt: startsAt,
        endsAt: endsAt ?? this.endsAt,
        createdAt: createdAt,
      );

  /// آیا همین حالا (فارغ از زمان‌بندی) معتبر است؟
  bool validAt(DateTime now) {
    if (!isActive) return false;
    if (startsAt != null && startsAt!.isAfter(now)) return false;
    if (endsAt != null && endsAt!.isBefore(now)) return false;
    return true;
  }

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as int,
        scope: OfferScope.fromWire(json['scope'] as String?),
        percent: json['percent'] as int,
        productId: json['product'] as int?,
        productName: json['product_name'] as String?,
        categoryId: json['category'] as int?,
        categoryName: json['category_name'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        startsAt: _date(json['starts_at']),
        endsAt: _date(json['ends_at']),
        createdAt: _date(json['created_at']),
      );
}

/// یک ردیف از پیش‌نمایش آفر (قیمت قبل/بعد برای یک محصول).
class OfferPreviewItem {
  const OfferPreviewItem({
    required this.productId,
    required this.productName,
    required this.base,
    required this.before,
    required this.finalPrice,
    required this.saving,
    required this.currentPercent,
  });

  final int productId;
  final String productName;
  final int base;
  final int before;
  final int finalPrice;
  final int saving;
  final int currentPercent;

  factory OfferPreviewItem.fromJson(Map<String, dynamic> json) =>
      OfferPreviewItem(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        base: json['base'] as int,
        before: json['before'] as int,
        finalPrice: json['final'] as int,
        saving: json['saving'] as int,
        currentPercent: json['current_percent'] as int? ?? 0,
      );
}

/// نتیجه‌ی پیش‌نمایش آفر. برای فعال‌سازی باید عیناً همان [fingerprint] برگردد.
class OfferPreview {
  const OfferPreview({
    required this.scope,
    required this.percent,
    required this.products,
    required this.productCount,
    required this.fingerprint,
    this.startsAt,
    this.endsAt,
  });

  final OfferScope scope;
  final int percent;
  final List<OfferPreviewItem> products;
  final int productCount;

  /// اثر انگشت ورودی‌های مؤثر؛ اگر بین پیش‌نمایش و تأیید قیمت‌ها عوض شود،
  /// سرور فعال‌سازی را رد می‌کند تا تخفیف ناخواسته اعمال نشود.
  final String fingerprint;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isEmpty => products.isEmpty;

  factory OfferPreview.fromJson(Map<String, dynamic> json) => OfferPreview(
        scope: OfferScope.fromWire(json['scope'] as String?),
        percent: json['percent'] as int,
        products: (json['products'] as List? ?? const [])
            .map((e) => OfferPreviewItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        productCount: json['product_count'] as int? ?? 0,
        fingerprint: json['fingerprint'] as String? ?? '',
        startsAt: _date(json['starts_at']),
        endsAt: _date(json['ends_at']),
      );
}

/// ورودی ساخت/پیش‌نمایش آفر. بدنه‌ی POST به Backend.
class OfferRequest {
  const OfferRequest({
    required this.scope,
    required this.percent,
    this.productId,
    this.categoryId,
    this.startsAt,
    this.endsAt,
  });

  final OfferScope scope;
  final int percent;
  final int? productId;
  final int? categoryId;
  final DateTime? startsAt;
  final DateTime? endsAt;

  Map<String, dynamic> toJson() => {
        'scope': scope.wire,
        if (productId != null) 'product_id': productId,
        if (categoryId != null) 'category_id': categoryId,
        'percent': percent,
        if (startsAt != null) 'starts_at': startsAt!.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt!.toUtc().toIso8601String(),
      };
}

DateTime? _date(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
