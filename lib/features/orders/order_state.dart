import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../products/product_state.dart';
import 'orders_api.dart';

class OrderItemSnapshot {
  const OrderItemSnapshot({required this.productId, required this.name, required this.imageUrl, required this.unitPrice, required this.quantity, this.size, this.color});
  final String productId, name, imageUrl;
  final double unitPrice;
  final int quantity;
  final String? size, color;
  double get total => unitPrice * quantity;

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) => OrderItemSnapshot(
    productId: (json['product_id'] ?? '').toString(),
    name: (json['name'] ?? 'Product').toString(),
    imageUrl: (json['image_url'] ?? '').toString(),
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    size: json['size']?.toString(),
    color: json['color']?.toString(),
  );
}

class StoreOrder {
  const StoreOrder({required this.id, this.databaseId = '', required this.createdAt, required this.items, required this.subtotal, required this.delivery, required this.total, required this.paymentMethod, required this.paymentStatus, required this.status, required this.address, this.trackingCode, this.history = const []});
  /// Public order number shown to customers and used for detail lookup.
  final String id;
  final String databaseId;
  final DateTime createdAt;
  final List<OrderItemSnapshot> items;
  final double subtotal, delivery, total;
  final String paymentMethod, paymentStatus, status, address;
  final String? trackingCode;
  final List<Map<String, dynamic>> history;

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((item) => OrderItemSnapshot.fromJson(Map<String, dynamic>.from(item))).toList(growable: false)
        : <OrderItemSnapshot>[];
    final rawHistory = json['history'];
    final history = rawHistory is List
        ? rawHistory.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false)
        : <Map<String, dynamic>>[];
    return StoreOrder(
      id: (json['order_number'] ?? json['id'] ?? '').toString(),
      databaseId: (json['order_id'] ?? json['id'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? items.fold<double>(0, (sum, item) => sum + item.total),
      delivery: (json['delivery'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['payment_method'] ?? 'PayChangu').toString(),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      status: (json['status'] ?? json['order_status'] ?? 'pending').toString(),
      address: (json['address'] ?? '').toString(),
      trackingCode: json['tracking_code']?.toString(),
      history: history,
    );
  }
}

class OrdersController extends StateNotifier<List<StoreOrder>> {
  OrdersController() : super(const []);
  final OrdersApi _api = OrdersApi();
  String? _loadedToken;
  bool _hasLoaded = false;
  Future<void>? _loading;

  Future<void> load(String token, {bool force = false}) async {
    if (token.trim().isEmpty) {
      state = const [];
      return;
    }

    if (!force && _loadedToken == token && _hasLoaded) {
      return;
    }

    if (_loading != null) {
      return _loading!;
    }

    _loading = _fetchOrders(token);

    try {
      await _loading;
    } finally {
      _loading = null;
    }
  }

  Future<void> _fetchOrders(String token) async {
    final orders = await _api.list(token: token);

    state = orders;
    _loadedToken = token;
    _hasLoaded = true;
  }
 /* Future<void> load(String token, {bool force = false}) async {
    if (token.isEmpty) return;
    if (!force && _loadedToken == token && _hasLoaded) return;
    if (_loading != null) return _loading;
    _loading = () async {
      try {
        final orders = await _api.list(token: token);
        state = orders;
        _loadedToken = token;
        _hasLoaded = true;
      } finally {
        _loading = null;
      }
    }();
    return _loading;
  }*/

  Future<StoreOrder> refreshDetail(String token, String id) async {
    final order = await _api.detail(token: token, id: id);
    state = [order, ...state.where((item) => item.id != order.id)];
    _loadedToken = token;
    _hasLoaded = true;
    return order;
  }

  StoreOrder createDemoOrder({required List<CartLine> cart, required double total, required double delivery, required String method, required String address}) {
    final now = DateTime.now();
    final id = 'MS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    final items = cart.map((line) => OrderItemSnapshot(productId: line.product.id, name: line.product.name, imageUrl: line.product.imageUrl, unitPrice: line.product.price, quantity: line.quantity, size: line.size, color: line.color)).toList(growable: false);
    final order = StoreOrder(id: id, createdAt: now, items: items, subtotal: items.fold<double>(0, (sum, item) => sum + item.total), delivery: delivery, total: total, paymentMethod: method, paymentStatus: 'Pending', status: 'Processing', address: address);
    state = [order, ...state];
    return order;
  }
}
final ordersProvider = StateNotifierProvider<OrdersController, List<StoreOrder>>((ref) => OrdersController());
final ordersLoadingProvider = StateProvider<bool>((ref) => false);
final ordersErrorProvider = StateProvider<String?>((ref) => null);

final ordersRequestedTokenProvider = StateProvider<String?>((ref) => null);
