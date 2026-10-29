import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../products/product.dart';
import '../../core/network/catalog_state.dart';
import '../shared/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  String query = '';
  static const popular = ['Knitwear', 'Jackets', 'Bags', 'Everyday essentials'];
  void choose(String term) { setState(() { query = term; controller.text = term; controller.selection = TextSelection.collapsed(offset: term.length); }); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
    final w = c.maxWidth;
    final pad = w >= Breakpoints.desktop ? 48.0 : w >= Breakpoints.mobile ? 28.0 : 18.0;
    final cols = w >= Breakpoints.desktop ? 4 : w >= Breakpoints.mobile ? 3 : 2;
    final trimmedQuery = query.trim();
    final remote = trimmedQuery.isEmpty ? null : ref.watch(catalogSearchProductsProvider(trimmedQuery));
    final items = remote?.valueOrNull ?? <Product>[];
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440), child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 28, pad, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('FIND YOUR NEXT FAVOURITE', style: TextStyle(fontSize: 10, letterSpacing: 1.8, color: AppColors.grey600, fontWeight: FontWeight.w700)), const SizedBox(height: 7), Text('Search', style: Theme.of(context).textTheme.headlineLarge)])), IconButton(onPressed: () => context.go('/explore'), icon: const Icon(Icons.grid_view_rounded), tooltip: 'Explore')]),
          const SizedBox(height: 22),
          TextField(controller: controller, textInputAction: TextInputAction.search, onChanged: (v) => setState(() => query = v), onSubmitted: (v) => setState(() => query = v), decoration: InputDecoration(hintText: 'Search products, brands...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: query.isNotEmpty ? IconButton(onPressed: () => setState(() { controller.clear(); query = ''; }), icon: const Icon(Icons.close_rounded)) : null)),
          const SizedBox(height: 24),
          if (query.trim().isEmpty) ...[
            const Text('POPULAR SEARCHES', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)), const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: popular.map((term) => ActionChip(label: Text(term), onPressed: () => choose(term), backgroundColor: AppColors.grey50, side: const BorderSide(color: AppColors.grey200), labelStyle: const TextStyle(color: AppColors.black, fontSize: 12))).toList()),
            const SizedBox(height: 28), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.grey50, border: Border.all(color: AppColors.grey200)), child: const Row(children: [Icon(Icons.search_rounded, size: 24), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('A more considered wardrobe', style: TextStyle(fontWeight: FontWeight.w600)), SizedBox(height: 4), Text('Search by style, brand or product name.', style: TextStyle(color: AppColors.grey600, fontSize: 12))]))])),
          ] else Text('${items.length} results for “$query”', style: const TextStyle(color: AppColors.grey600, fontSize: 13)),
        ]),
      )))),
      if (trimmedQuery.isNotEmpty && remote?.isLoading == true && remote?.valueOrNull == null)
        const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
      else if (trimmedQuery.isNotEmpty && remote?.hasError == true)
        SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.grey500), const SizedBox(height: 12), const Text('Search is temporarily unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 6), const Text('Check your connection to the Mono Store API and try again.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey600)), const SizedBox(height: 12), OutlinedButton(onPressed: () => ref.invalidate(catalogSearchProductsProvider(trimmedQuery)), child: const Text('Try again'))]))))
      else if (trimmedQuery.isNotEmpty && items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off_rounded, size: 42, color: AppColors.grey500), SizedBox(height: 12), Text('No matching products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), SizedBox(height: 6), Text('Try a different product name or brand.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey600))]))))
      else if (items.isNotEmpty) SliverPadding(padding: EdgeInsets.fromLTRB(pad, 0, pad, 120), sliver: SliverGrid(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: w < Breakpoints.mobile ? 12 : 20, mainAxisSpacing: 22, childAspectRatio: w < Breakpoints.mobile ? .57 : .62), delegate: SliverChildBuilderDelegate((context, i) => ProductCard(product: items[i]), childCount: items.length))),
    ]);
  });
}
