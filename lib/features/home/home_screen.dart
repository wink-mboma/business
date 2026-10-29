import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../products/product.dart';
import '../../core/network/catalog_state.dart';
import '../shared/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveProducts = ref.watch(catalogProductsProvider).valueOrNull ?? sampleProducts;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= Breakpoints.desktop
            ? 6
            : width >= Breakpoints.mobile
            ? 4
            : 2;
        final horizontal = width >= Breakpoints.desktop
            ? 48.0
            : width >= Breakpoints.mobile
            ? 28.0
            : 18.0;
        final gridRatio = width < Breakpoints.mobile ? 0.57 : 0.62;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              backgroundColor: AppColors.white,
              surfaceTintColor: AppColors.white,
              titleSpacing: horizontal,
              title:       Image.asset("assets/light-logo2.png", height: 40, width: 150,),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/account/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  tooltip: 'Search products',
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                Padding(
                  padding: EdgeInsets.only(right: horizontal > 20 ? horizontal - 8 : 10),
                  child: IconButton(
                    tooltip: 'Wishlist',
                    onPressed: () => context.go('/wishlist'),
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionEyebrow('CURATED FOR YOU'),
                        const SizedBox(height: 8),
                        Text('Less, but better.', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 7),
                        const Text(
                          'Timeless pieces. Thoughtfully selected.',
                          style: TextStyle(color: AppColors.grey600, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        _BannerCarousel(
                          height: width < Breakpoints.mobile ? 230 : 320,
                          onTap: (index) {
                            if (index == 1 && liveProducts.length > 1) {
                              context.push('/product/${liveProducts[1].id}');
                            } else {
                              context.go('/explore');
                            }
                          },
                        ),
                        const SizedBox(height: 30),
                        _SectionHeading(
                          title: 'Shop by category',
                          action: 'View all',
                          onPressed: () => context.go('/explore'),
                        ),
                        const SizedBox(height: 12),
                        const _CategoryRow(),
                        const SizedBox(height: 30),
                        _SectionHeading(
                          title: 'Featured products',
                          action: 'See all',
                          onPressed: () => context.go('/explore'),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _ProductGridSliver(
              products: liveProducts.take(4).toList(),
              horizontal: horizontal,
              columns: columns,
              ratio: gridRatio,
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeading(
                          title: 'Shop by brand',
                          action: 'All brands',
                          onPressed: () => context.go('/explore'),
                        ),
                        const SizedBox(height: 12),
                        const _BrandRow(),
                        const SizedBox(height: 30),
                        _SectionHeading(
                          title: 'Best sellers',
                          action: 'View all',
                          onPressed: () => context.go('/explore'),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _ProductGridSliver(
              products: _pickProducts(liveProducts, [0, 2, 5, 1]),
              horizontal: horizontal,
              columns: columns,
              ratio: gridRatio,
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeading(
                          title: 'New arrivals',
                          action: 'Shop new',
                          onPressed: () => context.go('/explore'),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _ProductGridSliver(
              products: _pickProducts(liveProducts, [3, 4, 1, 5]),
              horizontal: horizontal,
              columns: columns,
              ratio: gridRatio,
              bottomPadding: 120,
            ),
          ],
        );
      },
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 2.2,
      color: AppColors.grey600,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.action, required this.onPressed});
  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      TextButton(onPressed: onPressed, child: Text(action)),
    ],
  );
}

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel({required this.height, required this.onTap});
  final double height;
  final ValueChanged<int> onTap;

  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _current = 0;

  static const _fallback = [
    _BannerItem(
      kicker: 'THE NEW EDIT',
      title: 'Modern\nessentials.',
      button: 'DISCOVER NOW',
      image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1800&q=90',
    ),
    _BannerItem(
      kicker: 'THE EVERYDAY COLLECTION',
      title: 'Made to\nmove with you.',
      button: 'SHOP THE EDIT',
      image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1800&q=90',
    ),
    _BannerItem(
      kicker: 'FINISHING TOUCHES',
      title: 'Details that\nmake a difference.',
      button: 'EXPLORE MORE',
      image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1800&q=90',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final count = _bannerItems.length;
      if (count < 2) return;
      final next = (_current + 1) % count;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  List<_BannerItem> get _bannerItems {
    final remote = ref.read(catalogBannersProvider).valueOrNull
        ?.where((b) => b.position == 'home' && (b.imageUrl?.isNotEmpty ?? false))
        .map((b) => _BannerItem(
              kicker: b.title.toUpperCase(),
              title: (b.subtitle?.trim().isNotEmpty ?? false) ? b.subtitle!.trim() : b.title,
              button: 'SHOP NOW',
              image: b.imageUrl!,
              productId: b.productId,
            ))
        .toList();
    return remote != null && remote.isNotEmpty ? remote : _fallback;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiBanners = ref.watch(catalogBannersProvider);
    final remote = apiBanners.valueOrNull
        ?.where((b) => b.position == 'home' && (b.imageUrl?.isNotEmpty ?? false))
        .map((b) => _BannerItem(
              kicker: b.title.toUpperCase(),
              title: (b.subtitle?.trim().isNotEmpty ?? false) ? b.subtitle!.trim() : b.title,
              button: 'SHOP NOW',
              image: b.imageUrl!,
              productId: b.productId,
            ))
        .toList();
    final banners = remote != null && remote.isNotEmpty ? remote : _fallback;
    if (_current >= banners.length) _current = 0;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Material(
                  color: AppColors.grey200,
                  child: InkWell(
                    onTap: () {
                      if (banner.productId != null && banner.productId!.isNotEmpty) {
                        context.push('/product/${banner.productId}');
                      } else {
                        widget.onTap(index);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(imageUrl: 
                          banner.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(baseColor: const Color(0xFFEAEAEA), highlightColor: const Color(0xFFF7F7F7), child: Container(color: Colors.white)),
                              errorWidget: (_, __, ___) => Container(color: AppColors.grey200),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [AppColors.black.withValues(alpha: 0.68), AppColors.black.withValues(alpha: 0.02)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 22, top: 18, bottom: 18, right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(banner.kicker, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.white, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text(banner.title,
                                maxLines: 3, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.white, fontSize: widget.height < 250 ? 27 : 36, fontWeight: FontWeight.w700, height: 1.02, letterSpacing: -0.8)),
                              const SizedBox(height: 16),
                              Container(
                                color: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Text(banner.button, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final selected = index == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: selected ? 22 : 5,
              decoration: BoxDecoration(color: selected ? AppColors.black : AppColors.grey300, borderRadius: BorderRadius.circular(10)),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerItem {
  const _BannerItem({required this.kicker, required this.title, required this.button, required this.image, this.productId});
  final String kicker;
  final String title;
  final String button;
  final String image;
  final String? productId;
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();
  static const categories = [
    ('Clothing', Icons.checkroom_outlined),
    ('Bags', Icons.shopping_bag_outlined),
    ('Shoes', Icons.directions_walk_outlined),
    ('Accessories', Icons.watch_outlined),
    ('Home', Icons.chair_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(catalogCategoriesProvider).valueOrNull;
    final items = remote == null || remote.isEmpty
        ? categories.map((c) => (id: '', name: c.$1, imageUrl: '')).toList()
        : remote.map((c) => (id: c.id, name: c.name, imageUrl: c.imageUrl ?? '')).toList();
    return SizedBox(
    height: 88,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => context.go('/explore'),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.grey50, border: Border.all(color: AppColors.grey200), borderRadius: BorderRadius.circular(5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (item.imageUrl.isNotEmpty)
                SizedBox(width: 30, height: 30, child: CachedNetworkImage(imageUrl: item.imageUrl, fit: BoxFit.contain, placeholder: (context, url) => Shimmer.fromColors(baseColor: const Color(0xFFEAEAEA), highlightColor: const Color(0xFFF7F7F7), child: Container(color: Colors.white)),
                              errorWidget: (_, __, ___) => const Icon(Icons.category_outlined, size: 22)))
              else
                const Icon(Icons.category_outlined, size: 22),
              const SizedBox(height: 7),
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ),
        );
      },
    ),
  );
  }
}

class _BrandRow extends ConsumerWidget {
  const _BrandRow();
  static const brands = ['STUDIO', 'ESSENTIALS', 'FORM', 'MONO EDIT', 'ATELIER'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(catalogBrandsProvider).valueOrNull;
    final items = remote == null || remote.isEmpty
        ? brands.map((name) => (name: name, imageUrl: '')).toList()
        : remote.map((brand) => (name: brand.name, imageUrl: brand.imageUrl ?? '')).toList();
    return SizedBox(
    height: 76,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) => InkWell(
        onTap: () => context.go('/explore'),
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 132,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.grey200), borderRadius: BorderRadius.circular(5)),
          child: items[index].imageUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: items[index].imageUrl, fit: BoxFit.contain, placeholder: (context, url) => Shimmer.fromColors(baseColor: const Color(0xFFEAEAEA), highlightColor: const Color(0xFFF7F7F7), child: Container(color: Colors.white)),
                              errorWidget: (_, __, ___) => Text(items[index].name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)))
              : Text(items[index].name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ),
      ),
    ),
  );
  }
}

class _ProductGridSliver extends StatelessWidget {
  const _ProductGridSliver({required this.products, required this.horizontal, required this.columns, required this.ratio, this.bottomPadding = 0});
  final List<Product> products;
  final double horizontal;
  final int columns;
  final double ratio;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, bottomPadding),
    sliver: SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: MediaQuery.sizeOf(context).width < Breakpoints.mobile ? 12 : 20,
        mainAxisSpacing: 22,
        childAspectRatio: ratio,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) => ProductCard(product: products[index]),
        childCount: products.length,
      ),
    ),
  );
}

List<Product> _pickProducts(List<Product> products, List<int> indexes) => [for (final i in indexes) if (i < products.length) products[i]];
