// ignore_for_file: avoid_print
/// Generates assets/icon/app_icon.png by replicating the _ClassoraLogo /
/// _GradCapPainter from splash_screen.dart at 1024 × 1024.
///
/// Run with:  dart run tool/generate_icon.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

// ─── Brand colours (match splash_screen.dart) ────────────────────────────────
const int _kBrightBlueR = 0x25, _kBrightBlueG = 0x63, _kBrightBlueB = 0xEB;
const int _kDarkBlueR   = 0x0C, _kDarkBlueG   = 0x34, _kDarkBlueB   = 0x84;
const int _kPaleBlueR   = 0xBF, _kPaleBlueG   = 0xDB, _kPaleBlueB   = 0xFE;

void main() async {
  const int size = 1024;

  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0)); // transparent

  final double cx = size / 2.0;
  final double cy = size / 2.0;
  final double radius = size / 2.0;

  // ── 1. Gradient background circle ─────────────────────────────────────────
  // Linear gradient: top-left (#2563EB) → bottom-right (#0C3484)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double dx = x - cx;
      final double dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        final double t = ((dx + dy) / (2.0 * radius) + 1.0) / 2.0;
        final int r = (_kBrightBlueR + (_kDarkBlueR - _kBrightBlueR) * t)
            .round()
            .clamp(0, 255);
        final int g = (_kBrightBlueG + (_kDarkBlueG - _kBrightBlueG) * t)
            .round()
            .clamp(0, 255);
        final int b = (_kBrightBlueB + (_kDarkBlueB - _kBrightBlueB) * t)
            .round()
            .clamp(0, 255);
        image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
      }
    }
  }

  // ── 2. Inner ring (white @ 12 % opacity, radius 118/140 of full radius) ───
  final double innerR = radius * (118.0 / 140.0);
  final double scale  = size / 140.0;
  final double ringHW = 1.0 * scale; // half-width of ring in pixels
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double dx = x - cx;
      final double dy = y - cy;
      final double dist = math.sqrt(dx * dx + dy * dy);
      if ((dist - innerR).abs() <= ringHW) {
        final pixel = image.getPixel(x, y);
        final int baseR = pixel.r.toInt();
        final int baseG = pixel.g.toInt();
        final int baseB = pixel.b.toInt();
        image.setPixel(
          x,
          y,
          img.ColorRgba8(
            (baseR + (255 - baseR) * 0.12).round(),
            (baseG + (255 - baseG) * 0.12).round(),
            (baseB + (255 - baseB) * 0.12).round(),
            255,
          ),
        );
      }
    }
  }

  // ── 3. Graduation cap (replicates _GradCapPainter on 84 × 84) ─────────────
  //
  // The painter draws on 84 × 84.  The logo circle is 140 × 140.
  // Painter is centered in the circle, so painter origin = (28, 28) in circle
  // space.  Scale everything by (1024 / 140).

  const double painterOff = 28.0; // (140 - 84) / 2

  // Convert painter-space x → image pixel x
  int px(double v) => ((painterOff + v) * scale).round();
  int py(double v) => ((painterOff + v) * scale).round();

  final double w = 84.0;
  final double h = 84.0;
  final double pCx = w / 2; // 42

  final double boardCY = h * 0.36;   // 30.24
  final double bHW     = w * 0.44;   // 36.96
  final double bHH     = h * 0.13;   // 10.92

  // ── Board diamond ──────────────────────────────────────────────────────────
  img.fillPolygon(
    image,
    vertices: [
      img.Point(px(pCx),        py(boardCY - bHH)),
      img.Point(px(pCx + bHW),  py(boardCY)),
      img.Point(px(pCx),        py(boardCY + bHH)),
      img.Point(px(pCx - bHW),  py(boardCY)),
    ],
    color: img.ColorRgba8(255, 255, 255, 255),
  );

  // ── Highlight (upper half of board at 22 % white) ─────────────────────────
  // Paint white pixels at low alpha on the upper triangle of the diamond
  _blendPolygon(
    image,
    vertices: [
      [px(pCx).toDouble(),       py(boardCY - bHH).toDouble()],
      [px(pCx + bHW).toDouble(), py(boardCY).toDouble()],
      [px(pCx).toDouble(),       py(boardCY).toDouble()],
      [px(pCx - bHW).toDouble(), py(boardCY).toDouble()],
    ],
    alpha: 0.22,
  );

  // ── Top knob / button ─────────────────────────────────────────────────────
  img.fillCircle(
    image,
    x: px(pCx),
    y: py(boardCY - bHH - 5),
    radius: (3.5 * scale).round().clamp(1, 50),
    color: img.ColorRgba8(_kPaleBlueR, _kPaleBlueG, _kPaleBlueB, 255),
  );

  // ── Cap body (trapezoid) ──────────────────────────────────────────────────
  final double sidesTop    = boardCY + bHH * 0.45;
  final double sidesBottom = boardCY + h * 0.38;
  final double sHW         = bHW * 0.52;

  img.fillPolygon(
    image,
    vertices: [
      img.Point(px(pCx - sHW),         py(sidesTop)),
      img.Point(px(pCx + sHW),         py(sidesTop)),
      img.Point(px(pCx + sHW * 0.78),  py(sidesBottom)),
      img.Point(px(pCx - sHW * 0.78),  py(sidesBottom)),
    ],
    color: img.ColorRgba8(255, 255, 255, (0.88 * 255).round()),
  );

  // ── Tassel line ───────────────────────────────────────────────────────────
  final double tasselX  = pCx + bHW;
  final double tasselY0 = boardCY;
  final double tasselY1 = boardCY + h * 0.30;
  final int    lineW    = (2.2 * scale).round().clamp(2, 30);

  img.drawLine(
    image,
    x1: px(tasselX), y1: py(tasselY0),
    x2: px(tasselX), y2: py(tasselY1),
    color: img.ColorRgba8(_kPaleBlueR, _kPaleBlueG, _kPaleBlueB, 255),
    thickness: lineW,
    antialias: true,
  );

  // ── Tassel tuft ───────────────────────────────────────────────────────────
  final int tuftW = (2.5 * scale).round().clamp(2, 30);
  final paleBlue  = img.ColorRgba8(_kPaleBlueR, _kPaleBlueG, _kPaleBlueB, 255);

  img.drawLine(
    image,
    x1: px(tasselX - 5), y1: py(tasselY1),
    x2: px(tasselX + 3), y2: py(tasselY1 + 7),
    color: paleBlue, thickness: tuftW, antialias: true,
  );
  img.drawLine(
    image,
    x1: px(tasselX + 3), y1: py(tasselY1),
    x2: px(tasselX - 5), y2: py(tasselY1 + 7),
    color: paleBlue, thickness: tuftW, antialias: true,
  );

  // ── Sparkle dots ──────────────────────────────────────────────────────────
  final int sparkleR = (2.0 * scale).round().clamp(2, 20);
  for (final pos in [
    [pCx - bHW * 0.85, boardCY - bHH * 1.9],
    [pCx + bHW * 0.75, boardCY - bHH * 2.2],
    [pCx - bHW * 0.55, boardCY + h * 0.58],
  ]) {
    img.fillCircle(
      image,
      x: px(pos[0]), y: py(pos[1]),
      radius: sparkleR,
      color: img.ColorRgba8(_kPaleBlueR, _kPaleBlueG, _kPaleBlueB,
          (0.7 * 255).round()),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  final file = File('assets/icon/app_icon.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(img.encodePng(image));
  print('✓  Icon saved → ${file.path}  (${size}×${size})');
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Blends a white overlay at [alpha] opacity inside the given convex polygon.
/// Uses a simple scanline fill; vertices must be in order (CW or CCW).
void _blendPolygon(
  img.Image image, {
  required List<List<double>> vertices,
  required double alpha,
}) {
  if (vertices.isEmpty) return;

  final minY = vertices.map((p) => p[1]).reduce(math.min).ceil();
  final maxY = vertices.map((p) => p[1]).reduce(math.max).floor();

  final n = vertices.length;
  for (int y = minY; y <= maxY; y++) {
    final List<double> xs = [];
    for (int i = 0; i < n; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % n];
      if ((p1[1] <= y && p2[1] > y) || (p2[1] <= y && p1[1] > y)) {
        final t = (y - p1[1]) / (p2[1] - p1[1]);
        xs.add(p1[0] + t * (p2[0] - p1[0]));
      }
    }
    if (xs.length < 2) continue;
    xs.sort();
    for (int x = xs[0].ceil(); x <= xs[1].floor(); x++) {
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
      final pixel = image.getPixel(x, y);
      image.setPixel(
        x, y,
        img.ColorRgba8(
          (pixel.r.toInt() + (255 - pixel.r.toInt()) * alpha).round(),
          (pixel.g.toInt() + (255 - pixel.g.toInt()) * alpha).round(),
          (pixel.b.toInt() + (255 - pixel.b.toInt()) * alpha).round(),
          pixel.a.toInt(),
        ),
      );
    }
  }
}
