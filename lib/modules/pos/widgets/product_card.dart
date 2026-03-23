import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';

/// Product card widget for POS grid
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  String _getMeasurementLabel() {
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

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: isOutOfStock
                        ? colorScheme.outline
                        : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Product name
              Text(
                product.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOutOfStock
                      ? colorScheme.onSurface.withValues(alpha: 0.6)
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Price
              Text(
                '₹${product.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock
                      ? colorScheme.onSurface.withValues(alpha: 0.6)
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              // Measurement type
              Text(
                _getMeasurementLabel(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              // Stock status
              Row(
                children: [
                  Icon(
                    isOutOfStock ? Icons.cancel : Icons.check_circle,
                    size: 12,
                    color: isOutOfStock
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isOutOfStock
                          ? 'Out of stock'
                          : 'Stock: ${product.stock.toStringAsFixed(product.measurementType.toLowerCase() == 'kg' || product.measurementType.toLowerCase() == 'gm' ? 2 : 0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOutOfStock
                            ? colorScheme.error
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
