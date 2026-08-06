import 'package:flutter/material.dart';

import 'auth_controller.dart';

class LoginController {
  LoginController(this._authController);

  final AuthController _authController;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  AuthController get authController => _authController;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  Future<bool> submitLogin(VoidCallback onStateChanged) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    isLoading = true;
    onStateChanged();

    final success = await _authController.signIn(
      emailController.text,
      passwordController.text,
    );

    isLoading = false;
    onStateChanged();
    return success;
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
