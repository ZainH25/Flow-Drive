class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.username,
    this.isEmailVerified = false,
  });

  final String id;
  final String email;
  final String? username;
  final bool isEmailVerified;

  factory UserModel.fromCognitoAttributes({
    required String userId,
    required String email,
    String? username,
    bool isEmailVerified = false,
  }) {
    return UserModel(
      id: userId,
      email: email,
      username: username,
      isEmailVerified: isEmailVerified,
    );
  }
}
