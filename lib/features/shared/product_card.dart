import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../products/product.dart';
import '../products/product_state.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  String money(double value) =>
      'MK ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(storeProvider).wishlistIds.contains(product.id);
    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),

                  child: CachedNetworkImage(imageUrl: 
                    product.imageUrl,
                    fit: BoxFit.cover,


                    placeholder: (context, url) => Shimmer.fromColors(baseColor: const Color(0xFFEAEAEA), highlightColor: const Color(0xFFF7F7F7), child: Container(color: Colors.white)),
                              errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 38,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Material(
                    color: AppColors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: saved
                          ? 'Remove from wishlist'
                          : 'Add to wishlist',
                      onPressed: () => ref
                          .read(storeProvider.notifier)
                          .toggleWishlist(product.id),
                      icon: Icon(
                        saved ? Icons.favorite : Icons.favorite_border,
                        size: 19,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
                if (product.originalPrice != null)
                  const Positioned(left: 9, top: 9, child: _SaleLabel()),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            product.brand,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: AppColors.grey600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  money(product.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (product.originalPrice != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    money(product.originalPrice!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleLabel extends StatelessWidget {
  const _SaleLabel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.grey200),
    ),
    child: const Text(
      'SALE',
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
