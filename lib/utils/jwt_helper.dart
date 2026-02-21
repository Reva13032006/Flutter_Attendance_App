import 'package:jwt_decoder/jwt_decoder.dart';

class JwtHelper {
  static Map<String, dynamic> decode(String token) {
    return JwtDecoder.decode(token);
  }

  static String getEmail(String token) {
    return decode(token)["sub"];
  }

  static String getRole(String token) {
    return decode(token)["role"];
  }

  static bool isExpired(String token) {
    return JwtDecoder.isExpired(token);
  }
}
