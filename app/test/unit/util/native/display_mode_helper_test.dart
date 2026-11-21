import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:localsend_app/util/native/display_mode_helper.dart';
import 'package:test/test.dart';

void main() {
  group('selectHighRefreshRateMode', () {
    const active60 = DisplayMode(id: 1, width: 1920, height: 1080, refreshRate: 60);

    test('keeps the active mode if it is already the fastest one', () {
      expect(selectHighRefreshRateMode(supportedModes: const [active60], activeMode: active60), active60);
    });

    test('picks the fastest mode that keeps the resolution', () {
      const faster = DisplayMode(id: 2, width: 1920, height: 1080, refreshRate: 120);
      const otherResolution = DisplayMode(id: 3, width: 1280, height: 720, refreshRate: 240);
      expect(selectHighRefreshRateMode(supportedModes: const [DisplayMode.auto, active60, otherResolution, faster], activeMode: active60), faster);
    });

    test('never lowers the refresh rate', () {
      const slower = DisplayMode(id: 4, width: 1920, height: 1080, refreshRate: 30);
      expect(selectHighRefreshRateMode(supportedModes: const [slower], activeMode: active60), active60);
    });

    test('keeps the automatic mode if the active mode is unknown', () {
      expect(selectHighRefreshRateMode(supportedModes: const [active60], activeMode: DisplayMode.auto), DisplayMode.auto);
    });
  });
}
