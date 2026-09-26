import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../widgets/status_chip.dart';

/// چیپ وضعیت + سوییچ فعال/غیرفعال.
class ProductStatusSwitch extends StatelessWidget {
  const ProductStatusSwitch({
    super.key,
    required this.product,
    required this.onChanged,
  });

  final Product product;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: product.isActive,
          onChanged: (_) => onChanged(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Flexible(
          child: StatusChip(
            label: product.isActive ? 'فعال' : 'غیرفعال',
            tone: product.isActive ? StatusTone.success : StatusTone.neutral,
          ),
        ),
      ],
    );
  }
}