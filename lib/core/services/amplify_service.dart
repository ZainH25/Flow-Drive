import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../config/aws_config.dart';

class AmplifyService {
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  Future<void> configure() async {
    if (_isConfigured || !AwsConfig.isConfigured) {
      return;
    }

    try {
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
      ]);

      await Amplify.configure(AwsConfig.amplifyConfig);
      _isConfigured = true;
      safePrint('Amplify configured successfully');
    } on AmplifyAlreadyConfiguredException {
      _isConfigured = true;
    } on Exception catch (e) {
      safePrint('Amplify configuration failed: $e');
      rethrow;
    }
  }
}
