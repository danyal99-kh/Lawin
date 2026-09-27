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
  });

  final int id;
  final String name;
  final int categoryId;

  /// قیمت فروش به تومان
  final int price;
  final String? description;

  /// آدرس (URL) یا مسیر فایل محلی تصویر. بعد از اتصال به Django آدرس فایل آپلودشده است.
  final String? imageUrl;
  final bool isActive;

  Product copyWith({bool? isActive}) => Product(
        id: id,
        name: name,
        categoryId: categoryId,
        price: price,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive ?? this.isActive,
      );

  /// جایگزینی همه‌ی فیلدهای قابل ویرایش (شامل پاک‌کردن تصویر/توضیحات).
  Product applyDraft(ProductDraft d) => Product(
        id: id,
        name: d.name,
        categoryId: d.categoryId,
        price: d.price,
        description: d.description,
        imageUrl: d.imageUrl,
        isActive: d.isActive,
      );

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        categoryId: json['category_id'] as int,
        price: json['price'] as int,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
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
