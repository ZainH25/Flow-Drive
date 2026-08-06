import 'package:get/get.dart';

import '../../../core/config/aws_config.dart';
import '../../../core/config/dev_credentials.dart';
import '../../../core/services/amplify_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../model/user_model.dart';
import '../service/cognito_auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthController extends GetxController {
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

  final status = AuthStatus.unknown.obs;
  final user = Rxn<UserModel>();
  final errorMessage = RxnString();

  bool get isAuthenticated => status.value == AuthStatus.authenticated;
  bool get isOnboardingCompleted => _storageService.isOnboardingCompleted;

  Future<void> initialize() async {
    await _amplifyService.configure();
    user.value = _restoreDevSession() ?? await _authService.getCurrentUser();
    status.value =
        user.value != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    errorMessage.value = null;

    if (canUseDevLogin) {
      final normalizedEmail = email.trim().toLowerCase();
      user.value = UserModel(
        id: 'dev-${normalizedEmail.hashCode}',
        email: normalizedEmail,
        username: displayName,
        isEmailVerified: true,
      );
      status.value = AuthStatus.authenticated;
      await _storageService.setDevUserEmail(normalizedEmail);
      return true;
    }

    try {
      user.value = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      status.value = AuthStatus.authenticated;
      return true;
    } on Exception catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      status.value = AuthStatus.unauthenticated;
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    errorMessage.value = null;

    final devAccount = _tryDevSignIn(email, password);
    if (devAccount != null) {
      user.value = devAccount;
      status.value = AuthStatus.authenticated;
      await _storageService.setDevUserEmail(devAccount.email);
      return true;
    }

    try {
      user.value = await _authService.signIn(email: email, password: password);
      status.value = AuthStatus.authenticated;
      return true;
    } on Exception catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      status.value = AuthStatus.unauthenticated;
      return false;
    }
  }

  Future<void> signOut() async {
    await _storageService.clearDevUserEmail();
    await _authService.signOut();
    user.value = null;
    status.value = AuthStatus.unauthenticated;
    errorMessage.value = null;
  }

  UserModel? _restoreDevSession() {
    final email = _storageService.devUserEmail;
    if (email == null) return null;

    final account = DevCredentials.findByEmail(email);
    if (account == null) return null;

    return UserModel(
      id: account.id,
      email: account.email,
      username: account.displayName,
      isEmailVerified: true,
    );
  }

  UserModel? _tryDevSignIn(String email, String password) {
    if (!DevCredentials.matches(email, password)) return null;

    final account = DevCredentials.findByEmail(email)!;
    return UserModel(
      id: account.id,
      email: account.email,
      username: account.displayName,
      isEmailVerified: true,
    );
  }

  bool get canUseDevLogin => !AwsConfig.isConfigured;

  Future<void> completeOnboarding() async {
    await _storageService.setOnboardingCompleted(value: true);
  }

  void clearError() => errorMessage.value = null;
}
