import 'auth_user.dart';

class Session {
  const Session({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final AuthUser user;
}
