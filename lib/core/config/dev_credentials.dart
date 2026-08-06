/// Hardcoded dev accounts for local testing (no AWS Cognito required).
class DevCredentials {
  DevCredentials._();

  /// Shared password for all dev accounts.
  static const String password = 'Password123';

  static const List<DevAccount> accounts = [
    DevAccount(
      email: 'zain@gmail.com',
      displayName: 'Zain',
      id: 'dev-zain',
    ),
    DevAccount(
      email: 'thomas@gmail.com',
      displayName: 'Thomas',
      id: 'dev-thomas',
    ),
    DevAccount(
      email: 'vishank@gmail.com',
      displayName: 'Vishank',
      id: 'dev-vishank',
    ),
  ];

  static DevAccount? findByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final account in accounts) {
      if (account.email.toLowerCase() == normalized) {
        return account;
      }
    }
    return null;
  }

  static bool matches(String email, String password) {
    return password == DevCredentials.password && findByEmail(email) != null;
  }
}

class DevAccount {
  const DevAccount({
    required this.email,
    required this.displayName,
    required this.id,
  });

  final String email;
  final String displayName;
  final String id;
}
