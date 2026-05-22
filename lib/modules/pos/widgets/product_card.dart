import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';

/// Product card for the POS product grid.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  String get _measurementLabel {
    switch (product.measurementType.toLowerCase()) {
      case 'kg':
        return 'per kg';
      case 'gm':
        return 'per gm';
      case 'piece':
        return 'per piece';
      case 'box':
        return 'per box';
      default:
        return 'per unit';
    }
  }

  String get _stockLabel {
    final decimals = product.isWeightBased ? 2 : 0;
    return product.stock.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? colorScheme.error.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / icon area — fixed height, no flex overflow
            SizedBox(
              height: 88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isOutOfStock
                            ? [
                                colorScheme.surfaceContainerHighest,
                                colorScheme.surfaceContainerHigh,
                              ]
                            : [
                                colorScheme.primaryContainer.withValues(
                                  alpha: 0.55,
                                ),
                                colorScheme.secondaryContainer.withValues(
                                  alpha: 0.4,
                                ),
                              ],
                      ),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 36,
                      color: isOutOfStock
                          ? colorScheme.outline
                          : colorScheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                  if (isOutOfStock)
                    Container(
                      alignment: Alignment.center,
                      color: Colors.black.withValues(alpha: 0.35),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Out of stock',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: isOutOfStock
                            ? colorScheme.onSurface.withValues(alpha: 0.55)
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? colorScheme.onSurface.withValues(alpha: 0.5)
                                : colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _measurementLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? colorScheme.errorContainer.withValues(alpha: 0.5)
                            : colorScheme.primaryContainer.withValues(
                                alpha: 0.45,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOutOfStock
                                ? Icons.remove_circle_outline
                                : Icons.check_circle_outline,
                            size: 14,
                            color: isOutOfStock
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isOutOfStock
                                  ? 'Unavailable'
                                  : 'Stock: $_stockLabel',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isOutOfStock
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
