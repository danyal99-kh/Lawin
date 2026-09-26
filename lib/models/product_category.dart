class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    this.productCount = 0,
  });

  final int id;
  final String name;

  /// تعداد محصولات این دسته (Backend محاسبه می‌کند).
  final int productCount;

  ProductCategory copyWith({String? name, int? productCount}) =>
      ProductCategory(
        id: id,
        name: name ?? this.name,
        productCount: productCount ?? this.productCount,
      );

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        productCount: json['product_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'product_count': productCount};
}