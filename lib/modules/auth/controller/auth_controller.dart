import 'package:flutter/foundation.dart';

import '../../../core/services/amplify_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../model/user_model.dart';
import '../service/cognito_auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required CognitoAuthService authService,
    required LocalStorageService storageService,
    required AmplifyService amplifyService,
  })  : _authService = authService,
        _storageService = storageService,
        _amplifyService = amplifyService;

  final CognitoAuthService _authService;
  final LocalStorageService _storageService;
  final AmplifyService _amplifyService;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isOnboardingCompleted => _storageService.isOnboardingCompleted;

  Future<void> initialize() async {
    await _amplifyService.configure();
    _user = await _authService.getCurrentUser();
    _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _storageService.setOnboardingCompleted(value: true);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
