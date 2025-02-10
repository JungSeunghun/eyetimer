import 'package:flutter/material.dart';

class NoGlowScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Simply return the child without any overscroll glow
    return child;
  }
}