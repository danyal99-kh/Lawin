import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/view_state.dart';
import '../../models/product.dart';
import '../../models/recipe.dart';
import '../../providers/product_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../responsive/page_container.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import 'widgets/recipe_form.dart';

/// دستور مصرف: مشخص می‌کند هر محصول برای یک واحد فروش چه کالاهایی از انبار مصرف می‌کند.
class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  Future<void> _reload() => Future.wait([
        context.read<ProductProvider>().load(),
        context.read<RecipeProvider>().load(),
      ]);

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openForm(Product product, Recipe? recipe) async {
    final inventoryItems = context.read<RecipeProvider>().inventoryItems;
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      maxDialogWidth: 520,
      builder: (_) => RecipeForm(
          product: product, recipe: recipe, inventoryItems: inventoryItems),
    );
    if (saved == true && mounted)
      _snack('دستور مصرف «${product.name}» ذخیره شد.');
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final recipes = context.watch<RecipeProvider>();

    return RefreshIndicator(
      onRefresh: _reload,
      child: AsyncStateView<List<Product>>(
        state: products.state,
        onRetry: _reload,
        emptyTitle: 'هنوز محصولی ثبت نشده',
        emptyIcon: Icons.local_cafe_outlined,
        builder: (context, all) {
          final byProduct = {for (final r in recipes.all) r.productId: r};
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'دستور مصرف',
                    subtitle:
                        'برای هر محصول مشخص کنید با فروش آن چه مقدار از هر کالای انبار مصرف می‌شود.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('تازه‌سازی'),
                      ),
                    ],
                  ),
                  if (recipes.state.status == ViewStatus.error &&
                      recipes.state.data == null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ErrorView(
                          failure: recipes.state.failure!, onRetry: _reload),
                    )
                  else
                    for (final p in all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _RecipeTile(
                          product: p,
                          recipe: byProduct[p.id],
                          onTap: () => _openForm(p, byProduct[p.id]),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile(
      {required this.product, required this.recipe, required this.onTap});

  final Product product;
  final Recipe? recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final items = recipe?.items ?? const [];
    final defined = items.isNotEmpty;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  defined
                      ? items
                          .map((i) =>
                              '${i.inventoryItemName} (${i.unit.format(i.quantity)})')
                          .join('، ')
                      : 'دستور مصرفی تعریف نشده',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            label: defined ? 'تعریف‌شده' : 'ناقص',
            tone: defined ? StatusTone.success : StatusTone.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
