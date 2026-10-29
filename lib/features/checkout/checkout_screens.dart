import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../core/theme/app_colors.dart';
import '../account/account_screens.dart';
import '../products/product_state.dart';
import '../orders/order_state.dart';
import '../auth/auth_state.dart';
import 'checkout_api.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/address_state.dart';

// IMPORTANT:
// Change this import if SavedAddress and savedAddressesProvider
// are defined in a different file.

// The selected address is an index into savedAddressesProvider.
// Null means: automatically use the default address, or the first address.
final selectedAddressProvider = StateProvider<int?>((ref) => null);

final selectedPaymentProvider =
StateProvider<String>((ref) => 'Airtel Money');

String formatMoney(double value) =>
'MWK ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

// Combines the saved street/house address and area into one delivery address.
String _fullSavedAddress(SavedAddress address) {
return [
address.address,
address.area,
].where((part) => part.trim().isNotEmpty).join(', ');
}

// Determines which saved address should be displayed.
// The selected address takes priority; otherwise, use the default address.
int _effectiveAddressIndex(
List<SavedAddress> addresses,
int? selectedIndex,
) {
if (addresses.isEmpty) return -1;

if (selectedIndex != null &&
selectedIndex >= 0 &&
selectedIndex < addresses.length) {
return selectedIndex;
}

final defaultIndex = addresses.indexWhere((address) => address.isDefault);

return defaultIndex >= 0 ? defaultIndex : 0;
}

class CheckoutScreen extends ConsumerWidget {
const CheckoutScreen({super.key});

@override
Widget build(BuildContext context, WidgetRef ref) {
final lines = ref.watch(storeProvider).cart.values.toList();

// Use the same saved-address provider as the Saved Addresses page.
  final token = ref.watch(authProvider).token;

  final addresses = token == null || token.isEmpty
      ? <SavedAddress>[]
      : ref.watch(savedAddressesProvider(token)).valueOrNull ?? <SavedAddress>[];

final selectedIndex = ref.watch(selectedAddressProvider);
final effectiveIndex =
_effectiveAddressIndex(addresses, selectedIndex);

final payment = ref.watch(selectedPaymentProvider);

final subtotal = lines.fold<double>(
0,
(sum, line) => sum + line.unitPrice * line.quantity,
);

final delivery = subtotal >= 50000 ? 0.0 : 2500.0;
final total = subtotal + delivery;

return Scaffold(
appBar: AppBar(
leading: Padding(
padding: const EdgeInsets.only(left: 22.0),
child: IconButton(
onPressed: () => context.pop(),
icon: const Icon(Icons.arrow_back),
),
),
backgroundColor: Colors.white,
elevation: 0,
title: Text(
'Checkout',
style: Theme.of(context).textTheme.headlineLarge,
),
),
body: Stack(
children: [
Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 980),
child: ListView(
padding: const EdgeInsets.fromLTRB(22, 28, 22, 48),
children: [
const Text(
'Delivery details and secure payment',
style: TextStyle(color: AppColors.grey600),
),
const SizedBox(height: 26),
if (lines.isEmpty) ...[
const _Notice(
icon: Icons.shopping_bag_outlined,
title: 'Your bag is empty',
message:
'Add products to your bag before checkout.',
),
const SizedBox(height: 16),
OutlinedButton(
onPressed: () => context.go('/explore'),
child: const Text('Explore products'),
),
] else ...[
// ------------------------------------------------------
// 01. DELIVERY ADDRESS
// Now connected to savedAddressesProvider.
// ------------------------------------------------------
_SectionTitle(
number: '01',
title: 'Delivery address',
trailing: TextButton.icon(
onPressed: addresses.isEmpty
? null
    : () => _selectAddressDialog(context, ref),
icon: const Icon(
Icons.location_on_outlined,
size: 18,
),
label: const Text('Select Address'),
),
),
if (addresses.isEmpty)
const _Notice(
icon: Icons.location_on_outlined,
title: 'No saved addresses',
message:
'Add a delivery address in your saved addresses section before checking out.',
)
else
_AddressTile(
address: addresses[effectiveIndex],
selected: true,
onTap: () => _selectAddressDialog(context, ref),
),

const SizedBox(height: 26),

// ------------------------------------------------------
// 02. SECURE PAYMENT
// ------------------------------------------------------
const _SectionTitle(
number: '02',
title: 'Secure payment',
),
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
border: Border.all(color: AppColors.grey200),
borderRadius: BorderRadius.circular(8),
),
child: const Row(
children: [
Icon(Icons.lock_outline, size: 22),
SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Pay securely with PayChangu',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
SizedBox(height: 4),
Text(
'Choose an available method on the secure payment page, including supported mobile money and cards.',
style: TextStyle(
color: AppColors.grey600,
fontSize: 12,
height: 1.4,
),
),
],
),
),
],
),
),

const SizedBox(height: 26),

// ------------------------------------------------------
// 03. ORDER SUMMARY
// ------------------------------------------------------
const _SectionTitle(
number: '03',
title: 'Order summary',
),
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
padding:
const EdgeInsets.only(bottom: 14),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
ClipRRect(
borderRadius:
BorderRadius.circular(4),
child: Image.network(
line.product.imageUrl,
width: 58,
height: 68,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) =>
Container(
width: 58,
height: 68,
color: AppColors.grey100,
child: const Icon(
Icons.image_outlined,
),
),
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
line.product.name,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
'Qty ${line.quantity}'
'${line.size == null ? '' : ' · Size ${line.size}'}'
'${line.color == null ? '' : ' · ${line.color}'}',
style: const TextStyle(
color: AppColors.grey600,
fontSize: 12,
),
),
const SizedBox(height: 4),
Text(
formatMoney(
line.product.price *
line.quantity,
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
_PriceRow(
label: 'Subtotal',
amount: formatMoney(subtotal),
),
const SizedBox(height: 10),
_PriceRow(
label: 'Delivery',
amount: delivery == 0
? 'FREE'
    : formatMoney(delivery),
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

const Text(
"Your order and stock are validated by the store server. Payment is completed on PayChangu's secure checkout page.",
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 11,
color: AppColors.grey600,
),
),

const SizedBox(height: 40),
],
],
),
),
),

// --------------------------------------------------------------
// FIXED PLACE ORDER BUTTON
// --------------------------------------------------------------
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
22,
12,
22,
12,
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
onPressed: effectiveIndex < 0
? null
    : () => _startCheckout(
context,
ref,
addresses[effectiveIndex],
),
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
],
),
);
}

// ----------------------------------------------------------------------
// CREATE ORDER AND OPEN PAYCHANGU
// Uses the selected SavedAddress; payment flow remains unchanged.
// ----------------------------------------------------------------------
Future<void> _startCheckout(
BuildContext context,
WidgetRef ref,
SavedAddress address,
) async {
final fullAddress = _fullSavedAddress(address);

if (fullAddress.trim().length < 5 ||
address.phone.trim().length < 7) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Please add a valid delivery address and phone number before checkout.',
),
),
);
return;
}

var loadingDialogOpen = false;
final auth = ref.read(authProvider);
final lines = ref.read(storeProvider).cart.values.toList();

if (!auth.isSignedIn || auth.token.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please sign in before checkout.'),
),
);
context.go('/login');
return;
}

if (lines.isEmpty) return;

showDialog<void>(
context: context,
barrierDismissible: false,
builder: (_) => const Center(
child: CircularProgressIndicator(),
),
);
loadingDialogOpen = true;

try {
final result = await CheckoutApi().createOrder(
token: auth.token,
address: fullAddress,
phone: address.phone,
items: lines
    .map(
(line) => {
'product_id': int.tryParse(line.product.id) ?? 0,
'variant_id': line.variantId,
'quantity': line.quantity,
},
)
    .toList(),
);

if (context.mounted) {
Navigator.of(context, rootNavigator: true).pop();
}
loadingDialogOpen = false;

final checkoutUrl =
Uri.tryParse('${result['checkout_url'] ?? ''}');

if (checkoutUrl == null || checkoutUrl.scheme != 'https') {
throw Exception(
'The payment provider returned an invalid checkout link.',
);
}

final launched = await launchUrl(
checkoutUrl,
mode: LaunchMode.externalApplication,
);

if (!launched) {
throw Exception(
'Could not open the PayChangu checkout page. Please allow pop-ups or try another browser.',
);
}

if (!context.mounted) return;

context.go(
'/payment-status',
extra: {
'total': (result['amount'] as num?)?.toDouble() ??
totalFallback(lines),
'method': 'PayChangu',
'address': fullAddress,
'tx_ref': result['tx_ref']?.toString() ?? '',
'orderId': result['order_id']?.toString() ?? '',
'orderNumber': result['order_number']?.toString() ?? '',
'checkoutUrl': checkoutUrl.toString(),
},
);
} catch (e) {
if (context.mounted) {
if (loadingDialogOpen) {
Navigator.of(context, rootNavigator: true).maybePop();
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
e.toString().replaceFirst('Exception: ', ''),
),
),
);
}
}
}

double totalFallback(List<CartLine> lines) {
return lines.fold<double>(
0,
(sum, line) => sum + line.unitPrice * line.quantity,
);
}

// ----------------------------------------------------------------------
// SELECT AN EXISTING SAVED ADDRESS
// No TextEditingControllers are created here.
// ----------------------------------------------------------------------
  Future<void> _selectAddressDialog(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final token = ref.read(authProvider).token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to select a saved address.'),
        ),
      );
      return;
    }

    try {
      // Retrieve the actual list from the asynchronous provider.
      final addresses = await ref.read(
        savedAddressesProvider(token).future,
      );

      if (!context.mounted) return;

      if (addresses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No saved addresses are available. Add one in your account first.',
            ),
          ),
        );
        return;
      }

      final currentIndex = _effectiveAddressIndex(
        addresses,
        ref.read(selectedAddressProvider),
      );

      final selectedIndex = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Select delivery address'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(addresses.length, (index) {
                    final address = addresses[index];
                    final isSelected = index == currentIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.of(dialogContext).pop(index);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.black
                                    : AppColors.grey200,
                                width: isSelected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: AppColors.black,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              address.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (address.isDefault)
                                            const Text(
                                              'DEFAULT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(address.phone),
                                      const SizedBox(height: 5),
                                      Text(
                                        _fullSavedAddress(address),
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
                      ),
                    );
                  }),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < addresses.length) {
        ref.read(selectedAddressProvider.notifier).state = selectedIndex;
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load saved addresses: '
                '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }
}

// ========================================================================
// PAYMENT STATUS SCREEN
// ========================================================================

class PaymentStatusScreen extends ConsumerStatefulWidget {
const PaymentStatusScreen({super.key, required this.data});

final Map<String, dynamic> data;

@override
ConsumerState<PaymentStatusScreen> createState() =>
_PaymentStatusScreenState();
}

class _PaymentStatusScreenState
extends ConsumerState<PaymentStatusScreen> {
bool processing = false;
String paymentStatus = 'pending';
String? errorMessage;

@override
void initState() {
super.initState();
}

@override
Widget build(BuildContext context) {
final total = (widget.data['total'] as num?)?.toDouble() ?? 0;
final method = widget.data['method'] as String? ?? 'PayChangu';
final address = widget.data['address'] as String? ?? '';
final txRef = widget.data['tx_ref'] as String? ?? '';
final orderNumber = widget.data['orderNumber'] as String? ??
widget.data['orderId'] as String? ??
'';

Future<void> checkPayment() async {
final auth = ref.read(authProvider);

if (!auth.isSignedIn || auth.token.isEmpty || txRef.isEmpty) {
setState(() {
errorMessage = 'Sign in again to check this payment.';
});
return;
}

setState(() {
processing = true;
errorMessage = null;
});

try {
final result = await CheckoutApi().verify(
token: auth.token,
txRef: txRef,
);

if (!mounted) return;

setState(() {
paymentStatus = (result['status'] ??
result['payment_status'] ??
'pending')
    .toString()
    .toLowerCase();
processing = false;
});

if (paymentStatus == 'paid') {
ref.read(storeProvider.notifier).clearCart();
}
} catch (e) {
if (mounted) {
setState(() {
errorMessage =
e.toString().replaceFirst('Exception: ', '');
processing = false;
});
}
}
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
processing
? 'Checking payment'
    : paymentStatus == 'paid'
? 'Payment confirmed'
    : paymentStatus == 'failed'
? 'Payment not completed'
    : 'Order created',
style: Theme.of(context).textTheme.headlineMedium,
textAlign: TextAlign.center,
),
const SizedBox(height: 10),
Text(
processing
? 'Verifying your transaction directly with PayChangu…'
    : paymentStatus == 'paid'
? 'Your payment is confirmed. Your order is being processed.'
    : paymentStatus == 'failed'
? 'The payment failed or was cancelled. If stock was reserved, the server will release it.'
    : 'Your order is awaiting payment. Complete the secure PayChangu checkout, then return here and check the payment status.',
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.grey600,
height: 1.5,
),
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
_PriceRow(
label: 'Payment method',
amount: method,
),
const SizedBox(height: 12),
_PriceRow(
label: 'Amount',
amount: formatMoney(total),
bold: true,
),
if (address.isNotEmpty) ...[
const SizedBox(height: 12),
const Divider(),
const Align(
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
'Order: $orderNumber\n'
'Transaction reference: $txRef\n'
'The store server verifies the amount, currency and transaction reference before marking this order paid.',
style: const TextStyle(
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
Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Text(
errorMessage!,
style: const TextStyle(color: Colors.red),
textAlign: TextAlign.center,
),
),
SizedBox(
width: double.infinity,
child: FilledButton(
onPressed: processing ? null : checkPayment,
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 14),
child: Text(
processing
? 'Checking…'
    : 'Check payment status',
),
),
),
),
const SizedBox(height: 8),
TextButton(
onPressed: () => context.go('/orders'),
child: const Text('View my orders'),
),
TextButton(
onPressed: () => context.go('/explore'),
child: const Text('Continue shopping'),
),
if (processing)
const Padding(
padding: EdgeInsets.only(top: 14),
child: CircularProgressIndicator(),
),
],
),
),
),
);
}
}

// ========================================================================
// ORDER CONFIRMATION SCREEN
// ========================================================================

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
child: const Icon(
Icons.receipt_long_outlined,
size: 42,
),
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
style: TextStyle(
color: AppColors.grey600,
height: 1.5,
),
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
_PriceRow(
label: 'Payment method',
amount: method,
),
if (address.isNotEmpty) ...[
const SizedBox(height: 12),
const Divider(),
const Align(
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

// ========================================================================
// SHARED UI COMPONENTS
// ========================================================================

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
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w700,
),
),
),
if (trailing != null) trailing!,
],
),
);
}

// This tile now accepts SavedAddress rather than DeliveryAddress.
class _AddressTile extends StatelessWidget {
const _AddressTile({
required this.address,
required this.selected,
required this.onTap,
});

final SavedAddress address;
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
color: selected
? AppColors.black
    : AppColors.grey200,
width: selected ? 1.5 : 1,
),
borderRadius: BorderRadius.circular(8),
),
child: Row(
children: [
Icon(
selected
? Icons.radio_button_checked
    : Icons.radio_button_off,
color: selected
? AppColors.black
    : AppColors.grey500,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
address.name,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
),
if (address.isDefault)
const Text(
'DEFAULT',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w700,
),
),
],
),
const SizedBox(height: 4),
Text(
_fullSavedAddress(address),
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
const SizedBox(width: 8),
const Icon(Icons.edit_location_alt_outlined, size: 18),
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
padding: const EdgeInsets.symmetric(
horizontal: 15,
vertical: 14,
),
decoration: BoxDecoration(
border: Border.all(
color: selected
? AppColors.black
    : AppColors.grey200,
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
style: const TextStyle(
fontWeight: FontWeight.w600,
),
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
selected
? Icons.radio_button_checked
    : Icons.radio_button_off,
color: selected
? AppColors.black
    : AppColors.grey500,
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
fontWeight:
bold ? FontWeight.w700 : FontWeight.w400,
fontSize: bold ? 15 : 13,
),
),
),
Text(
amount,
style: TextStyle(
fontWeight:
bold ? FontWeight.w800 : FontWeight.w600,
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
Text(
title,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 5),
Text(
message,
style: const TextStyle(
color: AppColors.grey600,
fontSize: 13,
),
),
],
),
),
],
),
);
}

// Retained from the original page so unrelated code is not removed.
// Checkout no longer uses this form to create delivery addresses.
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
validator: (value) =>
value == null || value.trim().isEmpty
? 'This field is required'
    : null,
),
);
}
