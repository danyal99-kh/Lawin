import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// تصویر محصول؛ آدرس http(s) را از شبکه و مسیر محلی را از فایل می‌خواند.
/// در نبود تصویر یا خطا، آیکن جایگزین نمایش داده می‌شود.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.imageUrl, this.size = 48});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    Widget placeholder() => Container(
          width: size,
          height: size,
          color: AppColors.woodSoft,
          child: Icon(Icons.local_cafe_outlined,
              color: AppColors.wood, size: size * 0.45),
        );

    Widget child;
    if (url == null || url.isEmpty) {
      child = placeholder();
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      child = Image.network(url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder());
    } else {
      child = Image.file(File(url),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder());
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}