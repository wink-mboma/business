import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../products/product_state.dart';
import '../orders/order_state.dart';
import '../auth/auth_state.dart';
import 'checkout_api.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryAddress {
  const DeliveryAddress({
    required this.name,
    required this.phone,
    required this.area,
    required this.details,
    this.label = 'Home',
  });
  final String name, phone, area, details, label;
  String get oneLine => '$details, $area';
}

class CheckoutState extends StateNotifier<List<DeliveryAddress>> {
  CheckoutState()
      : super(const [
    DeliveryAddress(
      name: 'Winkford Mboma',
      phone: '+265 991 000 000',
      area: 'Area 18, Lilongwe',
      details: 'House 12, near main road',
    ),
  ]);
  void add(DeliveryAddress address) => state = [...state, address];
}

final addressesProvider =
StateNotifierProvider<CheckoutState, List<DeliveryAddress>>(
      (ref) => CheckoutState(),
);
final selectedAddressProvider = StateProvider<int>((ref) => 0);
final selectedPaymentProvider = StateProvider<String>((ref) => 'Airtel Money');

String formatMoney(double value) =>
    'MWK ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(storeProvider).cart.values.toList();
    final addresses = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressProvider);
    final payment = ref.watch(selectedPaymentProvider);
    final subtotal = lines.fold<double>(
      0,
          (sum, line) => sum + line.unitPrice * line.quantity,
    );
    final delivery = subtotal >= 50000 ? 0.0 : 2500.0;
    final total = subtotal + delivery;
    return  Stack(
        children: [

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 48),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Checkout',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Delivery details and secure payment',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                  const SizedBox(height: 26),
                  if (lines.isEmpty) ...[
                    const _Notice(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your bag is empty',
                      message: 'Add products to your bag before checkout.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/explore'),
                      child: const Text('Explore products'),
                    ),
                  ]
                  else ...[
                    _SectionTitle(
                      number: '01',
                      title: 'Delivery address',
                      trailing: TextButton.icon(
                        onPressed: () => _showAddressDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add new'),
                      ),
                    ),
                    if (addresses.isEmpty)
                      const _Notice(
                        icon: Icons.location_on_outlined,
                        title: 'Add a delivery address',
                        message:
                        'We need an address to calculate and arrange delivery.',
                      )
                    else
                      ...addresses.asMap().entries.map(
                            (entry) => _AddressTile(
                          address: entry.value,
                          selected: selected == entry.key,
                          onTap: () =>
                          ref.read(selectedAddressProvider.notifier).state =
                              entry.key,
                        ),
                      ),
                    const SizedBox(height: 26),
                    const _SectionTitle(number: '02', title: 'Secure payment'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.grey200), borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [
                        Icon(Icons.lock_outline, size: 22), SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Pay securely with PayChangu', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 4), Text('Choose an available method on the secure payment page, including supported mobile money and cards.', style: TextStyle(color: AppColors.grey600, fontSize: 12, height: 1.4)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 26),
                    const _SectionTitle(number: '03', title: 'Order summary'),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ...lines.map(
                                (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(imageUrl: 
                                      line.product.imageUrl,
                                      width: 58,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Shimmer.fromColors(baseColor: const Color(0xFFEAEAEA), highlightColor: const Color(0xFFF7F7F7), child: Container(color: Colors.white)),
                              errorWidget: (_, __, ___) => Container(
                                        width: 58,
                                        height: 68,
                                        color: AppColors.grey100,
                                        child: const Icon(Icons.image_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty ${line.quantity}${line.size == null ? '' : ' · Size ${line.size}'}${line.color == null ? '' : ' · ${line.color}'}',
                                          style: const TextStyle(
                                            color: AppColors.grey600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatMoney(
                                            line.product.price * line.quantity,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          _PriceRow(label: 'Subtotal', amount: formatMoney(subtotal)),
                          const SizedBox(height: 10),
                          _PriceRow(
                            label: 'Delivery',
                            amount: delivery == 0 ? 'FREE' : formatMoney(delivery),
                          ),
                          if (delivery == 0)
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Free delivery on orders MWK 50,000+',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ),
                            ),
                          const Divider(height: 28),
                          _PriceRow(
                            label: 'Total to pay',
                            amount: formatMoney(total),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    /*  FilledButton.icon(
                    onPressed: addresses.isEmpty
                        ? null
                        : () => context.push(
                      '/payment-status',
                      extra: {
                        'total': total,
                        'method': payment,
                        'address':
                        addresses[selected < 0
                            ? 0
                            : (selected >= addresses.length
                            ? addresses.length - 1
                            : selected)]
                            .oneLine,
                      },
                    ),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text('Continue to $payment · ${formatMoney(total)}'),
                    ),
                  ),*/

                    const Text(
                      "Your order and stock are validated by the store server. Payment is completed on PayChangu\'s secure checkout page.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.grey600),
                    ),

                    const SizedBox(height:40),
                  ],
                ],
              ),
            ),
          ),

          if (lines.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 16,
                    sigmaY: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      22, 12, 22, 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.94),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.grey200,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 936,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: addresses.isEmpty
                                  ? null
                                  : () => _startCheckout(context, ref, addresses[selected < 0 ? 0 : selected >= addresses.length ? addresses.length - 1 : selected]),
                              icon: const Icon(
                                Icons.lock_outline,
                                size: 18,
                              ),
                              label: Padding(
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: Text(
                                  'Place order & pay securely · '
                                      '${formatMoney(total)}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

        ]
    ) ;
  }

  Future<void> _startCheckout(BuildContext context, WidgetRef ref, DeliveryAddress address) async {
    var loadingDialogOpen = false;
    final auth = ref.read(authProvider);
    final lines = ref.read(storeProvider).cart.values.toList();
    if (!auth.isSignedIn || auth.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in before checkout.')));
      context.go('/login');
      return;
    }
    if (lines.isEmpty) return;
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    loadingDialogOpen = true;
    try {
      final result = await CheckoutApi().createOrder(
        token: auth.token,
        address: '${address.details}, ${address.area}',
        phone: address.phone,
        items: lines.map((line) => {'product_id':int.tryParse(line.product.id) ?? 0,'variant_id':line.variantId,'quantity':line.quantity}).toList(),
      );
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;
      final checkoutUrl = Uri.tryParse('${result['checkout_url'] ?? ''}');
      if (checkoutUrl == null || checkoutUrl.scheme != 'https') throw Exception('The payment provider returned an invalid checkout link.');
      final launched = await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Could not open the PayChangu checkout page. Please allow pop-ups or try another browser.');
      if (!context.mounted) return;
      context.go('/payment-status', extra: {
        'total': (result['amount'] as num?)?.toDouble() ?? totalFallback(lines),
        'method': 'PayChangu', 'address': '${address.details}, ${address.area}',
        'tx_ref': result['tx_ref']?.toString() ?? '',
        'orderId': result['order_id']?.toString() ?? '',
        'orderNumber': result['order_number']?.toString() ?? '',
        'checkoutUrl': checkoutUrl.toString(),
      });
    } catch (e) {
      if (context.mounted) {
        if (loadingDialogOpen) Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  double totalFallback(List<CartLine> lines) => lines.fold<double>(0, (sum, line) => sum + line.unitPrice * line.quantity);

  Future<void> _showAddressDialog(
      BuildContext context,
      WidgetRef ref,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _CheckoutAddressDialog(
        onSave: (address) {
          ref.read(addressesProvider.notifier).add(address);

          ref.read(selectedAddressProvider.notifier).state =
              ref.read(addressesProvider).length - 1;
        },
      ),
    );
  }

}

class _CheckoutAddressDialog extends StatefulWidget {
  const _CheckoutAddressDialog({
    required this.onSave,
  });

  final ValueChanged<DeliveryAddress> onSave;

  @override
  State<_CheckoutAddressDialog> createState() =>
      _CheckoutAddressDialogState();
}

class _CheckoutAddressDialogState
    extends State<_CheckoutAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _areaController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _areaController = TextEditingController();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _detailsController.dispose();

    super.dispose();
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;

    final address = DeliveryAddress(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      area: _areaController.text.trim(),
      details: _detailsController.text.trim(),
    );

    widget.onSave(address);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New delivery address'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddressInput(
                  controller: _nameController,
                  label: 'Recipient full name',
                ),
                _AddressInput(
                  controller: _phoneController,
                  label: 'Phone number',
                  keyboard: TextInputType.phone,
                ),
                _AddressInput(
                  controller: _areaController,
                  label: 'Area / city (e.g. Area 18, Lilongwe)',
                ),
                _AddressInput(
                  controller: _detailsController,
                  label: 'House, street or landmark',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveAddress,
          child: const Text('Save address'),
        ),
      ],
    );
  }
}

class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  bool processing = false;
  String paymentStatus = 'pending';
  String? errorMessage;
  @override
  void initState() { super.initState(); }

  @override
  Widget build(BuildContext context) {
    final total = (widget.data['total'] as num?)?.toDouble() ?? 0;
    final method = widget.data['method'] as String? ?? 'PayChangu';
    final address = widget.data['address'] as String? ?? '';
    final txRef = widget.data['tx_ref'] as String? ?? '';
    final orderNumber = widget.data['orderNumber'] as String? ?? widget.data['orderId'] as String? ?? '';
    Future<void> checkPayment() async {
      final auth = ref.read(authProvider);
      if (!auth.isSignedIn || auth.token.isEmpty || txRef.isEmpty) { setState(() { errorMessage = 'Sign in again to check this payment.'; }); return; }
      setState(() { processing = true; errorMessage = null; });
      try { final result = await CheckoutApi().verify(token: auth.token, txRef: txRef); if (!mounted) return; setState(() { paymentStatus = (result['status'] ?? result['payment_status'] ?? 'pending').toString().toLowerCase(); processing = false; }); if (paymentStatus == 'paid') ref.read(storeProvider.notifier).clearCart(); }
      catch (e) { if (mounted) setState(() { errorMessage = e.toString().replaceFirst('Exception: ', ''); processing = false; }); }
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                processing
                    ? Icons.hourglass_top_rounded
                    : Icons.info_outline_rounded,
                size: 68,
                color: AppColors.black,
              ),
              const SizedBox(height: 22),
              Text(
                processing ? 'Checking payment' : (paymentStatus == 'paid' ? 'Payment confirmed' : paymentStatus == 'failed' ? 'Payment not completed' : 'Order created'),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                processing ? 'Verifying your transaction directly with PayChangu…' : (paymentStatus == 'paid' ? 'Your payment is confirmed. Your order is being processed.' : paymentStatus == 'failed' ? 'The payment failed or was cancelled. If stock was reserved, the server will release it.' : 'Your order is awaiting payment. Complete the secure PayChangu checkout, then return here and check the payment status.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey600, height: 1.5),
              ),
              const SizedBox(height: 26),
              if (!processing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    border: Border.all(color: AppColors.grey200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _PriceRow(label: 'Payment method', amount: method),
                      const SizedBox(height: 12),
                      _PriceRow(
                        label: 'Amount',
                        amount: formatMoney(total),
                        bold: true,
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Deliver to',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(address),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Order: $orderNumber\nTransaction reference: $txRef\nThe store server verifies the amount, currency and transaction reference before marking this order paid.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (errorMessage != null)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: processing ? null : checkPayment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(processing ? 'Checking…' : 'Check payment status'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/orders'), child: const Text('View my orders')),
              TextButton(onPressed: () => context.go('/explore'), child: const Text('Continue shopping')),
              if (processing) const Padding(padding: EdgeInsets.only(top: 14), child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final method = data['method'] as String? ?? 'PayChangu';
    final address = data['address'] as String? ?? '';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 42),
              ),
              const SizedBox(height: 22),
              Text(
                'Order preview created',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'This is a demonstration confirmation only. Your order is not placed and payment is not verified until the backend is connected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey600, height: 1.5),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'REFERENCE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['orderId'] as String? ?? 'DEMO-ORDER',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Divider(height: 28),
                    _PriceRow(
                      label: 'Total',
                      amount: formatMoney(total),
                      bold: true,
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(label: 'Payment method', amount: method),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Delivery address',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(address),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final id = data['orderId'] as String?;
                    if (id != null) {
                      context.go('/orders/$id');
                    } else {
                      context.go('/orders');
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Track this order'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(storeProvider.notifier).clearCart();
                    context.go('/');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Continue shopping'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.number,
    required this.title,
    this.trailing,
  });
  final String number, title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });
  final DeliveryAddress address;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.black : AppColors.grey200,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.black : AppColors.grey500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(address.name, style: const TextStyle(fontSize: 13)),
                  Text(
                    address.oneLine,
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    address.phone,
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                    ),
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

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final String method;
  final bool selected;
  final VoidCallback onTap;
  IconData get icon =>
      method == 'Visa' ? Icons.credit_card : Icons.phone_android;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.black : AppColors.grey200,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    method == 'Visa'
                        ? 'Debit or credit card via PayChangu'
                        : 'Mobile money via PayChangu',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.black : AppColors.grey500,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });
  final String label, amount;
  final bool bold;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: bold ? 17 : 13,
        ),
      ),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.grey50,
      border: Border.all(color: AppColors.grey200),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(color: AppColors.grey600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AddressInput extends StatelessWidget {
  const _AddressInput({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.streetAddress,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required'
          : null,
    ),
  );
}
