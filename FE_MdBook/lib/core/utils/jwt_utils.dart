import 'dart:convert';

/// Decode JWT token without verifying signature (verification is done server-side).
/// Returns the `sub` claim which is the Keycloak user ID used by the chat service.
String? getSubFromJwt(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    // JWT payload is base64url encoded
    String payload = parts[1];
    // Pad to multiple of 4
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }

    final decoded = utf8.decode(base64Url.decode(payload));
    final Map<String, dynamic> data = jsonDecode(decoded);
    return data['sub'] as String?;
  } catch (_) {
    return null;
  }
}
