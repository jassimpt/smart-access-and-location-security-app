import 'dart:convert';

class PinCredential {
  const PinCredential({
    required this.salt,
    required this.hash,
    required this.iterations,
  });

  final String salt;
  final String hash;
  final int iterations;

  /// Restores and validates the persisted PIN verifier.
  factory PinCredential.fromJson(Map<String, dynamic> json) {
    final credential = PinCredential(
      salt: json['salt'] as String,
      hash: json['hash'] as String,
      iterations: json['iterations'] as int,
    );
    if (base64Decode(credential.salt).length != 16 ||
        base64Decode(credential.hash).length != 32 ||
        credential.iterations < 100000 ||
        credential.iterations > 1000000) {
      throw const FormatException('Invalid PIN credential');
    }
    return credential;
  }

  /// Serializes only the salted verifier, never the PIN.
  Map<String, dynamic> toJson() => {
    'salt': salt,
    'hash': hash,
    'iterations': iterations,
  };
}
