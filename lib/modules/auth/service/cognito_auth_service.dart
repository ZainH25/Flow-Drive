import 'package:amplify_flutter/amplify_flutter.dart';

import '../../../core/config/aws_config.dart';
import '../../../core/services/amplify_service.dart';
import '../model/user_model.dart';

class CognitoAuthService {
  CognitoAuthService(this._amplifyService);

  final AmplifyService _amplifyService;

  bool get isAmplifyReady =>
      AwsConfig.isConfigured && _amplifyService.isConfigured;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (!isAmplifyReady) {
      throw Exception('AWS Cognito is not configured yet.');
    }

    final result = await Amplify.Auth.signIn(
      username: email.trim(),
      password: password,
    );

    if (!result.isSignedIn) {
      throw Exception('Sign in requires additional steps.');
    }

    return _fetchCurrentUser();
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!isAmplifyReady) {
      throw Exception('AWS Cognito is not configured yet.');
    }

    final result = await Amplify.Auth.signUp(
      username: email.trim(),
      password: password,
      options: SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email.trim(),
          AuthUserAttributeKey.name: displayName.trim(),
        },
      ),
    );

    if (!result.isSignUpComplete) {
      throw Exception('Sign up requires email verification.');
    }

    final signInResult = await Amplify.Auth.signIn(
      username: email.trim(),
      password: password,
    );

    if (!signInResult.isSignedIn) {
      throw Exception('Account created. Please sign in.');
    }

    return _fetchCurrentUser();
  }

  Future<UserModel> _fetchCurrentUser() async {
    final session = await Amplify.Auth.fetchAuthSession();
    if (!session.isSignedIn) {
      throw Exception('No active session.');
    }

    final user = await Amplify.Auth.getCurrentUser();
    final attributes = await Amplify.Auth.fetchUserAttributes();

    final email = attributes
            .where((a) => a.userAttributeKey == AuthUserAttributeKey.email)
            .map((a) => a.value)
            .firstOrNull ??
        user.username;

    final emailVerified = attributes
        .where((a) => a.userAttributeKey == AuthUserAttributeKey.emailVerified)
        .map((a) => a.value == 'true')
        .firstOrNull;

    return UserModel.fromCognitoAttributes(
      userId: user.userId,
      email: email,
      username: user.username,
      isEmailVerified: emailVerified ?? false,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    if (!isAmplifyReady) return null;

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) return null;
      return _fetchCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    if (!isAmplifyReady) return;
    await Amplify.Auth.signOut();
  }
}
