import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_api.dart';

class AuthState {
  const AuthState({this.isSignedIn = false, this.email = '', this.displayName = '', this.customerId = '', this.phone = '', this.token = '', this.profileImageUrl = '', this.isLoading = true});
  final bool isSignedIn;
  final String email, displayName, customerId, phone, token, profileImageUrl;
  final bool isLoading;
  AuthState copyWith({bool? isSignedIn, String? email, String? displayName, String? customerId, String? phone, String? token, String? profileImageUrl, bool? isLoading}) => AuthState(
    isSignedIn:isSignedIn??this.isSignedIn,email:email??this.email,displayName:displayName??this.displayName,
    customerId:customerId??this.customerId,phone:phone??this.phone,token:token??this.token,profileImageUrl:profileImageUrl??this.profileImageUrl,isLoading:isLoading??this.isLoading);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) { unawaited(_restore()); }
  final AuthApi _api = AuthApi();

  Future<void> _restore() async {
    try {
      final token = await _api.savedToken();
      if (token != null && token.isNotEmpty) {
        final customer = await _api.me(token);
        state = AuthState(isSignedIn:true,email:customer.email,displayName:customer.name,customerId:customer.id,phone:customer.phone,token:token,profileImageUrl:customer.profileImageUrl??'',isLoading:false);
        return;
      }
    } catch (_) { await _api.clearToken(); }
    state = state.copyWith(isLoading:false);
  }

  Future<AuthState> login({required String email, required String password}) async {
    state = state.copyWith(isLoading:true);
    try { final result = await _api.login(email,password); return _set(result); }
    finally { state = state.copyWith(isLoading:false); }
  }
  Future<AuthState> register({required String name, required String email, required String phone, required String password}) async {
    state = state.copyWith(isLoading:true);
    try { final result = await _api.register(name:name,email:email,phone:phone,password:password); return _set(result); }
    finally { state = state.copyWith(isLoading:false); }
  }
  AuthState _set(AuthResult result) {
    state = AuthState(isSignedIn:true,email:result.customer.email,displayName:result.customer.name,customerId:result.customer.id,phone:result.customer.phone,token:result.token,profileImageUrl:result.customer.profileImageUrl??'',isLoading:false);
    return state;
  }
  /// Updates profile details in the current app state.
  /// Server-side persistence requires an authenticated profile API endpoint.
  Future<void> updateProfileImage(String fileName, List<int> bytes) async {
    final updated = await _api.uploadProfileImage(state.token, fileName, bytes);
    state = state.copyWith(profileImageUrl: updated.profileImageUrl ?? '');
  }

  void updateProfile({required String displayName, required String email}) {
    state = state.copyWith(displayName: displayName.trim(), email: email.trim());
  }

  Future<void> signOut() async { final token=state.token; state=const AuthState(isLoading:false); await _api.logout(token); }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
