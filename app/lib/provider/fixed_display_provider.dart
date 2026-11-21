import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:refena_flutter/refena_flutter.dart';

final fixedDisplayProvider = Provider<bool>(
  (_) => throw Exception('fixedDisplayProvider not initialized'),
  debugLabel: 'fixedDisplayProvider',
);

/// System features of devices whose display mode must not be changed.
///
/// Those panels derive their output signal from the requested display mode. Reconfiguring it can blank
/// the screen, and the app may lose frames that were already rendered (e.g. a blank navigation rail).
const fixedDisplayFeatures = {
  // Android TV, see https://github.com/localsend/localsend/issues/3452
  'android.software.leanback',
  // Car head units.
  'android.hardware.type.automotive',
  // Embedded panels, kiosks and smart displays.
  'android.hardware.type.embedded',
};

/// Returns true, if the system features of [features] indicate a fixed display.
bool isFixedDisplay({required Iterable<String> features}) {
  return features.any(fixedDisplayFeatures.contains);
}

/// Returns true, if this device has a fixed display whose mode must not be reconfigured.
Future<bool> checkIfFixedDisplay() async {
  if (checkPlatformIsNot([TargetPlatform.android])) {
    return false;
  }

  final androidInfo = await DeviceInfoPlugin().androidInfo;
  return isFixedDisplay(features: androidInfo.systemFeatures);
}
