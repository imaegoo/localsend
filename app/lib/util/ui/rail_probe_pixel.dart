/// A single opaque pixel in the bottom right corner of the content pane.
///
/// The smallest possible amount of painted, opaque content. Invisible to the eye, but it does paint.
library;

import 'package:flutter/widgets.dart';

class RailProbe extends StatelessWidget {
  const RailProbe({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: SizedBox(
          width: 1,
          height: 1,
          child: ColoredBox(color: Color(0xFF000000)),
        ),
      ),
    );
  }
}
