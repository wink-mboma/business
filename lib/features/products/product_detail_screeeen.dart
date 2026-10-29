
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import 'product.dart';
import 'product_state.dart';
import '../../core/network/catalog_state.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  final PageController _galleryController = PageController();
  final TextEditingController _reviewController =
  TextEditingController();

  int imageIndex = 0;
  String? selectedSize;
  String? selectedColor;
  int quantity = 1;
  bool _showFullDescription = false;
  double _reviewRating = 5;

  String money(num? value) {
    final amount = value ?? 0;

    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (match) => '${match[1]},',
    );

    return 'MK $formatted';
  }

  @override
  void dispose() {
    _galleryController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  ProductVariant? _selectedVariant(Product product) {
    if (!product.hasVariantInventory) return null;
    final size = selectedSize ?? (product.hasSizeOptions ? null : product.sizes.firstOrNull);
    final color = selectedColor ?? (product.hasColorOptions ? null : product.colors.firstOrNull);
    if (size == null || color == null) return null;
    return product.variantFor(size, color);
  }

  bool _sizeAvailable(Product product, String size) {
    if (!product.hasVariantInventory || !product.hasColorOptions || selectedColor == null) {
      return product.variants.any((variant) => variant.size == size && variant.stock > 0);
    }
    return product.variants.any((variant) => variant.size == size && variant.color == selectedColor && variant.stock > 0);
  }

  bool _colorAvailable(Product product, String color) {
    if (!product.hasVariantInventory || !product.hasSizeOptions || selectedSize == null) {
      return product.variants.any((variant) => variant.color == color && variant.stock > 0);
    }
    return product.variants.any((variant) => variant.color == color && variant.size == selectedSize && variant.stock > 0);
  }

  Future<void> _shareProduct(Product product) async {
    // This assumes the public product route is /product/:productId.
    // Replace the base URL with your production website domain when ready.
    final productUrl = Uri.base.resolve(
      '/product/${Uri.encodeComponent(product.id)}',
    );

    await Clipboard.setData(
      ClipboardData(
        text: '${product.name}\n$productUrl',
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product link copied to clipboard'),
      ),
    );
  }

  void _addToBag(Product product, {bool buyNow = false}) {
    final variant = _selectedVariant(product);

    if (!product.hasVariantInventory && product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This product is currently out of stock.')));
      return;
    }

    if (product.hasVariantInventory &&
        ((product.hasSizeOptions && selectedSize == null) ||
         (product.hasColorOptions && selectedColor == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size and colour first.'),
        ),
      );
      return;
    }

    if (product.hasVariantInventory &&
        (variant == null || !variant.isAvailable)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That combination is currently out of stock.'),
        ),
      );
      return;
    }

    final availableStock = variant?.stock ?? product.stockQuantity;
    if (quantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only $availableStock item(s) are available.')));
      return;
    }

    if (variant != null && quantity > variant.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${variant.stock} item(s) are available for this variant.',
          ),
        ),
      );
      return;
    }

    ref.read(storeProvider.notifier).addToCart(
      product,
      quantity: quantity,
      variant: variant,
    );

    if (buyNow) {
      context.go('/cart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to bag')),
      );
    }
  }

  void _submitReview() {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review first.'),
        ),
      );
      return;
    }

    // Demo only: connect this action to your PHP reviews API.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Review form ready. Reviews API integration is required to submit.',
        ),
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDescription(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('PRODUCT DESCRIPTION'),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _showFullDescription
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: SizedBox(
            width: double.infinity,
            child: Text(
              product.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                height: 1.7,
                color: AppColors.grey700,
              ),
            ),
          ),
          secondChild: SizedBox(
            width: double.infinity,
            child: Text(
              product.description,
              style: const TextStyle(
                height: 1.7,
                color: AppColors.grey700,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _showFullDescription = !_showFullDescription;
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.black,
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showFullDescription
                    ? 'Show less'
                    : 'Read full description',
              ),
              const SizedBox(width: 5),
              Icon(
                _showFullDescription
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector(Product product) {
    if (!product.hasSizeOptions || product.sizes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('CHOOSE SIZE'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.sizes.map((size) {
            final available = _sizeAvailable(product, size);
            final selected = selectedSize == size;

            return ChoiceChip(
              label: Text(
                available ? size : '$size · Out',
              ),
              selected: selected,
              onSelected: available
                  ? (_) {
                setState(() {
                  selectedSize = size;
                  quantity = 1;
                });
              }
                  : null,
              selectedColor: AppColors.black,
              backgroundColor: AppColors.white,
              disabledColor: AppColors.grey100,
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.white
                    : available
                    ? AppColors.black
                    : AppColors.grey500,
                fontWeight: FontWeight.w600,
                decoration:
                available ? null : TextDecoration.lineThrough,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.black
                    : AppColors.grey300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector(Product product) {
    if (!product.hasColorOptions || product.colors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('COLOUR'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.colors.map((color) {
            final available = _colorAvailable(product, color);
            final selected = selectedColor == color;

            return ChoiceChip(
              label: Text(color),
              selected: selected,
              onSelected: available
                  ? (_) {
                setState(() {
                  selectedColor = color;
                  quantity = 1;
                });
              }
                  : null,
              selectedColor: AppColors.grey200,
              backgroundColor: AppColors.white,
              disabledColor: AppColors.grey100,
              side: BorderSide(
                color: selected
                    ? AppColors.black
                    : AppColors.grey300,
              ),
              labelStyle: TextStyle(
                color: available
                    ? AppColors.black
                    : AppColors.grey500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(Product product, ProductVariant? variant) {
    final stockLimit = variant?.stock ?? product.stockQuantity;
    final maxQuantity = stockLimit > 0
        ? (stockLimit < 10 ? stockLimit : 10)
        : 1;

    return Row(
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        _QtyButton(
          icon: Icons.remove,
          onTap: () {
            setState(() {
              if (quantity > 1) quantity--;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        _QtyButton(
          icon: Icons.add,
          onTap: () {
            setState(() {
              if (quantity < maxQuantity) quantity++;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPurchaseButtons(
      Product product,
      bool saved,
      bool unavailable,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref
                      .read(storeProvider.notifier)
                      .toggleWishlist(product.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        saved
                            ? 'Removed from wishlist'
                            : 'Added to wishlist',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  foregroundColor: AppColors.black,
                  side: const BorderSide(
                    color: AppColors.grey300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Icon(
                  saved
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: unavailable
                    ? null
                    : () => _addToBag(product),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'ADD TO BAG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: unavailable
                ? null
                : () => _addToBag(product, buyNow: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              minimumSize: const Size(0, 50),
              side: const BorderSide(
                color: AppColors.black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              'BUY NOW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostageAndPayments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 36),
        _sectionHeading('POSTAGE AND PAYMENTS'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Delivery address'),
          subtitle: const Text(
            'Select a saved address or add one at checkout.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/cart'),
        ),
        const Divider(height: 20),
        _sectionHeading('DELIVERY OPTIONS'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.local_shipping_outlined),
          title: Text('Standard delivery'),
          subtitle: Text(
            'Delivery charges and estimated arrival will be confirmed '
                'at checkout.',
          ),
        ),
        const Divider(height: 20),
        _sectionHeading('PAYMENT METHODS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _PaymentMethodChip(label: 'Airtel Money'),
            _PaymentMethodChip(label: 'TNM Mpamba'),
            _PaymentMethodChip(label: 'Visa'),
            _PaymentMethodChip(label: 'PayChangu'),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Payment options depend on availability at checkout. '
              'Online payments must be securely verified by the server.',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildReturns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 36),
        _sectionHeading('RETURNS'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.assignment_return_outlined),
          title: Text('7-day return period'),
          subtitle: Text(
            'Eligible products may be returned within 7 days after '
                'delivery, subject to the store’s published return '
                'conditions. Contact support to request a return.',
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSeller() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions about this product?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Chat with the Mono Store team.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go('/chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              side: const BorderSide(
                color: AppColors.grey300,
              ),
            ),
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('RATINGS & REVIEWS'),
          const Text(
            'Share your experience with this product.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your rating',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;

              return IconButton(
                onPressed: () {
                  setState(() {
                    _reviewRating = rating.toDouble();
                  });
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(
                  rating <= _reviewRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 29,
                  color: AppColors.black,
                ),
              );
            }),
          ),
          Text(
            '${_reviewRating.toStringAsFixed(0)} out of 5',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write your product review...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.grey300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitReview,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text('SUBMIT REVIEW'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reviews will appear here after review submission is '
                'connected to the store backend.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(
      BuildContext context, {
        required String title,
        required List<Product> products,
      }) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = products[index];

                return SizedBox(
                  width: 165,
                  child: InkWell(
                    onTap: () {
                      context.push('/product/${item.id}');
                    },
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: AppColors.grey100,
                            child: item.images.isEmpty
                                ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 36,
                                color: AppColors.grey500,
                              ),
                            )
                                : Image.network(
                              item.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.brand.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          money(item.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(
      BuildContext context,
      Product product,
      ProductVariant? variant,
      bool saved,
      bool unavailable,
      bool wide,
      ) {
    final needsSize = product.hasSizeOptions && selectedSize == null;
    final needsColor = product.hasColorOptions && selectedColor == null;
    final stock = variant?.stock ?? product.stockQuantity;
    final stockText = product.hasVariantInventory && (needsSize || needsColor)
        ? 'Choose ${needsSize && needsColor ? 'a size and colour' : needsSize ? 'a size' : 'a colour'} to check availability'
        : stock <= 0
        ? 'Out of stock'
        : stock <= 3
        ? 'Only $stock left'
        : 'In stock';

    return Padding(
      padding: EdgeInsets.all(wide ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.brand.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: AppColors.grey600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                money(product.price),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.originalPrice != null) ...[
                const SizedBox(width: 10),
                Text(
                  money(product.originalPrice!),
                  style: const TextStyle(
                    color: AppColors.grey500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          _buildDescription(product),

          const SizedBox(height: 24),
          _buildSizeSelector(product),

          if (product.sizes.isNotEmpty)
            const SizedBox(height: 24),

          _buildColorSelector(product),

          if (product.colors.isNotEmpty)
            const SizedBox(height: 18),

          Row(
            children: [
              Icon(
                unavailable
                    ? Icons.error_outline
                    : Icons.inventory_2_outlined,
                size: 17,
                color: unavailable
                    ? AppColors.grey700
                    : AppColors.grey600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stockText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: unavailable
                        ? AppColors.grey700
                        : AppColors.grey600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _buildQuantitySelector(product, variant),

          const SizedBox(height: 24),
          _buildPurchaseButtons(product, saved, unavailable),

          _buildPostageAndPayments(),
          _buildReturns(),
          _buildMessageSeller(),
          _buildReviews(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(catalogProductsProvider);
    final remoteProducts = productsAsync.valueOrNull ?? const <Product>[];
    final inList = remoteProducts.where((item) => item.id == widget.productId).firstOrNull;
    final detailAsync = inList == null ? ref.watch(catalogProductByIdProvider(widget.productId)) : null;
    final product = inList ?? detailAsync?.valueOrNull;
    if (product == null) {
      if (detailAsync?.hasError == true) {
        return Scaffold(appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded))), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inventory_2_outlined, size: 42), const SizedBox(height: 12), const Text('This product could not be loaded.'), const SizedBox(height: 12), OutlinedButton(onPressed: () => ref.invalidate(catalogProductByIdProvider(widget.productId)), child: const Text('Try again'))]))));
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final allProducts = remoteProducts.isNotEmpty ? remoteProducts : <Product>[product];

    final wide = MediaQuery.sizeOf(context).width >=
        Breakpoints.tablet;

    final saved = ref.watch(storeProvider)
        .wishlistIds
        .contains(product.id);

    final variant = _selectedVariant(product);

    final unavailable = product.hasVariantInventory &&
        !(product.hasSizeOptions && selectedSize == null) &&
        !(product.hasColorOptions && selectedColor == null) &&
        (variant == null || !variant.isAvailable);

    final relatedProducts = allProducts
        .where(
          (item) =>
      item.id != product.id &&
          item.brand == product.brand,
    )
        .take(6)
        .toList();

    final otherProducts = allProducts
        .where((item) => item.id != product.id)
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Search products',
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Share product',
            onPressed: () => _shareProduct(product),
            icon: const Icon(Icons.share_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _Gallery(
                            product: product,
                            controller: _galleryController,
                            currentIndex: imageIndex,
                            onChanged: (index) {
                              setState(() {
                                imageIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildProductDetails(
                          context,
                          product,
                          variant,
                          saved,
                          unavailable,
                          wide,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _Gallery(
                    product: product,
                    controller: _galleryController,
                    currentIndex: imageIndex,
                    onChanged: (index) {
                      setState(() {
                        imageIndex = index;
                      });
                    },
                  ),
                  _buildProductDetails(
                    context,
                    product,
                    variant,
                    saved,
                    unavailable,
                    wide,
                  ),
                ],

                _buildRecommendations(
                  context,
                  title: 'Inspired by your recent',
                  products: relatedProducts,
                ),

                _buildRecommendations(
                  context,
                  title: 'You May Also Like',
                  products: otherProducts,
                ),
              ],
            ),
          ),
        ),
      ),





    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.product,
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
  });

  final Product product;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final images = product.images;

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 0.82,
        child: Container(
          color: AppColors.grey100,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.grey500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 0.82,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: images.length,
                onPageChanged: onChanged,
                itemBuilder: (context, index) {
                  return Container(
                    color: AppColors.grey100,
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 42,
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        width: currentIndex == index ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? AppColors.black
                              : AppColors.grey300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / ${images.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 10),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    controller.animateToPage(
                      index,
                      duration:
                      const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                    onChanged(index);
                  },
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: currentIndex == index
                            ? AppColors.black
                            : AppColors.grey200,
                        width: currentIndex == index ? 2 : 1,
                      ),
                    ),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_outlined),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 17),
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
