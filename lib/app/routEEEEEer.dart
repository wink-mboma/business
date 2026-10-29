import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shared/app_shell.dart';
import '../features/wishlist/wishlist_screen.dart';
import '../features/orders/orders_screens.dart';
import '../features/account/account_screens.dart';
import '../features/chat/chat_screens.dart';
import '../features/shared/startup_screens.dart';

final appRouter = GoRouter(initialLocation: '/startup', routes: [
  GoRoute(path: '/startup', builder: (context, state) => const SplashScreen()),
  GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
  ShellRoute(
    builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
      GoRoute(path: '/chat/product/:productId', builder: (context, state) => ChatProductStartScreen(productId: state.pathParameters['productId']!, product: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : const {})),
      GoRoute(path: '/chat/:id', builder: (context, state) => ChatThreadScreen(chatId: state.pathParameters['id']!)),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
        ],
  ),
  GoRoute(path: '/account/addresses', builder: (context, state) => const SavedAddressesScreen()),
  GoRoute(path: '/account/notifications', builder: (context, state) => const AccountNotificationsScreen()),
  GoRoute(path: '/account/settings', builder: (context, state) => const AccountSettingsScreen()),
  GoRoute(path: '/orders', builder: (context, state) => const Scaffold(body: SafeArea(child: OrdersScreen()))),
  GoRoute(path: '/orders/:id', builder: (context, state) => OrderDetailsScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/checkout', builder: (context, state) => const Scaffold(body: SafeArea(child: CheckoutScreen())),),
  GoRoute(path: '/payment-status', builder: (context, state) => Scaffold(body: SafeArea(child: PaymentStatusScreen(data: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : const {})))),
  GoRoute(path: '/order-confirmation', builder: (context, state) => Scaffold(body: SafeArea(child: OrderConfirmationScreen(data: state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : const {})))),
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
  GoRoute(path: '/verify-otp', builder: (context, state) => OtpScreen(details: state.extra is Map<String, String> ? state.extra as Map<String, String> : null)),
  GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
  GoRoute(path: '/product/:id', builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
]);
