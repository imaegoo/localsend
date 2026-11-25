/// Covers the content pane with an essentially invisible tint.
///
/// The visible overlay that is known to work differs from every failed attempt in one respect: it actually
/// paints opaque pixels. `Opacity(opacity: 0)` does not, because RenderOpacity skips painting entirely at alpha
/// zero, and a RepaintBoundary only adds a layer without painting anything.
///
/// This variant paints, but at one percent so that it is invisible.
library;

import 'package:flutter/widgets.dart';

class RailProbe extends StatelessWidget {
  const RailProbe({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: ColoredBox(color: Color(0xFF000000)),
        ),
      ),
    );
  }
}
