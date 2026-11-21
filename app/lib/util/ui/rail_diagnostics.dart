import 'package:flutter/material.dart';

/// Enables the rail diagnostics overlay: `--dart-define=localsend.railDiagnostics=true`.
///
/// On some wide Android devices (car head units) the `NavigationRail` reserves its layout space and stays
/// tappable, but is never painted. This switch renders the rail in different ways so that the failing layer
/// can be identified on the device itself, without adb.
///
/// Not `const`, so that the analyzer does not fold the disabled branch into dead code.
final bool railDiagnosticsEnabled = const bool.fromEnvironment('localsend.railDiagnostics');

/// A rail entry as plain data, so that this file does not depend on the home page.
class RailDiagDestination {
  final IconData icon;
  final String label;

  const RailDiagDestination({required this.icon, required this.label});
}

/// The rail layouts of the diagnostics build.
enum RailDiagMode {
  baseline('0 framework rail'),
  custom('1 plain container'),
  bitmap('2 repaint boundary'),
  debugPaint('3 debug colors'),
  bottomBar('4 bottom bar');

  const RailDiagMode(this.label);

  final String label;

  /// Whether this mode shows a navigation rail (instead of the bottom bar).
  bool get showsRail => this != RailDiagMode.bottomBar;

  RailDiagMode get next => RailDiagMode.values[(index + 1) % RailDiagMode.values.length];
}

/// The currently selected rail layout.
final railDiagMode = ValueNotifier<RailDiagMode>(RailDiagMode.baseline);

/// A hand written rail that uses neither [NavigationRail] nor [Material].
///
/// If this one is painted while [NavigationRail] is not, the problem is inside the framework widget
/// (e.g. the `Material` + `elevation` layer), not in the engine.
class RailDiagCustomRail extends StatelessWidget {
  final List<RailDiagDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool debugColors;

  const RailDiagCustomRail({required this.destinations, required this.selectedIndex, required this.onSelected, required this.debugColors, super.key});

  @override
  Widget build(BuildContext context) {
    final foreground = debugColors ? Colors.red : Colors.white;
    return Container(
      width: 256,
      color: debugColors ? Colors.magenta : const Color(0xFF141F1C),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Text(
                'LocalSend',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: foreground),
              ),
            ),
            for (var i = 0; i < destinations.length; i++)
              ListTile(
                selected: i == selectedIndex,
                leading: Icon(destinations[i].icon, color: foreground),
                title: Text(destinations[i].label, style: TextStyle(color: foreground)),
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small overlay that switches the rail layout at runtime.
///
/// It is rendered inside the content pane, which is painted correctly on the affected devices.
class RailDiagPanel extends StatefulWidget {
  const RailDiagPanel({super.key});

  @override
  State<RailDiagPanel> createState() => _RailDiagPanelState();
}

class _RailDiagPanelState extends State<RailDiagPanel> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: ValueListenableBuilder<RailDiagMode>(
        valueListenable: railDiagMode,
        builder: (context, mode, _) {
          return Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RAIL: ${mode.label}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextButton(onPressed: () => railDiagMode.value = mode.next, child: const Text('NEXT')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
