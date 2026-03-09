class AuthUser {
  const AuthUser({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;

  bool matchesIdentifier(String identifier) {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    return username.toLowerCase() == normalizedIdentifier ||
        email.toLowerCase() == normalizedIdentifier;
  }
}
