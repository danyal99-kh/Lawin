import 'api_enum.dart';
import 'enums.dart';

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.note,
  });

  final int productId;
  final String productName;
  final int quantity;

  /// قیمت واحد در لحظه‌ی ثبت سفارش (Backend مقدار را snapshot می‌کند).
  final int unitPrice;
  final String? note;

  int get lineTotal => quantity * unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        unitPrice: json['unit_price'] as int,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'note': note,
      };
}

/// سفارش. هم سفارش‌های ثبت‌شده توسط ادمین و هم سفارش‌های آینده‌ی بخش مشتری
/// (`source == customer`) با همین مدل نمایش داده می‌شوند. قالب JSON در docs/API_CONTRACT.md.
class Order {
  const Order({
    required this.id,
    required this.number,
    required this.source,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.createdAt,
    required this.sessionId,
    this.tableId,
    this.tableNumber,
    this.paymentMethod,
    this.customerNote,
    this.paidAt,
    this.barPrintedAt,
    this.version = 1,
  });

  final String id;
  final int number;
  final OrderSource source;
  final int? tableId;
  final int? tableNumber;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String? customerNote;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? paidAt;

  /// نشست میزی که این سفارش به آن تعلق دارد.
  final String sessionId;

  /// زمان چاپ سفارش بار؛ برای جلوگیری از چاپ تکراری.
  final DateTime? barPrintedAt;

  /// نسخه برای رد داده‌ی کهنه هنگام دریافت تغییرات از سرور.
  final int version;

  int get total => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isFromCustomer => source == OrderSource.customer;

  factory Order.fromJson(Map<String, dynamic> json) {
    final table = json['table'] as Map<String, dynamic>?;
    final method = json['payment_method'];
    final paidAt = json['paid_at'] as String?;
    final printedAt = json['bar_printed_at'] as String?;
    return Order(
      id: json['id'] as String,
      number: json['number'] as int,
      source: parseApiEnum(OrderSource.values, json['source'],
          fallback: OrderSource.admin),
      tableId: table?['id'] as int?,
      tableNumber: table?['number'] as int?,
      status: parseApiEnum(OrderStatus.values, json['status'],
          fallback: OrderStatus.newOrder),
      paymentStatus: parseApiEnum(PaymentStatus.values, json['payment_status'],
          fallback: PaymentStatus.unpaid),
      paymentMethod: method == null
          ? null
          : parseApiEnum(PaymentMethod.values, method,
              fallback: PaymentMethod.cash),
      customerNote: json['customer_note'] as String?,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      paidAt: paidAt == null ? null : DateTime.parse(paidAt).toLocal(),
      barPrintedAt:
          printedAt == null ? null : DateTime.parse(printedAt).toLocal(),
      version: json['version'] as int? ?? 1,
      sessionId: json['session_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'source': source.apiValue,
        'table':
            tableNumber == null ? null : {'id': tableId, 'number': tableNumber},
        'status': status.apiValue,
        'payment_status': paymentStatus.apiValue,
        'payment_method': paymentMethod?.apiValue,
        'customer_note': customerNote,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'created_at': createdAt.toUtc().toIso8601String(),
        'paid_at': paidAt?.toUtc().toIso8601String(),
        'bar_printed_at': barPrintedAt?.toUtc().toIso8601String(),
        'version': version,
        'session_id': sessionId,
      };

  Order copyWith({
    String? id,
    int? number,
    OrderSource? source,
    int? tableId,
    int? tableNumber,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? customerNote,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? barPrintedAt,
    int? version,
    String? sessionId,
    bool clearPaymentMethod = false,
    bool clearPaidAt = false,
    bool clearBarPrintedAt = false,
  }) {
    return Order(
      id: id ?? this.id,
      number: number ?? this.number,
      source: source ?? this.source,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      customerNote: customerNote ?? this.customerNote,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      barPrintedAt:
          clearBarPrintedAt ? null : (barPrintedAt ?? this.barPrintedAt),
      version: version ?? this.version,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}
