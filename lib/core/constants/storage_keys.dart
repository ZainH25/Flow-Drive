class StorageKeys {
  StorageKeys._();

  /// Set to true after the user completes post-login onboarding (never shown again).
  static const String onboardingCompleted = 'onboarding_completed';

  /// Email of the signed-in dev user (local testing only).
  static const String devUserEmail = 'dev_user_email';

  static const String rememberMe = 'remember_me';
  static const String rememberedEmail = 'remembered_email';
}
