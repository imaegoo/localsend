/// An invisible, full size child that is composited on its own.
///
/// The working reference is a static overlay in the content pane that makes the navigation rail appear. It never
/// rebuilds, so the effect has to come from the extra composited child rather than from repaint timing. This
/// variant adds such a child without showing anything.
library;

import 'package:flutter/widgets.dart';

class RailProbe extends StatelessWidget {
  const RailProbe({super.key});

  @override
  Widget build(BuildContext context) {
    // Positioned with zero opacity still participates in layer composition.
    return const Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: ColoredBox(color: Color(0xFF000000)),
        ),
      ),
    );
  }
}
