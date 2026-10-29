
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'customer_addresses_api.dart';

class SavedAddress {
  const SavedAddress({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    this.isDefault = false,
  });

  final String? id;
  final String name;
  final String phone;
  final String address;
  final String area;
  final bool isDefault;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    final value = json['is_default'];

    return SavedAddress(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      isDefault: value == true ||
          value?.toString() == '1' ||
          value?.toString().toLowerCase() == 'true',
    );
  }
}

final customerAddressesApiProvider =
Provider<CustomerAddressesApi>((ref) {
  return CustomerAddressesApi();
});

final savedAddressesProvider =
FutureProvider.family<List<SavedAddress>, String>(
      (ref, token) async {
    if (token.isEmpty) return const <SavedAddress>[];

    final api = ref.watch(customerAddressesApiProvider);
    final rows = await api.getAddresses(token: token);

    return rows.map(SavedAddress.fromJson).toList();
  },
);
