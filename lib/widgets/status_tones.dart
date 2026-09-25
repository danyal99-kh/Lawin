import '../models/enums.dart';
import 'status_chip.dart';

/// نگاشت وضعیت‌های دامنه به رنگ معنایی. منطق رنگ فقط اینجاست، نه در صفحات.
extension OrderStatusTone on OrderStatus {
  StatusTone get tone => switch (this) {
        OrderStatus.newOrder => StatusTone.info,
        OrderStatus.preparing => StatusTone.warning,
        OrderStatus.ready => StatusTone.success,
        OrderStatus.delivered => StatusTone.info,
        OrderStatus.paid => StatusTone.success,
        OrderStatus.cancelled => StatusTone.danger,
      };
}

extension TableStatusTone on TableStatus {
  StatusTone get tone => switch (this) {
        TableStatus.empty => StatusTone.neutral,
        TableStatus.active => StatusTone.info,
        TableStatus.reserved => StatusTone.warning,
      };
}

extension StockStatusTone on StockStatus {
  StatusTone get tone => switch (this) {
        StockStatus.ok => StatusTone.success,
        StockStatus.low => StatusTone.warning,
        StockStatus.out => StatusTone.danger,
      };
}
