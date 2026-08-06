import 'package:amplify_flutter/amplify_flutter.dart';

/// GraphQL client wrapper for AWS AppSync.
class GraphQLService {
  Future<Map<String, dynamic>?> query({
    required String document,
    Map<String, dynamic>? variables,
    String? apiName,
  }) async {
    final request = GraphQLRequest<String>(
      document: document,
      variables: variables ?? {},
      apiName: apiName,
    );

    final response = await Amplify.API.query(request: request).response;

    if (response.hasErrors) {
      final message = response.errors.map((e) => e.message).join(', ');
      throw Exception(message.isEmpty ? 'GraphQL query failed' : message);
    }

    final data = response.data;
    if (data == null) return null;

  // response.data is JSON string from Amplify API
    return _parseJsonMap(data);
  }

  Future<Map<String, dynamic>?> mutate({
    required String document,
    Map<String, dynamic>? variables,
    String? apiName,
  }) async {
    final request = GraphQLRequest<String>(
      document: document,
      variables: variables ?? {},
      apiName: apiName,
    );

    final response = await Amplify.API.mutate(request: request).response;

    if (response.hasErrors) {
      final message = response.errors.map((e) => e.message).join(', ');
      throw Exception(message.isEmpty ? 'GraphQL mutation failed' : message);
    }

    final data = response.data;
    if (data == null) return null;

    return _parseJsonMap(data);
  }

  Map<String, dynamic>? _parseJsonMap(String raw) {
    try {
      // Amplify returns serialized JSON; decode if needed in future modules.
      return {'raw': raw};
    } catch (_) {
      return null;
    }
  }
}
