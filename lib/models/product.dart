/// محصول فروشی منو. Recipe (دستور مصرف) در مرحله ۶ به آن وصل می‌شود.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.effectivePrice,
    this.discountPercent = 0,
    this.offerActive = false,
    this.offerEndsAt,
  });

  final int id;
  final String name;
  final int categoryId;

  /// قیمت پایه‌ی فروش به تومان. این مقدار هرگز با آفر تغییر نمی‌کند.
  final int price;
  final String? description;

  /// آدرس (URL) یا مسیر فایل محلی تصویر. بعد از اتصال به Django آدرس فایل آپلودشده است.
  final String? imageUrl;
  final bool isActive;

  /// قیمت مؤثر پس از اعمال آفرها (فقط‌خواندنی؛ سرور محاسبه می‌کند).
  /// اگر null باشد یعنی آفری اعمال نشده و همان [price] است.
  final int? effectivePrice;

  /// درصد کل تخفیف (نسبت به قیمت پایه)؛ ۰ یعنی بدون آفر.
  final int discountPercent;

  /// آیا الان آفر فعالی روی این محصول اعمال می‌شود؟
  final bool offerActive;

  /// نزدیک‌ترین زمان پایان آفر (اگر زمان‌بندی داشته باشد).
  final DateTime? offerEndsAt;

  /// قیمت نهایی قابل پرداخت (با احتساب آفر).
  int get finalPrice => effectivePrice ?? price;

  /// آیا محصول تخفیف فعال دارد؟ (برای نمایش قیمت خط‌خورده و برچسب تخفیف)
  bool get hasOffer => offerActive && discountPercent > 0;

  Product copyWith({
    bool? isActive,
    int? effectivePrice,
    int? discountPercent,
    bool? offerActive,
    DateTime? offerEndsAt,
  }) =>
      Product(
        id: id,
        name: name,
        categoryId: categoryId,
        price: price,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive ?? this.isActive,
        effectivePrice: effectivePrice ?? this.effectivePrice,
        discountPercent: discountPercent ?? this.discountPercent,
        offerActive: offerActive ?? this.offerActive,
        offerEndsAt: offerEndsAt ?? this.offerEndsAt,
      );

  /// جایگزینی همه‌ی فیلدهای قابل ویرایش (شامل پاک‌کردن تصویر/توضیحات).
  /// فیلدهای آفر از سمت سرور می‌آیند و اینجا دست‌نخورده می‌مانند.
  Product applyDraft(ProductDraft d) => Product(
        id: id,
        name: d.name,
        categoryId: d.categoryId,
        price: d.price,
        description: d.description,
        imageUrl: d.imageUrl,
        isActive: d.isActive,
        effectivePrice: effectivePrice,
        discountPercent: discountPercent,
        offerActive: offerActive,
        offerEndsAt: offerEndsAt,
      );

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        categoryId: json['category_id'] as int,
        price: json['price'] as int,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        effectivePrice: json['effective_price'] as int?,
        discountPercent: json['discount_percent'] as int? ?? 0,
        offerActive: json['offer_active'] as bool? ?? false,
        offerEndsAt: _offerDate(json['offer_ends_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'is_active': isActive,
      };
}

DateTime? _offerDate(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

/// داده‌ی فرم ایجاد/ویرایش محصول (بدون شناسه). بدنه‌ی POST/PUT به Django.
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.price,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String name;
  final int categoryId;
  final int price;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  factory ProductDraft.fromProduct(Product p) => ProductDraft(
        name: p.name,
        categoryId: p.categoryId,
        price: p.price,
        description: p.description,
        imageUrl: p.imageUrl,
        isActive: p.isActive,
      );

  /// حذف فاصله‌های اضافه؛ متن خالی → null.
  ProductDraft normalized() {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return ProductDraft(
      name: name.trim(),
      categoryId: categoryId,
      price: price,
      description: clean(description),
      imageUrl: clean(imageUrl),
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category_id': categoryId,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'is_active': isActive,
      };
}
