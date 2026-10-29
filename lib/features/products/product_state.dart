import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product.dart';
import '../../core/network/catalog_api.dart';
import '../auth/customer_sync_api.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.variantId,
    this.size,
    this.color,
  });

  final Product product;
  final int quantity;
  final String? variantId;
  final String? size;
  final String? color;

  String get lineId => '${product.id}::${variantId ?? 'default'}';

  ProductVariant? get variant {
    for (final item in product.variants) {
      if (item.id == variantId) return item;
    }
    return null;
  }

  double get unitPrice => variant?.price ?? product.price;
  int get availableStock => variant?.stock ?? product.stockQuantity;

  CartLine copyWith({int? quantity}) => CartLine(
        product: product,
        quantity: quantity ?? this.quantity,
        variantId: variantId,
        size: size,
        color: color,
      );

  Map<String, dynamic> toJson() => {
    'product': product.toJson(), 'quantity': quantity,
    'variant_id': variantId, 'size': size, 'color': color,
  };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
    product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    variantId: json['variant_id']?.toString(),
    size: json['size']?.toString(), color: json['color']?.toString(),
  );
}

class StoreState {
  const StoreState({this.wishlistIds = const {}, this.cart = const {}});
  final Set<String> wishlistIds;
  final Map<String, CartLine> cart;

  int get cartItemCount => cart.values.fold(0, (sum, line) => sum + line.quantity);
  double get cartSubtotal => cart.values.fold(0, (sum, line) => sum + line.unitPrice * line.quantity);

  StoreState copyWith({Set<String>? wishlistIds, Map<String, CartLine>? cart}) => StoreState(
    wishlistIds: wishlistIds ?? this.wishlistIds,
    cart: cart ?? this.cart,
  );
}

/// Local-first store state: guest data persists locally, then merges into the
/// authenticated customer account and synchronizes after cart/wishlist changes.
class StoreController extends StateNotifier<StoreState> {
  StoreController() : super(const StoreState()) { unawaited(_restore()); }

  static const _cartKey = 'mono_store_guest_cart_v1';
  static const _wishlistKey = 'mono_store_wishlist_ids_v1';
  bool _restored = false;
  String? _accountToken;
  bool _syncingRemote = false;
  bool _syncQueued = false;
  final CustomerSyncApi _syncApi = CustomerSyncApi();
  final CatalogApi _catalogApi = CatalogApi();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCart = prefs.getString(_cartKey);
      final savedWishlist = prefs.getStringList(_wishlistKey) ?? const <String>[];
      final restoredCart = <String, CartLine>{};
      if (savedCart != null) {
        final decoded = jsonDecode(savedCart);
        if (decoded is List) {
          for (final raw in decoded) {
            if (raw is Map) {
              final line = CartLine.fromJson(Map<String, dynamic>.from(raw));
              if (line.quantity > 0 && line.availableStock > 0) {
                restoredCart[line.lineId] = line.copyWith(quantity: line.quantity.clamp(1, line.availableStock).toInt());
              }
            }
          }
        }
      }
      // Preserve any changes made before preferences finished loading.
      final mergedCart = {...restoredCart, ...state.cart};
      final mergedWishlist = {...savedWishlist, ...state.wishlistIds};
      state = state.copyWith(cart: mergedCart, wishlistIds: mergedWishlist);
    } catch (_) {
      // Corrupt or unavailable local storage should not prevent shopping.
    } finally {
      _restored = true;
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, jsonEncode(state.cart.values.map((line) => line.toJson()).toList()));
      await prefs.setStringList(_wishlistKey, state.wishlistIds.toList());
      if (_accountToken != null && _accountToken!.isNotEmpty) unawaited(_pushRemote());
    } catch (_) {
      // The in-memory cart remains usable if storage is blocked/unavailable.
    }
  }

  Future<void> connectAccount(String token) async {
    await waitUntilRestored();
    _accountToken = token;
    try {
      final remote = await _syncApi.fetch(token);
      final mergedWishlist = {...state.wishlistIds, ...((remote['wishlist'] as List? ?? const []).map((e) => e.toString()))};
      final mergedCart = {...state.cart};
      for (final raw in (remote['cart'] as List? ?? const [])) {
        if (raw is! Map) continue;
        final row = Map<String,dynamic>.from(raw);
        final pid = row['product_id']?.toString() ?? '';
        if (pid.isEmpty) continue;
        try {
          final product = await _catalogApi.productById(pid);
          final size = row['size_value']?.toString();
          final color = row['color_value']?.toString();
          ProductVariant? variant;
          for (final v in product.variants) { if ((size == null || size.isEmpty || v.size == size) && (color == null || color.isEmpty || v.color == color)) { variant = v; break; } }
          final lineId = '${product.id}::${variant?.id ?? 'default'}';
          final incoming = (row['quantity'] as num?)?.toInt() ?? 1;
          final existing = mergedCart[lineId];
          final maxStock = variant?.stock ?? product.stockQuantity;
          if (maxStock > 0) {
            final qty = ((existing?.quantity ?? 0) + incoming).clamp(1,maxStock).toInt();
            mergedCart[lineId] = CartLine(product:product,quantity:qty,variantId:variant?.id,size:size,color:color);
          }
        } catch (_) {}
      }
      state = state.copyWith(cart:mergedCart,wishlistIds:mergedWishlist);
      await _persist();
    } catch (_) {
      // Keep local shopping usable if account sync is temporarily unavailable.
    }
  }

  Future<void> disconnectAccount() async { _accountToken = null; }

  Future<void> _pushRemote() async {
    if (_accountToken == null || _accountToken!.isEmpty) return;
    if (_syncingRemote) { _syncQueued = true; return; }
    _syncingRemote = true;
    try {
      await _syncApi.save(_accountToken!, cart:state.cart.values.map((line) => {
        'product_id':line.product.id, 'variant_key':line.variantId ?? 'default',
        'size':line.size, 'color':line.color, 'quantity':line.quantity,
      }).toList(), wishlist:state.wishlistIds.toList());
    } catch (_) { /* Local data remains available; next change/re-login retries sync. */ }
    finally { _syncingRemote = false; if (_syncQueued) { _syncQueued=false; unawaited(_pushRemote()); } }
  }

  void toggleWishlist(String id) {
    final updated = {...state.wishlistIds};
    if (!updated.add(id)) updated.remove(id);
    state = state.copyWith(wishlistIds: updated);
    unawaited(_persist());
  }

  void addToCart(Product product, {int quantity = 1, ProductVariant? variant}) {
    final updated = {...state.cart};
    final lineId = '${product.id}::${variant?.id ?? 'default'}';
    final existing = updated[lineId];
    final maxStock = variant?.stock ?? product.stockQuantity;
    if (maxStock <= 0) return;
    final nextQuantity = ((existing?.quantity ?? 0) + quantity).clamp(1, maxStock).toInt();
    updated[lineId] = CartLine(
      product: product, quantity: nextQuantity, variantId: variant?.id,
      size: variant?.size, color: variant?.color,
    );
    state = state.copyWith(cart: updated);
    unawaited(_persist());
  }

  void changeQuantity(String lineId, int quantity) {
    final updated = {...state.cart};
    if (quantity <= 0) {
      updated.remove(lineId);
    } else {
      final existing = updated[lineId];
      if (existing != null) {
        final maxStock = existing.availableStock;
        if (maxStock <= 0) {
          updated.remove(lineId);
        } else {
          updated[lineId] = existing.copyWith(quantity: quantity.clamp(1, maxStock).toInt());
        }
      }
    }
    state = state.copyWith(cart: updated);
    unawaited(_persist());
  }

  void removeFromCart(String lineId) {
    final updated = {...state.cart}..remove(lineId);
    state = state.copyWith(cart: updated);
    unawaited(_persist());
  }

  void clearCart() {
    state = state.copyWith(cart: {});
    unawaited(_persist());
  }

  Future<void> waitUntilRestored() async {
    while (!_restored) { await Future<void>.delayed(const Duration(milliseconds: 10)); }
  }
}

final storeProvider = StateNotifierProvider<StoreController, StoreState>((ref) => StoreController());
