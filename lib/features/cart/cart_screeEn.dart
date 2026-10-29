import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../products/product_state.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  String money(double value) => 'MK ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(storeProvider).cart.values.toList();
    final subtotal = cart.fold<double>(0, (sum, line) => sum + line.unitPrice * line.quantity);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 28, 22, 130), children: [
          Text('My Cart', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text('${cart.fold<int>(0, (sum, line) => sum + line.quantity)} items · saved on this device', style: const TextStyle(color: AppColors.grey600)),
          const SizedBox(height: 24),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Column(children: [
                Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.grey500),
                SizedBox(height: 16),
                Text('Your cart is empty', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Explore the collection and find something you love.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey600)),
              ]),
            )
          else ...[
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: Column(children: cart.map((line) => _CartLine(line: line)).toList())),
                const SizedBox(width: 28),
                Expanded(child: _Summary(subtotal: subtotal, money: money)),
              ])
            else ...[
              ...cart.map((line) => _CartLine(line: line)),
              const SizedBox(height: 20),
              _Summary(subtotal: subtotal, money: money),
            ],
          ],
        ]),
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.line});
  final CartLine line;

  String money(double value) => 'MK ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.grey200))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.network(line.product.imageUrl, width: 100, height: 125, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 100, height: 125, color: AppColors.grey100, child: const Icon(Icons.image_outlined))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(line.product.brand, style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: AppColors.grey600)),
          const SizedBox(height: 5),
          Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (line.size != null || line.color != null) ...[
            const SizedBox(height: 5),
            Text(
              [if (line.size != null) 'Size ${line.size}', if (line.color != null) line.color].join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ],
          const SizedBox(height: 7),
          Text(money(line.unitPrice), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            _SmallButton(icon: Icons.remove, onTap: () => ref.read(storeProvider.notifier).changeQuantity(line.lineId, line.quantity - 1)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('${line.quantity}')),
            _SmallButton(icon: Icons.add, onTap: () {
              if (line.quantity >= line.availableStock) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have reached the available stock for this option.')));
                return;
              }
              ref.read(storeProvider.notifier).changeQuantity(line.lineId, line.quantity + 1);
            }),
            const Spacer(),
            IconButton(onPressed: () => ref.read(storeProvider.notifier).removeFromCart(line.lineId), icon: const Icon(Icons.delete_outline, size: 20)),
          ]),
        ])),
      ]),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(width: 30, height: 30, decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(3)), child: Icon(icon, size: 15)),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.subtotal, required this.money});
  final double subtotal;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.grey50, border: Border.all(color: AppColors.grey200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ORDER SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
      const SizedBox(height: 18),
      Row(children: [const Text('Subtotal'), const Spacer(), Text(money(subtotal), style: const TextStyle(fontWeight: FontWeight.w600))]),
      const SizedBox(height: 10),
      const Row(children: [Text('Delivery'), Spacer(), Text('Calculated at checkout', style: TextStyle(color: AppColors.grey600, fontSize: 12))]),
      const Divider(height: 28),
      Row(children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text(money(subtotal), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18))]),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () => context.push('/checkout'), child: const Text('Continue to checkout'))),
    ]),
  );
}
