import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

/// In debug builds on large screens, clips the app to a Wear OS–sized viewport
/// so you can see roughly how it looks on a watch. On real watches (small
/// window) or in release builds, this is a no-op.
///
/// Uses [WatchShape] from `wear_plus` so round vs. square matches device (or
/// the plugin default when the platform channel is unavailable).
class WearScreenPreview extends StatelessWidget {
  const WearScreenPreview({
    super.key,
    required this.child,
  });

  final Widget child;

  static const double _largeScreenShortestSide = 280;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return child;
    }
    final shortest =
        math.min(MediaQuery.sizeOf(context).width, MediaQuery.sizeOf(context).height);
    if (shortest <= _largeScreenShortestSide) {
      return child;
    }
    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: WatchShape(
          builder: (context, shape, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxSide = math.min(constraints.maxWidth, constraints.maxHeight);
                final diameter = maxSide * 0.72;
                return _bezel(
                  shape,
                  diameter,
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(diameter, diameter),
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _bezel(WearShape shape, double diameter, Widget screen) {
    const bezel = 12.0;
    final inner = SizedBox(
      width: diameter,
      height: diameter,
      child: shape == WearShape.round
          ? ClipOval(child: screen)
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: screen,
            ),
    );
    if (shape == WearShape.round) {
      final outer = diameter + bezel * 2;
      return Container(
        width: outer,
        height: outer,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2A2A2A),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              spreadRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: inner,
      );
    }
    return Container(
      padding: const EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF2A2A2A),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 2,
            color: Colors.black54,
          ),
        ],
      ),
      child: inner,
    );
  }
}
