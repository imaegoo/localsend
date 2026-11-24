/// Forces one repaint of the whole render view shortly after the first frame.
///
/// The navigation rail on some Android head units is laid out and hit tested correctly but never painted,
/// because nothing invalidates paint there. Rebuilding the tree does not help: an identical configuration does
/// not mark any render object as needing paint. Marking the render view itself does repaint everything.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RailProbe extends StatefulWidget {
  const RailProbe({super.key});

  @override
  State<RailProbe> createState() => _RailProbeState();
}

class _RailProbeState extends State<RailProbe> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final view in RendererBinding.instance.renderViews) {
        view.markNeedsPaint();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
