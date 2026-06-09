import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secretKey = 'local_api_signing_secret';
const _iterations = 120000;
const _keyLength = 32;

class LocalTokenClaims {
  const LocalTokenClaims({
    required this.userId,
    required this.email,
    required this.role,
  });

  final int userId;
  final String email;
  final String role;
}

class LocalAuth {
  LocalAuth._(this._secret);

  final String _secret;

  static Future<LocalAuth> create({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) async {
    var secret = await storage.read(key: _secretKey);
    if (secret == null || secret.isEmpty) {
      secret = _randomBase64Url(48);
      await storage.write(key: _secretKey, value: secret);
    }
    return LocalAuth._(secret);
  }

  String hashPassword(String password) {
    final salt = _randomBase64Url(24);
    final hash = _pbkdf2(password, salt, _iterations, _keyLength);
    return 'pbkdf2_sha256:$_iterations:$salt:$hash';
  }

  bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) return false;
    final expected = _pbkdf2(password, parts[2], iterations, _keyLength);
    return _constantTimeEquals(utf8.encode(expected), utf8.encode(parts[3]));
  }

  String signToken({
    required int userId,
    required String email,
    required String role,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final header = _base64UrlJson({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _base64UrlJson({
      'sub': userId,
      'email': email,
      'role': role,
      'iat': now,
      'exp': now + const Duration(hours: 24).inSeconds,
    });
    final signature = _sign('$header.$payload');
    return '$header.$payload.$signature';
  }

  LocalTokenClaims? verifyToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final expected = _sign('${parts[0]}.${parts[1]}');
    if (!_constantTimeEquals(utf8.encode(expected), utf8.encode(parts[2]))) {
      return null;
    }
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    final exp = payload['exp'] as int?;
    if (exp == null || exp <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      return null;
    }
    return LocalTokenClaims(
      userId: payload['sub'] as int,
      email: payload['email'] as String,
      role: payload['role'] as String? ?? 'user',
    );
  }

  String _sign(String data) {
    final hmac = Hmac(sha256, utf8.encode(_secret));
    return base64Url
        .encode(hmac.convert(utf8.encode(data)).bytes)
        .replaceAll('=', '');
  }
}

String _pbkdf2(String password, String salt, int iterations, int length) {
  final passwordBytes = utf8.encode(password);
  final saltBytes = utf8.encode(salt);
  final hLen = 32;
  final blocks = (length / hLen).ceil();
  final output = <int>[];
  for (var block = 1; block <= blocks; block++) {
    final blockSalt = Uint8List(saltBytes.length + 4)
      ..setAll(0, saltBytes)
      ..buffer.asByteData().setUint32(saltBytes.length, block);
    var u = Hmac(sha256, passwordBytes).convert(blockSalt).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = Hmac(sha256, passwordBytes).convert(u).bytes;
      for (var j = 0; j < hLen; j++) {
        t[j] ^= u[j];
      }
    }
    output.addAll(t);
  }
  return base64Url.encode(output.take(length).toList()).replaceAll('=', '');
}

String _base64UrlJson(Map<String, dynamic> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}

String _randomBase64Url(int length) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
