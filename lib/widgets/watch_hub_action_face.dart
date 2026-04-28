import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../painting/watch_hub_split_paths.dart';

class _HubTopClipper extends CustomClipper<Path> {
  _HubTopClipper(this.shape);
  final WearShape shape;

  @override
  Path getClip(Size size) => hubTopPath(size, shape);

  @override
  bool shouldReclip(covariant _HubTopClipper old) => old.shape != shape;
}

class _HubBottomClipper extends CustomClipper<Path> {
  _HubBottomClipper(this.shape);
  final WearShape shape;

  @override
  Path getClip(Size size) => hubBottomPath(size, shape);

  @override
  bool shouldReclip(covariant _HubBottomClipper old) => old.shape != shape;
}

class _HubFaceBorderPainter extends CustomPainter {
  _HubFaceBorderPainter(this.shape, this.color, this.strokeWidth);
  final WearShape shape;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    paintHubFaceBorder(canvas, size, shape, color, strokeWidth: strokeWidth);
  }

  @override
  bool shouldRepaint(covariant _HubFaceBorderPainter old) {
    return old.shape != shape || old.color != color || old.strokeWidth != strokeWidth;
  }
}

class WatchHubActionFace extends StatelessWidget {
  const WatchHubActionFace({
    super.key,
    required this.shape,
    required this.onNewSession,
    required this.onHistory,
    required this.newSessionContent,
    required this.historyContent,
  });

  final WearShape shape;
  final VoidCallback onNewSession;
  final VoidCallback onHistory;
  final Widget newSessionContent;
  final Widget historyContent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            ClipPath(
              clipper: _HubTopClipper(shape),
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                child: InkWell(
                  onTap: onNewSession,
                  child: newSessionContent,
                ),
              ),
            ),
            ClipPath(
              clipper: _HubBottomClipper(shape),
              child: Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: InkWell(
                  onTap: onHistory,
                  child: historyContent,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HubFaceBorderPainter(
                    shape,
                    Colors.black,
                    kHubBorderStroke,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
