import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class MotionAccessibility {
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration dur(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;

  static Duration get medium => YurukTokens.durationMedium;
  static Duration get fast => YurukTokens.durationFast;
}
