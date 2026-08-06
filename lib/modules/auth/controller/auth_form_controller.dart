import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/local_storage_service.dart';
import 'auth_controller.dart';

enum AuthFormMode { signIn, signUp }

class AuthFormController extends GetxController {
  AuthFormController(this._authController, this._storage);

  final AuthController _authController;
  final LocalStorageService _storage;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final mode = AuthFormMode.signIn.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;

  bool get isSignIn => mode.value == AuthFormMode.signIn;
  bool get isSignUp => mode.value == AuthFormMode.signUp;

  @override
  void onInit() {
    super.onInit();
    rememberMe.value = _storage.rememberMe;
    final email = _storage.rememberedEmail;
    if (rememberMe.value && email != null) {
      emailController.text = email;
    }
  }

  void setMode(AuthFormMode newMode) {
    if (mode.value == newMode) return;
    mode.value = newMode;
    _authController.clearError();
  }

  void togglePasswordVisibility() => obscurePassword.toggle();

  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.toggle();

  Future<bool> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isLoading.value = true;

    final success = isSignIn
        ? await _authController.signIn(
            emailController.text,
            passwordController.text,
          )
        : await _authController.signUp(
            email: emailController.text,
            password: passwordController.text,
            displayName: nameController.text.trim(),
          );

    if (success && isSignIn) {
      await _storage.setRememberMe(rememberMe.value);
      if (rememberMe.value) {
        await _storage.setRememberedEmail(emailController.text.trim());
      } else {
        await _storage.clearRememberedEmail();
      }
    }

    isLoading.value = false;
    return success;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
