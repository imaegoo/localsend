/// The plain overlay that is known to make the rail appear (this is what the working B2 build added).
///
/// Serves as the control of the experiment: if this one works, the harness is sound.
library;

import 'package:flutter/material.dart';

class RailProbe extends StatelessWidget {
  const RailProbe({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Text('PROBE', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ),
    );
  }
}
