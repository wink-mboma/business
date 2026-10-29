import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_state.dart';
import '../checkout/data/address_state.dart';
import '../checkout/data/customer_addresses_api.dart';
import '../products/product_state.dart';

final accountNotificationsProvider = StateProvider<Map<String, bool>>(
  (ref) => {
    'Order updates': true,
    'Promotions and offers': false,
    'Product recommendations': true,
  },
);

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const _ink = Color(0xFF171717);
  static const _muted = Color(0xFF777777);
  static const _canvas = Color(0xFFF7F7F7);
  static const _line = Color(0xFFEAEAEA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final signedIn = auth.isSignedIn;
    final name = auth.displayName.trim().isNotEmpty
        ? auth.displayName.trim()
        : 'Guest shopper';

    final email = auth.email.trim();
    final initial = signedIn && name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        surfaceTintColor: _canvas,
        elevation: 0,
        title: const Text(
          'MY PROFILE',
          style: TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/account/settings'),
            icon: const Icon(Icons.settings_outlined, color: _ink),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              // Profile hero
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: signedIn && (auth.profileImageUrl ?? '').isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(21), child: CachedNetworkImage(imageUrl: auth.profileImageUrl!, fit: BoxFit.cover, width: 64, height: 64, placeholder: (_, __) => Shimmer.fromColors(baseColor: const Color(0xFFEAEAEA), highlightColor: Colors.white, child: Container(width: 64, height: 64, color: Colors.white)), errorWidget: (_, __, ___) => const Icon(Icons.person, size: 30)))
                              : Padding(padding:  EdgeInsets.all(10.0), child: Image.asset("assets/light-logo.png")),
                        ),
                          SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                signedIn ? 'Welcome back,' : 'Welcome to',
                                style: const TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                            Image.asset("assets/dark-logo2.png", height: 40, width: 150,),
                              const SizedBox(height: 5),
                              Text(
                                signedIn
                                    ? (email.isNotEmpty
                                    ? email
                                    : 'Your Sound Mafioso account')
                                    : 'Your personal shopping space',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (signedIn)
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white70,
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 23),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            signedIn
                                ? 'Manage your shopping experience'
                                : 'Sign in for a more personal experience',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!signedIn)
                          IconButton(
                            tooltip: 'Sign in',
                            onPressed: () => context.push('/login'),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _ink,
                              minimumSize: const Size(42, 42),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 27),

              _sectionTitle('YOUR SHOPPING'),

              // Shopping shortcuts
              Row(
                children: [
                  Expanded(
                    child: _shortcut(
                      icon: Icons.receipt_long_outlined,
                      title: 'My orders',
                      subtitle: 'Track purchases',
                      onTap: () => context.push('/orders'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _shortcut(
                      icon: Icons.location_on_outlined,
                      title: 'Addresses',
                      subtitle: 'Delivery details',
                      onTap: () => context.push('/account/addresses'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 27),

              _sectionTitle('ACCOUNT DETAILS'),

              _menuTile(
                icon: Icons.person_outline_rounded,
                title: 'Personal details',
                subtitle: 'Manage your name and email',
                onTap: () => _editProfile(context, ref),
              ),
              _menuTile(
                icon: Icons.location_on_outlined,
                title: 'Saved addresses',
                subtitle: 'Manage delivery locations',
                onTap: () => context.push('/account/addresses'),
              ),
              _menuTile(
                icon: Icons.receipt_long_outlined,
                title: 'Order history',
                subtitle: 'View orders and delivery status',
                onTap: () => context.push('/orders'),
              ),

              const SizedBox(height: 24),

              _sectionTitle('PREFERENCES & SUPPORT'),

              _menuTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Choose the updates you receive',
                onTap: () => context.push('/account/notifications'),
              ),
              _menuTile(
                icon: Icons.tune_rounded,
                title: 'App settings',
                subtitle: 'Currency, privacy and preferences',
                onTap: () => context.push('/account/settings'),
              ),
              _menuTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Help & support',
                subtitle: 'Get help with products or orders',
                onTap: () => context.push('/chat'),
              ),

              const SizedBox(height: 24),

              if (signedIn)
                SizedBox(
                  height: 53,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 53,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded, size: 19),
                    label: const Text('Sign in or create an account'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              const Center(
                child: Column(
                  children: [
                    Text(
                      'Sound Mafioso',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'LESS, BUT BETTER.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        letterSpacing: 1.8,
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

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: _muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  static Widget _shortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _canvas,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _ink, size: 21),
              ),
              const SizedBox(height: 17),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _canvas,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _ink, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF999999),
          size: 21,
        ),
      ),
    );
  }

  static Future<void> _editProfile(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final auth = ref.read(authProvider);
    final name = TextEditingController(text: auth.displayName);
    final email = TextEditingController(text: auth.email);
    String? error;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Personal details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final fullName = name.text.trim();
                  final address = email.text.trim();

                  if (fullName.isEmpty ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(address)) {
                    setDialogState(() {
                      error = 'Enter a name and a valid email address.';
                    });
                    return;
                  }

                  // Update the profile displayed in the current app session.
                  ref.read(authProvider.notifier).updateProfile(
                    email: address,
                    displayName: fullName,
                  );

                  Navigator.pop(dialogContext);
                },
                child: const Text('Save changes'),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      email.dispose();
    }
  }

  static Future<void> _confirmSignOut(
      BuildContext context,
      WidgetRef ref,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign in again whenever you want to continue shopping.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(authProvider.notifier).signOut();
    await ref.read(storeProvider.notifier).disconnectAccount();
    if (!context.mounted) return;
    context.go('/');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have signed out.')),
    );
  }
}



class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState
    extends ConsumerState<SavedAddressesScreen> {
  bool _working = false;

  String? get _token {
    final auth = ref.read(authProvider);
    if (!auth.isSignedIn || auth.token.isEmpty) return null;
    return auth.token;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshAddresses() async {
    final token = _token;
    if (token == null) return;

    ref.invalidate(savedAddressesProvider(token));

    try {
      await ref.read(savedAddressesProvider(token).future);
    } catch (_) {
      // The provider exposes the error to the screen.
    }
  }

  Future<void> _makeDefault(SavedAddress address) async {
    final token = _token;
    final id = address.id;

    if (token == null) {
      _showMessage('Please sign in to manage your addresses.');
      return;
    }

    if (id == null || id.isEmpty) {
      _showMessage('This address has no valid ID. Refresh and try again.');
      return;
    }

    if (_working) return;
    setState(() => _working = true);

    try {
      await CustomerAddressesApi().setDefault(
        token: token,
        id: id,
      );

      await _refreshAddresses();
      _showMessage('Default address updated.');
    } catch (e) {
      _showMessage('Could not update the default address. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    final token = _token;
    final id = address.id;

    if (token == null) {
      _showMessage('Please sign in to manage your addresses.');
      return;
    }

    if (id == null || id.isEmpty) {
      _showMessage('This address has no valid ID. Refresh and try again.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 30),
        title: const Text(
          'Remove address?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove "${address.name}" from your saved delivery addresses?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep address'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (_working) return;

    setState(() => _working = true);

    try {
      await CustomerAddressesApi().deleteAddress(
        token: token,
        id: id,
      );

      await _refreshAddresses();
      _showMessage('Address removed.');
    } catch (e) {
      _showMessage('Could not remove the address. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _addAddress(List<SavedAddress> existing) async {
    final token = _token;

    if (token == null) {
      _showMessage('Please sign in before saving a delivery address.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddAddressDialog(
        initiallyDefault: existing.isEmpty ||
            !existing.any((address) => address.isDefault),
        onSave: (newAddress, makeDefault) async {
          if (_working) return;

          setState(() => _working = true);

          try {
            await CustomerAddressesApi().createAddress(
              token: token,
              name: newAddress.name,
              phone: newAddress.phone,
              address: newAddress.address,
              area: newAddress.area,
              isDefault: makeDefault || existing.isEmpty,
            );

            await _refreshAddresses();

            if (mounted) {
              _showMessage('Address saved successfully.');
            }
          } catch (e) {
            throw Exception(
              'Could not save your address. Check your connection and try again.',
            );
          } finally {
            if (mounted) setState(() => _working = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final token = auth.isSignedIn ? auth.token : '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Saved addresses',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      floatingActionButton: auth.isSignedIn && token.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _working
            ? null
            : () {
          final state = ref.read(savedAddressesProvider(token));
          state.when(
            data: (addresses) => _addAddress(addresses),
            loading: () => _showMessage(
              'Please wait while addresses are loading.',
            ),
            error: (_, __) => _showMessage(
              'Refresh addresses before adding a new one.',
            ),
          );
        },
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add address',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: !auth.isSignedIn || token.isEmpty
              ? _SignInForAddresses(
            onSignIn: () => context.push('/login'),
          )
              : ref.watch(savedAddressesProvider(token)).when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.black,
              ),
            ),
            error: (error, stackTrace) => _AddressLoadError(
              onRetry: _refreshAddresses,
            ),
            data: (addresses) {
              final defaultCount =
                  addresses.where((a) => a.isDefault).length;

              if (addresses.isEmpty) {
                return _EmptyAddresses(
                  onAdd: () => _addAddress(addresses),
                );
              }

              return Stack(
                children: [
                  ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      110,
                    ),
                    children: [
                      _AddressIntro(
                        count: addresses.length,
                        defaultCount: defaultCount,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your locations',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          Text(
                            '${addresses.length} saved',
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final address in addresses)
                        Padding(
                          key: ValueKey(address.id),
                          padding: const EdgeInsets.only(bottom: 13),
                          child: _AddressCard(
                            address: address,
                            onMakeDefault: () => _makeDefault(address),
                            onDelete: () => _deleteAddress(address),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const _AddressPrivacyNote(),
                    ],
                  ),
                  if (_working)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        color: AppColors.black,
                        backgroundColor: Color(0xFFEAEAEA),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignInForAddresses extends StatelessWidget {
  const _SignInForAddresses({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.black,
            ),
            const SizedBox(height: 18),
            const Text(
              'Sign in to manage addresses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your delivery addresses are saved securely to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressLoadError extends StatelessWidget {
  const _AddressLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.grey600,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load addresses',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey600),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog({
    required this.initiallyDefault,
    required this.onSave,
  });

  final bool initiallyDefault;
  final Future<void> Function(
      SavedAddress address,
      bool makeDefault,
      ) onSave;

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;

  late bool _makeDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _areaController = TextEditingController();
    _makeDefault = widget.initiallyDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final newAddress = SavedAddress(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      isDefault: _makeDefault,
    );

    setState(() => _saving = true);

    try {
      await widget.onSave(newAddress, _makeDefault);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(23),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New address',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Where should we deliver?',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _AddressField(
                  controller: _nameController,
                  label: 'Recipient name',
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter the recipient name'
                      : null,
                ),
                const SizedBox(height: 15),
                _AddressField(
                  controller: _phoneController,
                  label: 'Phone number',
                  hint: 'e.g. 0991 234 567',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter a phone number';
                    if (text.replaceAll(RegExp(r'\D'), '').length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _AddressField(
                  controller: _addressController,
                  label: 'Street / house / landmark',
                  hint: 'House number, street or nearby landmark',
                  icon: Icons.home_outlined,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter your delivery address'
                      : null,
                ),
                const SizedBox(height: 15),
                _AddressField(
                  controller: _areaController,
                  label: 'City or district',
                  hint: 'e.g. Lilongwe',
                  icon: Icons.location_city_outlined,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter your city or district'
                      : null,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEAEAEA),
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.black,
                    title: const Text(
                      'Set as default address',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'Use this address for future deliveries',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey600,
                      ),
                    ),
                    value: _makeDefault,
                    onChanged: _saving
                        ? null
                        : (checked) {
                      setState(() {
                        _makeDefault = checked ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Save address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onMakeDefault,
    required this.onDelete,
  });

  final SavedAddress address;
  final VoidCallback onMakeDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: address.isDefault
              ? AppColors.black
              : const Color(0xFFE8E8E8),
          width: address.isDefault ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? AppColors.black
                      : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: address.isDefault
                      ? Colors.white
                      : AppColors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        address.area,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Address options',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.grey600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'default') onMakeDefault();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 19),
                          SizedBox(width: 10),
                          Text('Set as default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 19),
                        SizedBox(width: 10),
                        Text('Remove address'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 17,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        address.address,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        address.phone,
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (address.isDefault) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'DEFAULT ADDRESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                TextButton.icon(
                  onPressed: onMakeDefault,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  icon: const Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Make default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Remove address',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.grey600,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _AddressPrivacyNote extends StatelessWidget {
  const _AddressPrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: AppColors.grey600,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your saved addresses make checkout easier. In this prototype, addresses are stored locally in app state and will reset when the app restarts.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEFEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 36,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No saved addresses yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Add a delivery address to make your next checkout quicker and easier.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey600,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first address'),
            ),
          ],
        ),
      ),
    );
  }
}
class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              size: 19,
              color: AppColors.grey600,
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.black,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressIntro extends StatelessWidget {
  const _AddressIntro({
    required this.count,
    required this.defaultCount,
  });

  final int count;
  final int defaultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery made simple',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count saved ${count == 1 ? 'location' : 'locations'} · '
                      '${defaultCount > 0 ? 'Default address set' : 'No default set'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_shipping_outlined,
            color: Colors.white70,
            size: 25,
          ),
        ],
      ),
    );
  }
}
/*
class SavedAddress {
  SavedAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    this.isDefault = false,
  });
  final String name;
  final String phone;
  final String address;
  final String area;
  final bool isDefault;
}

final savedAddressesProvider = StateProvider<List<SavedAddress>>(
      (ref) => [
    SavedAddress(
      name: 'Alex Morgan',
      phone: '+265 991 234 567',
      address: 'Area 10, House 24',
      area: 'Lilongwe',
      isDefault: true,
    ),
  ],
);
class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(savedAddressesProvider);
    final defaultCount = addresses.where((a) => a.isDefault).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Saved addresses',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAddress(context, ref),
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add address',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: addresses.isEmpty
              ? _EmptyAddresses(onAdd: () => _addAddress(context, ref))
              : ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              _AddressIntro(
                count: addresses.length,
                defaultCount: defaultCount,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your locations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Text(
                    '${addresses.length} saved',
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < addresses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _AddressCard(
                    address: addresses[i],
                    onMakeDefault: () => _makeDefault(ref, i),
                    onDelete: () => _deleteAddress(
                      context,
                      ref,
                      i,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const _AddressPrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }

  void _makeDefault(WidgetRef ref, int index) {
    final current = [...ref.read(savedAddressesProvider)];
    if (index < 0 || index >= current.length) return;

    final selected = current[index];

    ref.read(savedAddressesProvider.notifier).state = [
      for (var i = 0; i < current.length; i++)
        SavedAddress(
          name: current[i].name,
          phone: current[i].phone,
          address: current[i].address,
          area: current[i].area,
          isDefault: i == index,
        ),
    ];
  }

  Future<void> _deleteAddress(
      BuildContext context,
      WidgetRef ref,
      int index,
      ) async {
    final current = [...ref.read(savedAddressesProvider)];
    if (index < 0 || index >= current.length) return;

    final address = current[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.delete_outline_rounded,
          size: 30,
        ),
        title: const Text(
          'Remove address?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove "${address.name}" from your saved delivery addresses?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep address'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final latest = [...ref.read(savedAddressesProvider)];
    if (index >= latest.length) return;

    final removedWasDefault = latest[index].isDefault;
    latest.removeAt(index);

    // Keep a default address when any addresses remain.
    if (removedWasDefault && latest.isNotEmpty) {
      final first = latest.first;
      latest[0] = SavedAddress(
        name: first.name,
        phone: first.phone,
        address: first.address,
        area: first.area,
        isDefault: true,
      );
    }

    ref.read(savedAddressesProvider.notifier).state = latest;
  }

  Future<void> _addAddress(
      BuildContext context,
      WidgetRef ref,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AddAddressDialog(
          initiallyDefault: ref.read(savedAddressesProvider).isEmpty,
          onSave: (newAddress, makeDefault) {
            final current = [...ref.read(savedAddressesProvider)];

            final shouldBeDefault = makeDefault || current.isEmpty;

            final updated = [
              for (final item in current)
                SavedAddress(
                  name: item.name,
                  phone: item.phone,
                  address: item.address,
                  area: item.area,
                  isDefault: shouldBeDefault ? false : item.isDefault,
                ),
              SavedAddress(
                name: newAddress.name,
                phone: newAddress.phone,
                address: newAddress.address,
                area: newAddress.area,
                isDefault: shouldBeDefault,
              ),
            ];

            ref.read(savedAddressesProvider.notifier).state = updated;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address saved successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }
}
class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog({
    required this.initiallyDefault,
    required this.onSave,
  });

  final bool initiallyDefault;
  final void Function(SavedAddress address, bool makeDefault) onSave;

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;

  late bool _makeDefault;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _areaController = TextEditingController();

    _makeDefault = widget.initiallyDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();

    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newAddress = SavedAddress(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      isDefault: _makeDefault,
    );

    widget.onSave(newAddress, _makeDefault);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(23),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New address',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Where should we deliver?',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                _AddressField(
                  controller: _nameController,
                  label: 'Recipient name',
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter the recipient name'
                      : null,
                ),
                const SizedBox(height: 15),

                _AddressField(
                  controller: _phoneController,
                  label: 'Phone number',
                  hint: 'e.g. 0991 234 567',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Enter a phone number';
                    }

                    if (text.replaceAll(RegExp(r'\D'), '').length < 7) {
                      return 'Enter a valid phone number';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _AddressField(
                  controller: _addressController,
                  label: 'Street / house / landmark',
                  hint: 'House number, street or nearby landmark',
                  icon: Icons.home_outlined,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter your delivery address'
                      : null,
                ),
                const SizedBox(height: 15),

                _AddressField(
                  controller: _areaController,
                  label: 'City or district',
                  hint: 'e.g. Lilongwe',
                  icon: Icons.location_city_outlined,
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter your city or district'
                      : null,
                ),
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEAEAEA),
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.black,
                    title: const Text(
                      'Set as default address',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'Use this address for future deliveries',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey600,
                      ),
                    ),
                    value: _makeDefault,
                    onChanged: (checked) {
                      setState(() {
                        _makeDefault = checked ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text(
                      'Save address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
class _AddressIntro extends StatelessWidget {
  const _AddressIntro({
    required this.count,
    required this.defaultCount,
  });

  final int count;
  final int defaultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery made simple',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count saved ${count == 1 ? 'location' : 'locations'} · '
                      '${defaultCount > 0 ? 'Default address set' : 'No default set'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_shipping_outlined,
            color: Colors.white70,
            size: 25,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onMakeDefault,
    required this.onDelete,
  });

  final SavedAddress address;
  final VoidCallback onMakeDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: address.isDefault
              ? AppColors.black
              : const Color(0xFFE8E8E8),
          width: address.isDefault ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? AppColors.black
                      : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: address.isDefault
                      ? Colors.white
                      : AppColors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        address.area,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Address options',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.grey600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'default') onMakeDefault();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 19),
                          SizedBox(width: 10),
                          Text('Set as default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 19),
                        SizedBox(width: 10),
                        Text('Remove address'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 17,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        address.address,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        address.phone,
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (address.isDefault) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'DEFAULT ADDRESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                TextButton.icon(
                  onPressed: onMakeDefault,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  icon: const Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Make default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Remove address',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.grey600,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              size: 19,
              color: AppColors.grey600,
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.black,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEFEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 36,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No saved addresses yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Add a delivery address to make your next checkout quicker and easier.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey600,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first address'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressPrivacyNote extends StatelessWidget {
  const _AddressPrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: AppColors.grey600,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your saved addresses make checkout easier. In this prototype, addresses are stored locally in app state and will reset when the app restarts.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/



class AccountNotificationsScreen extends ConsumerWidget {
  const AccountNotificationsScreen({super.key});

  static const Map<String, _NotificationInfo> _notificationInfo = {
    'Order updates': _NotificationInfo(
      subtitle: 'Payment confirmations, order status and delivery updates.',
      icon: Icons.local_shipping_outlined,
      category: 'ESSENTIAL UPDATES',
    ),
    'Promotions and offers': _NotificationInfo(
      subtitle: 'Discover sales, discounts and special announcements.',
      icon: Icons.local_offer_outlined,
      category: 'SHOPPING',
    ),
    'Personalised recommendations': _NotificationInfo(
      subtitle: 'Product suggestions based on your interests.',
      icon: Icons.auto_awesome_outlined,
      category: 'SHOPPING',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref.watch(accountNotificationsProvider);
    final notifier = ref.read(accountNotificationsProvider.notifier);
    final enabledCount = values.values.where((value) => value).length;
    final allEnabled =
        values.isNotEmpty && values.values.every((value) => value);

    void updatePreference(String key, bool value) {
      notifier.state = {
        ...ref.read(accountNotificationsProvider),
        key: value,
      };
    }

    void updateAll(bool value) {
      notifier.state = {
        for (final entry in ref.read(accountNotificationsProvider).entries)
          entry.key: value,
      };
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '$enabledCount OF ${values.length} ON',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Stay in the loop.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Choose what you hear from Sound Mafioso, from order progress '
                      'to offers picked for you.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => updateAll(!allEnabled),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allEnabled
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            allEnabled
                                ? 'Turn off all preferences'
                                : 'Enable all preferences',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const _NotificationSectionHeading(
            title: 'ORDER NOTIFICATIONS',
            subtitle: 'Important updates about your purchases',
          ),
          const SizedBox(height: 12),

          _NotificationGroup(
            children: values.entries
                .where((entry) => entry.key == 'Order updates')
                .map(
                  (entry) => _NotificationPreferenceTile(
                title: entry.key,
                subtitle: _infoFor(entry.key).subtitle,
                icon: _infoFor(entry.key).icon,
                value: entry.value,
                onChanged: (value) =>
                    updatePreference(entry.key, value),
              ),
            )
                .toList(),
          ),

          const SizedBox(height: 26),

          const _NotificationSectionHeading(
            title: 'SHOPPING & DISCOVERY',
            subtitle: 'Offers and ideas for your next purchase',
          ),
          const SizedBox(height: 12),

          _NotificationGroup(
            children: values.entries
                .where((entry) => entry.key != 'Order updates')
                .map(
                  (entry) => _NotificationPreferenceTile(
                title: entry.key,
                subtitle: _infoFor(entry.key).subtitle,
                icon: _infoFor(entry.key).icon,
                value: entry.value,
                onChanged: (value) =>
                    updatePreference(entry.key, value),
              ),
            )
                .toList(),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 21,
                  color: Colors.black54,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'These preferences control your selections in the app. '
                        'Push notifications also require notification permissions '
                        'and a configured delivery service.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static _NotificationInfo _infoFor(String key) {
    return _notificationInfo[key] ??
        const _NotificationInfo(
          subtitle: 'Choose whether you want to receive these updates.',
          icon: Icons.notifications_none_rounded,
          category: 'GENERAL',
        );
  }
}

class _NotificationInfo {
  final String subtitle;
  final IconData icon;
  final String category;

  const _NotificationInfo({
    required this.subtitle,
    required this.icon,
    required this.category,
  });
}

class _NotificationSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotificationSectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  final List<Widget> children;

  const _NotificationGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: children.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'No preferences in this section.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      )
          : Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 70),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: Color(0xFFEFEFEF),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationPreferenceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.black, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: Colors.black,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool biometric = false;
  bool analytics = true;
  String currency = 'MWK (Malawi Kwacha)';

  static const currencies = [
    'MWK (Malawi Kwacha)',
    'USD (US Dollar)',
    'ZAR (South African Rand)',
    'GBP (British Pound)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          // Settings introduction
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Make it yours.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your shopping preferences, privacy and app settings.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.currency_exchange_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DISPLAY CURRENCY',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              currency,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _heading('APP PREFERENCES', 'Personalise your experience'),
          const SizedBox(height: 12),

          _settingsGroup([
            _settingsTile(
              icon: Icons.currency_exchange_rounded,
              title: 'Display currency',
              subtitle: currency,
              onTap: _chooseCurrency,
            ),
            _divider(),
            _settingsTile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric unlock',
              subtitle: 'Use fingerprint or Face ID',
              trailing: Switch.adaptive(
                value: biometric,
                activeColor: Colors.white,
                activeTrackColor: Colors.black,
                onChanged: (value) {
                  setState(() => biometric = value);
                },
              ),
              onTap: () => setState(() => biometric = !biometric),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.insights_rounded,
              title: 'Usage analytics',
              subtitle: 'Help us improve your experience',
              trailing: Switch.adaptive(
                value: analytics,
                activeColor: Colors.white,
                activeTrackColor: Colors.black,
                onChanged: (value) {
                  setState(() => analytics = value);
                },
              ),
              onTap: () => setState(() => analytics = !analytics),
            ),
          ]),

          const SizedBox(height: 28),
          _heading('PRIVACY & LEGAL', 'Know how your information is handled'),
          const SizedBox(height: 12),

          _settingsGroup([
            _settingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy policy',
              subtitle: 'How we handle your information',
              onTap: () => _openPage(const PrivacyPolicyScreen()),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.description_outlined,
              title: 'Terms & conditions',
              subtitle: 'Rules for using Sound Mafioso',
              onTap: () => _openPage(const TermsConditionsScreen()),
            ),
          ]),

          const SizedBox(height: 28),
          _heading('ABOUT', 'More information'),
          const SizedBox(height: 12),

          _settingsGroup([
            _settingsTile(
              icon: Icons.info_outline_rounded,
              title: 'App information',
              subtitle: 'Sound Mafioso · Version 1.0.0',
              onTap: () => _openPage(const AboutStoreScreen()),
            ),
          ]),

          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sound Mafioso',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Version 1.0.0 • Demo',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.black, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 70),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: Color(0xFFEFEFEF),
      ),
    );
  }

  Future<void> _chooseCurrency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Choose currency',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your preferred display currency.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              ...currencies.map(
                    (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: item == currency
                      ? const Icon(Icons.check_circle, color: Colors.black)
                      : const Icon(
                    Icons.circle_outlined,
                    color: Colors.black26,
                  ),
                  onTap: () => Navigator.pop(sheetContext, item),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => currency = selected);
    }
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE LEGAL PAGE
// -----------------------------------------------------------------------------

class _LegalSection {
  final String title;
  final String content;

  const _LegalSection(this.title, this.content);
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_LegalSection> sections;

  const _LegalPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.2,
                    letterSpacing: -0.6,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFF0E0BA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF8A6418),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sample policy content. Review and customise this '
                        'information to match your business and applicable '
                        'laws before publishing.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Color(0xFF6D521B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          ...sections.map(
                (section) => Padding(
              padding: const EdgeInsets.only(bottom: 23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    section.content,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.8,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Sound Mafioso • VERSION 1.0.0',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PRIVACY POLICY
// -----------------------------------------------------------------------------

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const sections = <_LegalSection>[
    _LegalSection(
      '1. Introduction',
      'Sound Mafioso provides an online shopping experience where customers '
          'can browse products, manage a cart and place orders. This policy '
          'explains the types of personal information the service may use '
          'and how that information may be handled.',
    ),
    _LegalSection(
      '2. Information we collect',
      'Depending on the features you use, information may include your name, '
          'email address, phone number, account details, delivery address, '
          'order history, wishlist and customer support messages. Payment '
          'providers may separately process payment details when you pay '
          'for an order.',
    ),
    _LegalSection(
      '3. How information is used',
      'Information may be used to manage your account, process purchases, '
          'arrange deliveries, provide order updates, answer support requests, '
          'prevent fraud and improve the shopping experience. Marketing '
          'communications should be sent only where permitted and where '
          'required consent has been obtained.',
    ),
    _LegalSection(
      '4. Payments and service providers',
      'Payment processors, hosting providers, delivery partners and messaging '
          'services may receive information needed to provide their services. '
          'The final policy should identify the actual providers used by '
          'Sound Mafioso and link to their relevant privacy information.',
    ),
    _LegalSection(
      '5. Data protection and retention',
      'Reasonable technical and organisational measures should be used to '
          'protect personal information. Information should be retained only '
          'for as long as needed for the stated purposes, legal obligations, '
          'dispute resolution or legitimate business requirements. No online '
          'system can guarantee absolute security.',
    ),
    _LegalSection(
      '6. Sharing information',
      'Information may be shared with service providers involved in fulfilling '
          'orders, where you request or authorise sharing, where required by '
          'law, or for other purposes disclosed in the final policy. The '
          'published policy must accurately reflect actual data-sharing '
          'practices.',
    ),
    _LegalSection(
      '7. Your privacy choices',
      'Depending on applicable law, you may be able to request access to, '
          'correction of or deletion of your personal information, or object '
          'to certain uses. You may also be able to update account details '
          'and manage optional analytics preferences. Provide a real contact '
          'address for privacy requests before launch.',
    ),
    _LegalSection(
      '8. Children’s privacy',
      'The service should not knowingly collect children’s personal '
          'information in a manner that violates applicable law. If the app '
          'is intended for children or is likely to be used by them, '
          'appropriate consent and safeguarding requirements must be addressed.',
    ),
    _LegalSection(
      '9. Changes to this policy',
      'This policy may be updated as the service or its data practices change. '
          'The final published version should include an effective date and '
          'explain how material changes will be communicated when required.',
    ),
    _LegalSection(
      '10. Contact information',
      'For questions about privacy, contact [Your registered business name] '
          'at [Your official support email]. Add any required business '
          'address and privacy contact details before publishing this policy.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Privacy Policy',
      subtitle: 'Your information matters. Here is how it may be handled.',
      icon: Icons.shield_outlined,
      sections: sections,
    );
  }
}

// -----------------------------------------------------------------------------
// TERMS AND CONDITIONS
// -----------------------------------------------------------------------------

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const sections = <_LegalSection>[
    _LegalSection(
      '1. Acceptance of terms',
      'These terms describe the proposed rules for accessing and using Mono '
          'Store. Before launch, the final terms should explain how users '
          'accept them and when updates take effect.',
    ),
    _LegalSection(
      '2. Customer accounts',
      'Customers should provide accurate account information and keep their '
          'login credentials secure. Notify the store if you suspect '
          'unauthorised account access. The final terms should explain '
          'account recovery, suspension and closure.',
    ),
    _LegalSection(
      '3. Products and availability',
      'Product descriptions, images, prices and availability should be '
          'presented as accurately as reasonably possible. If a product is '
          'unavailable or a listing contains a material error, the store '
          'should communicate the available options to the customer.',
    ),
    _LegalSection(
      '4. Pricing and payment',
      'The applicable currency, product price, delivery fees and other '
          'charges should be shown before the customer confirms an order. '
          'Available payment methods, payment confirmation and failed '
          'transaction procedures should match the actual checkout process.',
    ),
    _LegalSection(
      '5. Orders and cancellations',
      'Submitting an order requests the purchase of selected products. The '
          'final terms should specify when an order is accepted, how order '
          'confirmation works and how cancellations are handled, subject to '
          'applicable consumer protection law.',
    ),
    _LegalSection(
      '6. Delivery',
      'Delivery options, fees, service areas and estimated delivery times '
          'should be disclosed before checkout where possible. Customers '
          'are responsible for providing an accurate delivery address. '
          'The final terms should cover failed deliveries, delays and '
          'collection arrangements.',
    ),
    _LegalSection(
      '7. Returns and refunds',
      'The store should publish a clear returns and refunds policy covering '
          'eligibility, time limits, product condition, refund methods and '
          'processing times. Nothing in these terms should take away rights '
          'that customers have under applicable law.',
    ),
    _LegalSection(
      '8. Acceptable use',
      'Customers must not use the app for unlawful activity, fraudulent '
          'orders, unauthorised access, interference with the service or '
          'misuse of other customers’ information.',
    ),
    _LegalSection(
      '9. Intellectual property',
      'The Sound Mafioso name, branding, interface and original content may be '
          'protected by intellectual property laws. Users may not copy or '
          'commercially reuse protected materials without permission. '
          'Third-party product names and trademarks remain the property '
          'of their respective owners.',
    ),
    _LegalSection(
      '10. Service availability and liability',
      'The app may occasionally be unavailable due to maintenance or '
          'technical problems. The final terms should explain the store’s '
          'responsibilities and any legally permitted limitations. No '
          'provision should exclude liability where the law prohibits it.',
    ),
    _LegalSection(
      '11. Changes to the terms',
      'Terms may be updated as the app and business evolve. The final '
          'version should explain how changes are published and when '
          'customers may need to accept revised terms.',
    ),
    _LegalSection(
      '12. Governing law and contact',
      'Add the legal business name, business address, governing law, dispute '
          'resolution process and official support contact before launch. '
          'These details should be reviewed for the jurisdiction in which '
          'the business operates and serves customers.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Terms & Conditions',
      subtitle: 'The guidelines for shopping and using Sound Mafioso.',
      icon: Icons.description_outlined,
      sections: sections,
    );
  }
}

// -----------------------------------------------------------------------------
// ABOUT PAGE
// -----------------------------------------------------------------------------

class AboutStoreScreen extends StatelessWidget {
  const AboutStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'About Sound Mafioso',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            height: 90,
            width: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Sound Mafioso',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A simpler way to shop.',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 22),
          const Text(
            'Sound Mafioso is designed to make discovering products, managing '
                'your cart and placing orders simple and convenient. This app '
                'information page can be expanded with your official company '
                'story, website and customer support contacts.',
            style: TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'APPLICATION DETAILS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 15),
                Text('Version                       1.0.0'),
                SizedBox(height: 12),
                Text('Environment              Demo'),
                SizedBox(height: 12),
                Text('Developer                    [Your business name]'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
