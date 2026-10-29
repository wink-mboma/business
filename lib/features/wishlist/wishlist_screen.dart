import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../products/product.dart';
import '../products/product_state.dart';
import '../../core/network/catalog_state.dart';
import '../shared/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isSignedIn) {
      return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline_rounded, size: 44, color: AppColors.grey500), const SizedBox(height: 16),
        Text('Sign in to save your favourites', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center), const SizedBox(height: 8),
        const Text('Create a wishlist and keep your favourite pieces in one place.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey600)), const SizedBox(height: 20),
        FilledButton(onPressed: () => context.push('/login'), child: const Text('Sign in or create account'))
      ])));
    }
    final ids = ref.watch(storeProvider).wishlistIds;
    final catalog = ref.watch(catalogProductsProvider);
    final sourceProducts = catalog.valueOrNull ?? sampleProducts;
    final products = sourceProducts.where((p) => ids.contains(p.id)).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= Breakpoints.desktop ? 4 : constraints.maxWidth >= Breakpoints.mobile ? 3 : 2;
      final horizontal = constraints.maxWidth >= Breakpoints.mobile ? 28.0 : 18.0;
      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 18),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your wishlist', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 5),
              Text('${products.length} saved ${products.length == 1 ? 'piece' : 'pieces'}', style: const TextStyle(color: AppColors.grey600)),
            ])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
          ]),
        )),
        if (catalog.isLoading && catalog.valueOrNull == null)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else if (products.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.favorite_border_rounded, size: 42, color: AppColors.grey500),
              SizedBox(height: 14),
              Text('Your wishlist is waiting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Tap the heart on a product to save it here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey600)),
            ]),
          )))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 120),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 16, mainAxisSpacing: 22, childAspectRatio: 0.60),
              delegate: SliverChildBuilderDelegate((context, index) => ProductCard(product: products[index]), childCount: products.length),
            ),
          ),
      ]);
    });
  }
}
