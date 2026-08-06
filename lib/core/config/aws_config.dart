/// AWS configuration for Cognito and AppSync GraphQL.
///
/// Replace placeholder values with your AWS resources, or run:
/// `amplify init` → `amplify add auth` → `amplify add api` → `amplify push`
/// and use the generated [amplifyconfiguration.dart].
class AwsConfig {
  AwsConfig._();

  /// Set to true once Amplify is configured with real credentials.
  static const bool isConfigured = false;

  static const String region = 'us-east-1';

  // Cognito User Pool
  static const String userPoolId = 'YOUR_USER_POOL_ID';
  static const String userPoolWebClientId = 'YOUR_APP_CLIENT_ID';

  // AppSync GraphQL API
  static const String graphQLEndpoint = 'https://YOUR_API_ID.appsync-api.us-east-1.amazonaws.com/graphql';
  static const String graphQLApiKey = 'YOUR_API_KEY'; // optional if using Cognito auth

  /// Minimal Amplify config JSON — replace with amplifyconfiguration.dart output.
  static const String amplifyConfig = '''
{
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/2.0",
        "Version": "1.0",
        "CognitoUserPool": {
          "Default": {
            "PoolId": "$userPoolId",
            "AppClientId": "$userPoolWebClientId",
            "Region": "$region"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH"
          }
        }
      }
    }
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "flowdrive": {
          "endpointType": "GraphQL",
          "endpoint": "$graphQLEndpoint",
          "region": "$region",
          "authorizationType": "AMAZON_COGNITO_USER_POOLS"
        }
      }
    }
  }
}
''';
}
