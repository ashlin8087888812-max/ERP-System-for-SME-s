import 'dart:math' as math;
import 'dart:ui';

/// Maps a value from one range to another proportionally.
///
/// Takes a [value] from the range [inMin] to [inMax] and maps it
/// proportionally to the range [outMin] to [outMax].
///
/// Example:
/// ```dart
/// // Map 50 from range 0-100 to range 0-1
/// double result = mapValue(50, 0, 100, 0, 1); // Returns 0.5
///
/// // Map 75 from range 0-100 to range 200-400
/// double result2 = mapValue(75, 0, 100, 200, 400); // Returns 350
/// ```
///
/// Parameters:
/// - [value]: The value to map
/// - [inMin]: The minimum value of the input range
/// - [inMax]: The maximum value of the input range
/// - [outMin]: The minimum value of the output range
/// - [outMax]: The maximum value of the output range
/// - [clamp]: If true, clamps the output to [outMin] and [outMax] (default: false)
///
/// Returns the mapped value in the output range.
double mapValue(
  double value,
  double inMin,
  double inMax,
  double outMin,
  double outMax, {
  bool clamp = false,
}) {
  // Handle edge case where input range is zero
  if (inMin == inMax) {
    return outMin;
  }

  // Calculate the mapped value
  double result = outMin + (outMax - outMin) * ((value - inMin) / (inMax - inMin));

  // Optionally clamp the result to the output range
  if (clamp) {
    if (outMin < outMax) {
      result = result.clamp(outMin, outMax);
    } else {
      result = result.clamp(outMax, outMin);
    }
  }

  return result;
}

double mapUniformScale(
  double outMin,
  double outMax,
  double sWidth,
  double sHeight, {
  double baseWidth = 800,
  double baseHeight = 500,
  double maxWidth = 2194,
  double maxHeight = 1187,
}) {
  // Calculate individual progress
  final widthProgress =
      ((sWidth - baseWidth) / (maxWidth - baseWidth)).clamp(0.0, 1.0);
  final heightProgress =
      ((sHeight - baseHeight) / (maxHeight - baseHeight)).clamp(0.0, 1.0);

  final widthChanged = sWidth != baseWidth;
  final heightChanged = sHeight != baseHeight;

  final bothIncreased = sWidth > baseWidth && sHeight > baseHeight;
  final bothDecreased = sWidth < baseWidth && sHeight < baseHeight;

  if (bothIncreased || bothDecreased) {
    // Sync: interpolate based on the smaller of the two progress values
    final syncProgress = math.min(widthProgress, heightProgress);
    return outMin + (outMax - outMin) * syncProgress;
  }

  // Desync: freeze at the value where sync broke (based on last common progress)
  final frozenProgress = math.min(widthProgress, heightProgress);
  return outMin + (outMax - outMin) * frozenProgress;
}


/// Extension on num to provide a convenient map method.
///
/// Example:
/// ```dart
/// double result = 50.0.map(0, 100, 0, 1); // Returns 0.5
/// ```
extension MapExtension on num {
  double map(
    double inMin,
    double inMax,
    double outMin,
    double outMax, {
    bool clamp = false,
  }) {
    return mapValue(toDouble(), inMin, inMax, outMin, outMax, clamp: clamp);
  }
}
extension UniformScaleMap on Size {
  double uniformScale({
    required Size reference,
    double min = 1.0,
    required double max,
  }) {
    final scaleX = width / reference.width;
    final scaleY = height / reference.height;
    return math.min(scaleX, scaleY).clamp(min, max);
  }
}
