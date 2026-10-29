import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../products/product.dart';
import '../../core/network/catalog_state.dart';
import '../shared/product_card.dart';

enum ExploreSort { featured, lowHigh, highLow, name }

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String? categoryId;
  String? brandId;
  ExploreSort sort = ExploreSort.featured;
  double maxPrice = 150000;

  List<Product> filterProducts(List<Product> source) {
    final list = source.where((p) {
      final matchesCategory = categoryId == null || p.categoryId == categoryId;
      final matchesBrand = brandId == null || p.brandId == brandId;
      return matchesCategory && matchesBrand && p.price <= maxPrice;
    }).toList();
    switch (sort) {
      case ExploreSort.lowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ExploreSort.highLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ExploreSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ExploreSort.featured:
        break;
    }
    return list;
  }

  Widget _categoryChip(String label, String? id) {
    final selected = categoryId == id;
    return ChoiceChip(
      label: Text(label), selected: selected,
      onSelected: (_) => setState(() => categoryId = id),
      selectedColor: AppColors.black, backgroundColor: AppColors.white,
      side: BorderSide(color: selected ? AppColors.black : AppColors.grey300),
      labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.black, fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  String get sortLabel => switch (sort) {
    ExploreSort.featured => 'Featured',
    ExploreSort.lowHigh => 'Price: low to high',
    ExploreSort.highLow => 'Price: high to low',
    ExploreSort.name => 'Name',
  };

  Future<void> openFilters() async {
    var draftPrice = maxPrice;
    var draftSort = sort;
    final result = await showModalBottomSheet<(double, ExploreSort)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter & sort',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 22),
                const Text(
                  'SORT BY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExploreSort>(
                  value: draftSort,
                  items: const [
                    DropdownMenuItem(
                      value: ExploreSort.featured,
                      child: Text('Featured'),
                    ),
                    DropdownMenuItem(
                      value: ExploreSort.lowHigh,
                      child: Text('Price: low to high'),
                    ),
                    DropdownMenuItem(
                      value: ExploreSort.highLow,
                      child: Text('Price: high to low'),
                    ),
                    DropdownMenuItem(
                      value: ExploreSort.name,
                      child: Text('Name'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => draftSort = v);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'MAXIMUM PRICE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text('MK ${draftPrice.toStringAsFixed(0)}'),
                  ],
                ),
                Slider(
                  value: draftPrice,
                  min: 30000,
                  max: 150000,
                  divisions: 12,
                  activeColor: AppColors.black,
                  onChanged: (v) => setModalState(() => draftPrice = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setModalState(() {
                          draftPrice = 150000;
                          draftSort = ExploreSort.featured;
                        }),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, (draftPrice, draftSort)),
                        child: const Text('Show results'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted)
      setState(() {
        maxPrice = result.$1;
        sort = result.$2;
      });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= Breakpoints.desktop
          ? 6
          : w >= Breakpoints.mobile
          ? 4
          : 2;
      final pad = w >= Breakpoints.desktop
          ? 48.0
          : w >= Breakpoints.mobile
          ? 28.0
          : 18.0;
      final filterKey = '${categoryId ?? ''}|${brandId ?? ''}';
      final remote = ref.watch(catalogFilteredProductsProvider(filterKey));
      final categoriesAsync = ref.watch(catalogCategoriesProvider);
      final brandsAsync = ref.watch(catalogBrandsProvider);
      final source = remote.valueOrNull ?? <Product>[];
      final items = filterProducts(source);
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 28, pad, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THE COLLECTION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    color: AppColors.grey600,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Explore',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go('/search'),
                            icon: const Icon(Icons.search_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _categoryChip('All', null),
                            const SizedBox(width: 8),
                            ...((categoriesAsync.valueOrNull ?? const [])).map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _categoryChip(cat.name, cat.id),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Text('BRAND', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 12),
                        Expanded(child: DropdownButtonFormField<String?>(
                          value: brandId,
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder()),
                          hint: const Text('All brands'),
                          items: [const DropdownMenuItem<String?>(value: null, child: Text('All brands')), ...((brandsAsync.valueOrNull ?? const []).map((brand) => DropdownMenuItem<String?>(value: brand.id, child: Text(brand.name, overflow: TextOverflow.ellipsis))))],
                          onChanged: (value) => setState(() => brandId = value),
                        )),
                      ]),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            '${items.length} pieces',
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            sortLabel,
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 11,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: openFilters,
                            icon: const Icon(Icons.tune_rounded, size: 17),
                            label: const Text('Filter'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (remote.hasError)
            SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Could not load products from Mono Store.'), const SizedBox(height: 10), OutlinedButton.icon(onPressed: () => ref.invalidate(catalogFilteredProductsProvider(filterKey)), icon: const Icon(Icons.refresh), label: const Text('Try again'))]))))
          else if (remote.isLoading && remote.valueOrNull == null)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No products match these filters.')),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 120),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: w < Breakpoints.mobile ? 12 : 20,
                  mainAxisSpacing: 22,
                  childAspectRatio: w < Breakpoints.mobile ? .57 : .62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductCard(product: items[i]),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      );
    },
  );
}
