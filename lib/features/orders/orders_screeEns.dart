import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../checkout/checkout_screens.dart' show formatMoney;
import 'order_state.dart';
import '../auth/auth_state.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const double _maxWidth = 920;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final auth = ref.watch(authProvider);
    final loading = ref.watch(ordersLoadingProvider);
    final loadError = ref.watch(ordersErrorProvider);
    final requestedToken = ref.watch(ordersRequestedTokenProvider);
    if (auth.isSignedIn && auth.token.isNotEmpty && requestedToken != auth.token) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        ref.read(ordersRequestedTokenProvider.notifier).state = auth.token;
        ref.read(ordersLoadingProvider.notifier).state = true;
        ref.read(ordersErrorProvider.notifier).state = null;
        try {
          await ref.read(ordersProvider.notifier).load(auth.token);
        } catch (e) {
          ref.read(ordersErrorProvider.notifier).state = e.toString().replaceFirst('Exception: ', '');
        } finally {
          ref.read(ordersLoadingProvider.notifier).state = false;
        }
      });
    }

    final activeOrders = orders
        .where((order) => !_isFinished(order.status))
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _OrdersHeader(total: orders.length),
                      const SizedBox(height: 26),
                      _OrdersOverview(
                        total: orders.length,
                        active: activeOrders,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your orders',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          Text(
                            '${orders.length} ${orders.length == 1 ? 'order' : 'orders'}',
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (loading && orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (loadError != null && orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 32),
                              const SizedBox(height: 10),
                              Text(loadError, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey600)),
                              TextButton(
                                onPressed: () async {
                                  ref.read(ordersLoadingProvider.notifier).state = true;
                                  ref.read(ordersErrorProvider.notifier).state = null;
                                  try {
                                    await ref.read(ordersProvider.notifier).load(auth.token, force: true);
                                  } catch (e) {
                                    ref.read(ordersErrorProvider.notifier).state = e.toString().replaceFirst('Exception: ', '');
                                  } finally {
                                    ref.read(ordersLoadingProvider.notifier).state = false;
                                  }
                                },
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        )
                      else if (orders.isEmpty)
                        const _EmptyOrders()
                      else
                        ...orders.map(
                              (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _OrderCard(
                              order: order,
                              onTap: () =>
                                  context.push('/orders/${order.id}'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (loadError != null && orders.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Could not refresh orders: $loadError', style: const TextStyle(color: AppColors.grey600, fontSize: 11)),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My orders',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Everything you have ordered, in one place.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            size: 21,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

class _OrdersOverview extends StatelessWidget {
  const _OrdersOverview({
    required this.total,
    required this.active,
  });

  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 24,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_mall_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 23),
              const Text(
                'YOUR SHOPPING SUMMARY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$total ${total == 1 ? 'order' : 'orders'} placed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      active == 0
                          ? 'You have no active deliveries'
                          : '$active ${active == 1 ? 'order is' : 'orders are'} in progress',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final StoreOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(order.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEAEAEA)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.black,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _date(order.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    text: order.status,
                    foreground: status.foreground,
                    background: status.background,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 17),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
              Row(
                children: [
                  for (final item in order.items.take(3))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ProductThumbnail(
                        imageUrl: item.imageUrl,
                        width: 57,
                        height: 65,
                      ),
                    ),
                  if (order.items.length > 3)
                    Container(
                      width: 57,
                      height: 65,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '+${order.items.length - 3}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ORDER TOTAL',
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatMoney(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.4,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.only(top: 13),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF0F0F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _paymentIcon(order.paymentStatus),
                      size: 16,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Payment: ${order.paymentStatus}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 32,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your story starts here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'You haven’t placed an order yet. Explore our collection and find something you love.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey600,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/explore'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Explore products',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final auth = ref.watch(authProvider);

    StoreOrder? foundOrder;
    for (final item in orders) {
      if (item.id == orderId || item.databaseId == orderId) {
        foundOrder = item;
        break;
      }
    }
    if (foundOrder == null && auth.isSignedIn && auth.token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ordersProvider.notifier).refreshDetail(auth.token, orderId).then<void>((_) {}, onError: (_) {});
      });
    }

    if (foundOrder == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Order details'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Loading order details from the store…',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
        ),
      );
    }

    final order = foundOrder;
    final steps = _trackingSteps(order.status);
    final currentStep = _currentTrackingStep(order.status);
    final status = _statusStyle(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Order details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white70,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'ORDER REFERENCE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        _StatusBadge(
                          text: order.status,
                          foreground: status.foreground,
                          background: status.background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      order.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        letterSpacing: -0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Placed on ${_date(order.createdAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      height: 1,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'TOTAL PAID / DUE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatMoney(order.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _Panel(
                title: 'Delivery progress',
                subtitle: 'Follow your order from checkout to delivery.',
                icon: Icons.local_shipping_outlined,
                child: Column(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      _Timeline(
                        title: steps[i],
                        done: i <= currentStep,
                        active: i == currentStep,
                        last: i == steps.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                title: 'Items ordered',
                subtitle:
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} in this order',
                icon: Icons.shopping_bag_outlined,
                child: Column(
                  children: [
                    for (var i = 0; i < order.items.length; i++) ...[
                      _OrderItemRow(item: order.items[i]),
                      if (i != order.items.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Divider(
                            height: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                title: 'Payment & delivery',
                subtitle: 'Your order information',
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    _Detail(
                      label: 'Payment method',
                      value: order.paymentMethod,
                    ),
                    _Detail(
                      label: 'Payment status',
                      value: order.paymentStatus,
                    ),
                    _Detail(
                      label: 'Delivery address',
                      value: order.address,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Divider(
                        height: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                    _Detail(
                      label: 'Subtotal',
                      value: formatMoney(order.subtotal),
                    ),
                    _Detail(
                      label: 'Delivery fee',
                      value: order.delivery == 0
                          ? 'FREE'
                          : formatMoney(order.delivery),
                    ),
                    _Detail(
                      label: 'Total',
                      value: formatMoney(order.total),
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final options = [
      'Qty ${item.quantity}',
      if (item.size != null) 'Size ${item.size}',
      if (item.color != null) '${item.color}',
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductThumbnail(
          imageUrl: item.imageUrl,
          width: 76,
          height: 88,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  options,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  formatMoney(item.total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 11),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          child,
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.title,
    required this.done,
    required this.last,
    required this.active,
  });

  final String title;
  final bool done;
  final bool last;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 17),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 25,
              child: Column(
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: done ? AppColors.black : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? AppColors.black
                            : const Color(0xFFDADADA),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.circle,
                      size: done ? 14 : 5,
                      color: done ? Colors.white : const Color(0xFFDADADA),
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        color: done
                            ? AppColors.black
                            : const Color(0xFFE6E6E6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        active ? FontWeight.w800 : FontWeight.w600,
                        color: done
                            ? AppColors.black
                            : AppColors.grey600,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(height: 5),
                      const Text(
                        'Current order status',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NOW',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFFF3F3F3),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            size: 21,
            color: AppColors.grey600,
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F4F4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: AppColors.black),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: bold ? AppColors.black : AppColors.grey600,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.black,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

_StatusStyle _statusStyle(String status) {
  final value = status.toLowerCase();

  if (value.contains('deliver') || value.contains('complete')) {
    return const _StatusStyle(
      foreground: Color(0xFF176B45),
      background: Color(0xFFE7F5ED),
    );
  }

  if (value.contains('cancel') || value.contains('fail')) {
    return const _StatusStyle(
      foreground: Color(0xFFB42318),
      background: Color(0xFFFDECEC),
    );
  }

  if (value.contains('ship') ||
      value.contains('dispatch') ||
      value.contains('progress') ||
      value.contains('confirm')) {
    return const _StatusStyle(
      foreground: Color(0xFF2458A6),
      background: Color(0xFFEAF1FF),
    );
  }

  return const _StatusStyle(
    foreground: Color(0xFF805A16),
    background: Color(0xFFFFF4D8),
  );
}

bool _isFinished(String status) {
  final value = status.toLowerCase();
  return value.contains('deliver') ||
      value.contains('complete') ||
      value.contains('cancel') ||
      value.contains('fail');
}

IconData _paymentIcon(String paymentStatus) {
  final value = paymentStatus.toLowerCase();

  if (value.contains('paid') ||
      value.contains('complete') ||
      value.contains('success')) {
    return Icons.check_circle_outline_rounded;
  }

  if (value.contains('fail')) {
    return Icons.error_outline_rounded;
  }

  return Icons.pending_outlined;
}

int _currentTrackingStep(String status) {
  final value = status.toLowerCase();

  if (value.contains('deliver') || value.contains('complete')) return 5;
  if (value.contains('out for delivery')) return 4;
  if (value.contains('ship') || value.contains('dispatch')) return 3;
  if (value.contains('prepar')) return 2;
  if (value.contains('confirm')) return 1;
  return 0;
}

List<String> _trackingSteps(String status) {
  final value = status.toLowerCase();

  if (value.contains('cancel')) {
    return const [
      'Order placed',
      'Order cancelled',
    ];
  }

  if (value.contains('fail')) {
    return const [
      'Order placed',
      'Payment or order issue',
    ];
  }

  return const [
    'Order placed',
    'Order confirmed',
    'Preparing package',
    'Dispatched',
    'Out for delivery',
    'Delivered',
  ];
}

String _date(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}