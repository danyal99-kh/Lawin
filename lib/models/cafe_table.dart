import 'api_enum.dart';
import 'enums.dart';

/// میز کافه. ورود/خروج در مدل TableSession و اطلاعات ترکیبی در TableOverview است.
class CafeTable {
  const CafeTable({
    required this.id,
    required this.number,
    required this.status,
  });

  final int id;
  final int number;
  final TableStatus status;

  CafeTable copyWith({TableStatus? status}) =>
      CafeTable(id: id, number: number, status: status ?? this.status);

  CafeTable copyWith({TableStatus? status}) =>
      CafeTable(id: id, number: number, status: status ?? this.status);

  factory CafeTable.fromJson(Map<String, dynamic> json) => CafeTable(
        id: json['id'] as int,
        number: json['number'] as int,
        status: parseApiEnum(TableStatus.values, json['status'],
            fallback: TableStatus.empty),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'status': status.apiValue,
      };
}
