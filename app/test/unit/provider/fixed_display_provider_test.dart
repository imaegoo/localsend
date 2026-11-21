import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/provider/fixed_display_provider.dart';

void main() {
  group('isFixedDisplay', () {
    test('detects TVs', () {
      expect(isFixedDisplay(features: const ['android.software.leanback', 'android.hardware.touchscreen']), isTrue);
    });

    test('detects car head units', () {
      expect(isFixedDisplay(features: const ['android.hardware.type.automotive']), isTrue);
    });

    test('detects embedded panels', () {
      expect(isFixedDisplay(features: const ['android.hardware.type.embedded']), isTrue);
    });

    test('ignores phones and tablets', () {
      expect(isFixedDisplay(features: const ['android.hardware.touchscreen', 'android.hardware.wifi', 'android.hardware.camera']), isFalse);
    });

    test('handles devices without features', () {
      expect(isFixedDisplay(features: const []), isFalse);
    });
  });
}
