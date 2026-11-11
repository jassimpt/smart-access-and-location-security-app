import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pin_credential.dart';

final pinServiceProvider = Provider((ref) => PinService());

class PinService {
  static const pinLength = 6;
  static const _iterations = 600000;

  /// Accepts exactly six ASCII digits.
  bool isValid(String pin) => RegExp(r'^[0-9]{6}$').hasMatch(pin);

  /// Derives a salted PIN verifier outside the UI isolate.
  Future<PinCredential> create(String pin) async {
    if (!isValid(pin)) throw ArgumentError('Invalid PIN');
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await compute(_deriveHash, (pin, salt, _iterations));
    return PinCredential(
      salt: base64Encode(salt),
      hash: base64Encode(hash),
      iterations: _iterations,
    );
  }

  /// Compares a derived verifier without early exit on differing bytes.
  Future<bool> verify(String pin, PinCredential credential) async {
    if (!isValid(pin)) return false;
    final actual = await compute(_deriveHash, (
      pin,
      base64Decode(credential.salt),
      credential.iterations,
    ));
    final expected = base64Decode(credential.hash);
    var difference = actual.length ^ expected.length;
    for (var i = 0; i < actual.length && i < expected.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }
}

/// Derives the PBKDF2 verifier in a worker isolate.
Future<List<int>> _deriveHash((String, List<int>, int) input) async {
  final algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: input.$3,
    bits: 256,
  );
  final key = await algorithm.deriveKeyFromPassword(
    password: input.$1,
    nonce: input.$2,
  );
  return key.extractBytes();
}
