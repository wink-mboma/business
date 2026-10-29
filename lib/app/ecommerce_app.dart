import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart_screen.dart';
import '../features/auth/auth_state.dart';
import '../features/products/product_state.dart';
import '../features/home/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/shared/app_shell.dart';
import '../features/shared/not_implemented_screen.dart';
import '../features/wishlist/wishlist_screen.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';

class EcommerceApp extends ConsumerWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isSignedIn && next.token.isNotEmpty && previous?.token != next.token) {
        unawaited(ref.read(storeProvider.notifier).connectAccount(next.token));
      } else if (!next.isSignedIn && previous?.isSignedIn == true) {
        unawaited(ref.read(storeProvider.notifier).disconnectAccount());
      }
    });
    return MaterialApp.router(
      title: 'Mono Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
