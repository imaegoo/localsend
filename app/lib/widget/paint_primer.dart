import 'package:flutter/material.dart';

/// Paints one invisible pixel so that the framework composites the whole layer tree.
///
/// On some Android devices (observed on an automotive head unit, with Impeller enabled) the navigation rail is
/// laid out and receives taps but is never painted, while the content pane beside it renders correctly. What was
/// measured on that device, changing one thing at a time:
///
/// | change                                              | rail |
/// |-----------------------------------------------------|------|
/// | nothing                                             | blank |
/// | `setState` once after the first frame                | blank |
/// | `RenderView.markNeedsPaint()`                        | blank |
/// | `RepaintBoundary` around the rail, or around the body| blank |
/// | an overlay with `Opacity(0)`, which paints nothing   | blank |
/// | an overlay that paints opaque pixels                 | shown |
/// | Impeller disabled                                   | shown |
///
/// The rail is therefore dropped while compositing, and any opaque pixel painted anywhere in the tree is enough
/// for it to be composited as well.
///
/// This widget is that pixel: one logical pixel in the bottom right corner of the content pane, painted in the
/// scaffold background colour so that it is invisible, and excluded from hit testing so that it cannot be tapped.
class PaintPrimer extends StatelessWidget {
  const PaintPrimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: SizedBox.square(
          dimension: 1,
          child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ),
      ),
    );
  }
}
