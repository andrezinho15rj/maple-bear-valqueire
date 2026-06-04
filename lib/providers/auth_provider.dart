import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/usuario.dart';
import '../services/sponte_api_service.dart';
import '../config/constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SponteApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.initial;
  Usuario? _usuario;
  String? _erro;

  AuthProvider(this._api) {
    _checkAuth();
  }

  AuthStatus get status => _status;
  Usuario? get usuario => _usuario;
  String? get erro => _erro;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: AppConstants.sponteTokenKey);
    final userData = await _storage.read(key: AppConstants.userKey);

    if (token != null && userData != null) {
      try {
        _usuario = Usuario.fromJson(json.decode(userData));
        _status = AuthStatus.authenticated;
        notifyListeners();
        // Refresh user data in background
        _refreshUser();
      } catch (_) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _refreshUser() async {
    try {
      _usuario = await _api.getPerfil();
      await _storage.write(
          key: AppConstants.userKey, value: json.encode(_usuario!.toJson()));
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> login(String email, String senha) async {
    _status = AuthStatus.loading;
    _erro = null;
    notifyListeners();

    try {
      final data = await _api.login(email, senha);
      if (data['usuario'] != null) {
        _usuario = Usuario.fromJson(data['usuario']);
        await _storage.write(
            key: AppConstants.userKey,
            value: json.encode(_usuario!.toJson()));
      } else {
        _usuario = await _api.getPerfil();
        await _storage.write(
            key: AppConstants.userKey,
            value: json.encode(_usuario!.toJson()));
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _erro = _parseError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.delete(key: AppConstants.userKey);
      _usuario = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('401')) return 'Email ou senha incorretos.';
    if (e.toString().contains('SocketException')) {
      return 'Sem conexão com a internet.';
    }
    return 'Erro ao fazer login. Tente novamente.';
  }
}
