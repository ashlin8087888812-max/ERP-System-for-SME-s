import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ===============================
/// Public widget
/// ===============================

class StripesBackground extends StatefulWidget {
  const StripesBackground({
    super.key,
    this.color = const ui.Color(0xFF000000),
    this.speed = 4.0,
    this.spacing = 34,
    this.stripeWidth = 0.5,
  });

  final Color color;
  final double speed; // pixels per second
  final double spacing;
  final double stripeWidth;

  @override
  State<StripesBackground> createState() => _StripesBackgroundState();
}

class _StripesBackgroundState extends State<StripesBackground>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  ui.Image? _tile;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    if (kIsWeb) {
      _createStripeTile(widget.color).then((img) {
        if (mounted) setState(() => _tile = img);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: kIsWeb && _tile != null
            ? _ShaderStripesPainter(
                tile: _tile!,
                controller: _controller,
                speed: widget.speed,
              )
            : _CpuStripesPainter(
                controller: _controller,
                speed: widget.speed,
                color: widget.color,
                spacing: widget.spacing,
                stripeWidth: widget.stripeWidth,
              ),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// ===============================
/// CPU painter (mobile / desktop)
/// ===============================

class _CpuStripesPainter extends CustomPainter {
  _CpuStripesPainter({
    required this.controller,
    required this.speed,
    required this.spacing,
    required this.stripeWidth,
    required Color color,
  })  : _paint = Paint()..color = color,
        super(repaint: controller);

  final AnimationController controller;
  final double speed;
  final Paint _paint;

  final double spacing;
  final double stripeWidth;
  static const double _angle = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final elapsedMs = controller.lastElapsedDuration?.inMilliseconds ?? 0;
    final offset = elapsedMs * (speed / 1000);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_angle);
    canvas.translate(-size.width / 2, -size.height / 2);

    final total = size.width + size.height;
    final normalized =
        offset - (offset ~/ spacing) * spacing;
    final start = -total + normalized;

    for (double x = start; x < total; x += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, stripeWidth, size.height * 2),
        _paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

/// ===============================
/// Shader painter (web)
/// ===============================

class _ShaderStripesPainter extends CustomPainter {
  _ShaderStripesPainter({
    required this.tile,
    required this.controller,
    required this.speed,
  })  : _paint = Paint(),
        super(repaint: controller);

  final ui.Image tile;
  final AnimationController controller;
  final double speed;

  final Paint _paint;
  final Matrix4 _matrix = Matrix4.identity();

  @override
  void paint(Canvas canvas, Size size) {
    final elapsedMs =
        controller.lastElapsedDuration?.inMilliseconds ?? 0;
    final offset = elapsedMs * (speed / 1000);

    _matrix.setTranslationRaw(offset, 0, 0);

    _paint.shader = ImageShader(
      tile,
      TileMode.repeated,
      TileMode.repeated,
      _matrix.storage,
    );

    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// ===============================
/// Stripe tile generator (web)
/// ===============================

Future<ui.Image> _createStripeTile(Color color) async {
  const double size = 128.0;
  const double spacing = 24;
  const double stripeWidth = 6;
  const double angle = 0.6;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.translate(size / 2, size / 2);
  canvas.rotate(angle);
  canvas.translate(-size / 2, -size / 2);

  final paint = Paint()..color = color;

  for (double x = -size; x < size * 2; x += spacing) {
    canvas.drawRect(
      Rect.fromLTWH(x, 0, stripeWidth, size * 2),
      paint,
    );
  }

  final picture = recorder.endRecording();
  return picture.toImage(size.toInt(), size.toInt());
}
