import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const String _defaultSalt = "bharat_ledger_industrial_salt_2026";

  /// Hashes a plain password using SHA-256 with an optional salt.
  /// Returns a string formatted as "salt$hashedHex".
  static String hashPassword(String password, {String? salt}) {
    final effectiveSalt = salt ?? _defaultSalt;
    final bytes = utf8.encode("$effectiveSalt::$password");
    final digest = sha256.convert(bytes);
    return "$effectiveSalt\$$digest";
  }

  /// Verifies a plain password against a stored hashed string.
  /// Handles both salted format ("salt$hash") and direct SHA-256 hashes.
  static bool verifyPassword(String password, String storedHash) {
    if (storedHash.isEmpty) return false;

    if (storedHash.contains('\$')) {
      final parts = storedHash.split('\$');
      final salt = parts[0];
      final expectedDigest = parts[1];
      final bytes = utf8.encode("$salt::$password");
      final computedDigest = sha256.convert(bytes).toString();
      return computedDigest == expectedDigest;
    } else {
      // Direct comparison or unsalted hash fallback
      final computed = sha256.convert(utf8.encode(password)).toString();
      return computed == storedHash || password == storedHash;
    }
  }
}
