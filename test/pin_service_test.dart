import 'package:flutter_test/flutter_test.dart';
import 'package:smart_access/features/authentication/services/pin_service.dart';
import 'package:smart_access/features/authentication/models/pin_credential.dart';

void main() {
  test(
    'real PIN derivation uses independent salts and verifies across serialization',
    () async {
      final service = PinService();
      final first = await service.create('123456');
      final second = await service.create('123456');
      expect(first.salt, isNot(second.salt));
      expect(first.hash, isNot(second.hash));
      expect(first.toJson().values, isNot(contains('123456')));
      final restored = PinCredential.fromJson(first.toJson());
      expect(await service.verify('123456', restored), isTrue);
      expect(await service.verify('654321', first), isFalse);
      expect(await service.verify('12345', first), isFalse);
      expect(service.isValid('123456\n'), isFalse);
      expect(service.isValid('１２３４５６'), isFalse);
    },
  );
}
