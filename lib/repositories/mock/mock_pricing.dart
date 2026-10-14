import '../../models/offer.dart';
import '../../models/product.dart';

/// نتیجه‌ی محاسبه‌ی قیمت مؤثر در حالت Mock؛ معادل `catalog.pricing` در Backend.
class MockQuote {
  const MockQuote({
    required this.base,
    required this.finalPrice,
    required this.totalPercent,
  });

  final int base;
  final int finalPrice;
  final int totalPercent;

  int get saving => base - finalPrice;
}

/// یک درصد را روی مبلغ اعمال می‌کند (گردکردن نیم‌بها به بالا مثل Backend).
int applyPercent(int amount, int percent) {
  if (percent <= 0) return amount;
  return ((amount * (100 - percent)) / 100).round();
}

List<Offer> _applicable(List<Offer> offers, Product p, DateTime now) {
  final rows = offers.where((o) =>
      o.validAt(now) &&
      ((o.scope == OfferScope.product && o.productId == p.id) ||
          (o.scope == OfferScope.category && o.categoryId == p.categoryId)));
  final sorted = rows.toList()
    ..sort((a, b) {
      final byCreated = (a.createdAt ?? DateTime(0)).compareTo(
          b.createdAt ?? DateTime(0));
      return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
    });
  return sorted;
}

/// قیمت مؤثر یک محصول با زنجیره‌ی آفرهای فعال (متوالی و ضربی، نه جمعی).
MockQuote quoteProduct(List<Offer> offers, Product p, {DateTime? now}) {
  final rows = _applicable(offers, p, now ?? DateTime.now());
  var finalPrice = p.price;
  for (final o in rows) {
    finalPrice = applyPercent(finalPrice, o.percent);
  }
  final total = p.price <= 0
      ? 0
      : (((p.price - finalPrice) * 100) / p.price).round();
  return MockQuote(base: p.price, finalPrice: finalPrice, totalPercent: total);
}

/// اثر انگشت پیش‌نمایش؛ هم‌معنی با Backend (هر تغییر ورودی → اثر انگشت متفاوت).
String previewFingerprint(
  OfferScope scope,
  int percent,
  DateTime? startsAt,
  DateTime? endsAt,
  List<OfferPreviewItem> items,
) {
  final parts = <String>[
    scope.wire,
    '$percent',
    startsAt?.toUtc().toIso8601String() ?? '',
    endsAt?.toUtc().toIso8601String() ?? '',
    ...items.map((i) => '${i.productId}:${i.base}:${i.before}'),
  ];
  return parts.join('|');
}
