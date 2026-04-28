import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

/// Outer margin from the layout edge to the action face (0 = fill to edges).
const double kHubFaceInset = 4;

/// Black band between “New session” and “History” (visible gap).
const double kHubSegmentGap = 4;

/// Share of the face **between gap edges** for the new-session region (rest is history).
const double kHubTopFraction = 0.70;

const double kHubBorderStroke = 2;

Path hubFacePath(Size s, WearShape shape) {
  final w = s.width;
  final h = s.height;
  if (shape == WearShape.round) {
    final r = math.max(0.0, math.min(w, h) / 2 - kHubFaceInset);
    return Path()..addOval(Rect.fromCircle(center: Offset(w / 2, h / 2), radius: r));
  }
  final rxy = math.min(w, h) * 0.1;
  final rect = Rect.fromLTWH(
    kHubFaceInset,
    kHubFaceInset,
    math.max(0, w - 2 * kHubFaceInset),
    math.max(0, h - 2 * kHubFaceInset),
  );
  return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rxy)));
}

Path hubTopPath(Size s, WearShape shape) {
  final face = hubFacePath(s, shape);
  final w = s.width;
  final ySplit = _splitCenterY(s, shape);
  final yTopEnd = ySplit - kHubSegmentGap / 2;
  if (yTopEnd <= 0) {
    return Path();
  }
  final topRect = Path()..addRect(Rect.fromLTRB(-4, -4, w + 4, yTopEnd));
  return Path.combine(PathOperation.intersect, face, topRect);
}

Path hubBottomPath(Size s, WearShape shape) {
  final face = hubFacePath(s, shape);
  final w = s.width;
  final h = s.height;
  final ySplit = _splitCenterY(s, shape);
  final yBottomStart = ySplit + kHubSegmentGap / 2;
  if (yBottomStart >= h) {
    return Path();
  }
  final bottomRect = Path()..addRect(Rect.fromLTRB(-4, yBottomStart, w + 4, h + 4));
  return Path.combine(PathOperation.intersect, face, bottomRect);
}

/// Vertical **center of the black gap** (equidistant from colored regions).
double _splitCenterY(Size s, WearShape shape) {
  final w = s.width;
  final h = s.height;
  if (shape == WearShape.round) {
    final r = math.max(0.0, math.min(w, h) / 2 - kHubFaceInset);
    final cy = h / 2;
    final innerTop = cy - r;
    final innerBottom = cy + r;
    final span = innerBottom - innerTop;
    final usable = span - kHubSegmentGap;
    if (usable <= 0) {
      return cy;
    }
    final topH = kHubTopFraction * usable;
    return innerTop + topH + kHubSegmentGap / 2;
  }
  final innerTop = kHubFaceInset;
  final innerBottom = h - kHubFaceInset;
  final span = innerBottom - innerTop;
  final usable = span - kHubSegmentGap;
  if (usable <= 0) {
    return h / 2;
  }
  final topH = kHubTopFraction * usable;
  return innerTop + topH + kHubSegmentGap / 2;
}

void paintHubFaceBorder(
  Canvas canvas,
  Size size,
  WearShape shape,
  Color color, {
  double strokeWidth = kHubBorderStroke,
}) {
  final p = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..isAntiAlias = true;
  canvas.drawPath(hubFacePath(size, shape), p);
}
