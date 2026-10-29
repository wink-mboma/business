
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_api.dart';

class AuthState {
  const AuthState({
    this.isSignedIn = false,
    this.email = '',
    this.displayName = '',
    this.customerId = '',
    this.phone = '',
    this.address = '',
    this.token = '',
    this.profileImageUrl,
    this.isLoading = true,
  });

  final bool isSignedIn;
  final String email;
  final String displayName;
  final String customerId;
  final String phone;
  final String address;
  final String token;
  final String? profileImageUrl;
  final bool isLoading;

  AuthState copyWith({
    bool? isSignedIn,
    String? email,
    String? displayName,
    String? customerId,
    String? phone,
    String? address,
    String? token,
    String? profileImageUrl,
    bool clearProfileImageUrl = false,
    bool? isLoading,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      customerId: customerId ?? this.customerId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      token: token ?? this.token,
      profileImageUrl: clearProfileImageUrl
          ? null
          : profileImageUrl ?? this.profileImageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    unawaited(_restore());
  }

  final AuthApi _api = AuthApi();

  Future<void> _restore() async {
    try {
      final token = await _api.savedToken();

      if (token != null && token.isNotEmpty) {
        final customer = await _api.me(token);

        state = AuthState(
          isSignedIn: true,
          email: customer.email,
          displayName: customer.name,
          customerId: customer.id,
          phone: customer.phone,
          address: customer.address ?? '',
          token: token,
          profileImageUrl: customer.profileImageUrl,
          isLoading: false,
        );
        return;
      }
    } catch (_) {
      await _api.clearToken();
    }

    state = state.copyWith(isLoading: false);
  }

  Future<AuthState> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _api.login(email, password);
      return _set(result);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<AuthState> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return _set(result);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  AuthState _set(AuthResult result) {
    final customer = result.customer;

    state = AuthState(
      isSignedIn: true,
      email: customer.email,
      displayName: customer.name,
      customerId: customer.id,
      phone: customer.phone,
      address: customer.address ?? '',
      token: result.token,
      profileImageUrl: customer.profileImageUrl,
      isLoading: false,
    );

    return state;
  }

  /// Uploads the selected profile photo and updates the signed-in state.
  Future<void> updateProfileImage(
      String fileName,
      List<int> bytes,
      ) async {
    if (!state.isSignedIn || state.token.isEmpty) {
      throw Exception('Please sign in before uploading a profile photo.');
    }

    final customer = await _api.uploadProfileImage(
      state.token,
      fileName,
      bytes,
    );

    state = state.copyWith(
      displayName: customer.name,
      email: customer.email,
      phone: customer.phone,
      address: customer.address ?? '',
      profileImageUrl: customer.profileImageUrl,
    );
  }

  /// Updates profile details in the current app state.
  /// Server-side persistence requires a compatible profile API endpoint.
  void updateProfile({
    required String displayName,
    required String email,
  }) {
    state = state.copyWith(
      displayName: displayName.trim(),
      email: email.trim(),
    );
  }

  Future<void> signOut() async {
    final token = state.token;
    state = const AuthState(isLoading: false);
    await _api.logout(token);
  }
}

final authProvider =
StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(),
);
