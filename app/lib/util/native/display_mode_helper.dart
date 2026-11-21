import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Set to `true` to never request a display mode, e.g. to verify the behaviour on a specific device:
/// `--dart-define=localsend.skipHighRefreshRate=true`
const skipHighRefreshRate = bool.fromEnvironment('localsend.skipHighRefreshRate');

/// Returns the display mode with the highest refresh rate that keeps the resolution of [activeMode].
///
/// The resolution is never changed, that would resize the whole app surface.
/// [activeMode] is returned if no supported mode is faster than it.
DisplayMode selectHighRefreshRateMode({
  required List<DisplayMode> supportedModes,
  required DisplayMode activeMode,
}) {
  var best = activeMode;
  for (final mode in supportedModes) {
    if (mode.width != activeMode.width || mode.height != activeMode.height) {
      continue;
    }
    if (mode.refreshRate > best.refreshRate) {
      best = mode;
    }
  }

  return best;
}

/// Requests the highest refresh rate available at the current resolution.
///
/// Returns `true` if a display mode has been requested. Nothing is requested if the display already runs
/// at the best available mode (e.g. a 60 Hz panel), or if the mode has already been requested by a
/// previous launch, because every request reconfigures the panel.
Future<bool> applyHighRefreshRate() async {
  final activeMode = await FlutterDisplayMode.active;
  final targetMode = selectHighRefreshRateMode(
    supportedModes: await FlutterDisplayMode.supported,
    activeMode: activeMode,
  );
  if (targetMode == activeMode) {
    return false;
  }

  if (targetMode == await FlutterDisplayMode.preferred) {
    return false;
  }

  await FlutterDisplayMode.setPreferredMode(targetMode);
  return true;
}
