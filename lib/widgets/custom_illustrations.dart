import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SynergyLogo extends StatelessWidget {
  final double size;
  const SynergyLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SynergyLogoPainter(),
      ),
    );
  }
}

class _SynergyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintPrimary = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintSecondary = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect1 = Rect.fromLTWH(0, size.height * 0.15, size.width * 0.65, size.height * 0.65);
    final rect2 = Rect.fromLTWH(size.width * 0.35, size.height * 0.25, size.width * 0.65, size.height * 0.65);

    // Draw stylized overlapping rounded cards/shapes representing teamwork
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect1, Radius.circular(size.width * 0.18)),
      paintPrimary,
    );

    // Secondary shape with blending (opacity) to represent collaboration
    paintSecondary.color = AppColors.secondary.withOpacity(0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect2, Radius.circular(size.width * 0.18)),
      paintSecondary,
    );

    // Inner overlap accent
    final paintAccent = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    
    final overlapRect = Rect.fromLTRB(
      size.width * 0.35,
      size.height * 0.25,
      size.width * 0.65,
      size.height * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(overlapRect, Radius.circular(size.width * 0.08)),
      paintAccent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingIllustration extends StatelessWidget {
  final int index;
  const OnboardingIllustration({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CustomPaint(
            painter: _OnboardingPainter(index),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPainter extends CustomPainter {
  final int index;
  _OnboardingPainter(this.index);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (index == 0) {
      // Illustration 1: Gantt Chart/Task timeline
      _drawTimeline(canvas, w, h);
    } else if (index == 1) {
      // Illustration 2: Real-time chat bubbles
      _drawChatBubbles(canvas, w, h);
    } else {
      // Illustration 3: Core database/Workflow integrations
      _drawWorkflowIntegrations(canvas, w, h);
    }
  }

  void _drawTimeline(Canvas canvas, double w, double h) {
    final paintPrimary = Paint()..color = AppColors.primary;
    final paintSecondary = Paint()..color = AppColors.secondary;
    final paintBackground = Paint()..color = AppColors.border.withOpacity(0.7);

    // Draw grid lines
    final paintGrid = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 1.5;
    for (int i = 1; i <= 5; i++) {
      final dx = w * (i / 6);
      canvas.drawLine(Offset(dx, 0), Offset(dx, h), paintGrid);
    }

    // Draw Gantt Task 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.25, w * 0.45, h * 0.12),
        const Radius.circular(8),
      ),
      paintPrimary,
    );

    // Draw Gantt Task 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.45, w * 0.4, h * 0.12),
        const Radius.circular(8),
      ),
      paintSecondary,
    );

    // Draw Gantt Task 3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.65, w * 0.35, h * 0.12),
        const Radius.circular(8),
      ),
      paintBackground,
    );

    // Draw connectors/milestone lines
    final paintLine = Paint()
      ..color = AppColors.secondary.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..moveTo(w * 0.6, h * 0.31)
      ..lineTo(w * 0.65, h * 0.31)
      ..lineTo(w * 0.65, h * 0.51)
      ..lineTo(w * 0.45, h * 0.51);
    canvas.drawPath(path, paintLine);

    // Draw milestone diamond
    final paintDiamond = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    final diamondPath = Path()
      ..moveTo(w * 0.65, h * 0.48)
      ..lineTo(w * 0.68, h * 0.51)
      ..lineTo(w * 0.65, h * 0.54)
      ..lineTo(w * 0.62, h * 0.51)
      ..close();
    canvas.drawPath(diamondPath, paintDiamond);
  }

  void _drawChatBubbles(Canvas canvas, double w, double h) {
    final paintLeft = Paint()..color = AppColors.primary;
    final paintRight = Paint()..color = AppColors.secondary;
    final paintLines = Paint()..color = Colors.white..strokeWidth = 3;

    // Left chat bubble
    final pathLeft = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.5, h * 0.25),
        const Radius.circular(16),
      ))
      ..moveTo(w * 0.2, h * 0.45)
      ..lineTo(w * 0.15, h * 0.52)
      ..lineTo(w * 0.28, h * 0.45)
      ..close();
    canvas.drawPath(pathLeft, paintLeft);

    // Text placeholders in left bubble
    canvas.drawLine(Offset(w * 0.22, h * 0.28), Offset(w * 0.55, h * 0.28), paintLines);
    canvas.drawLine(Offset(w * 0.22, h * 0.36), Offset(w * 0.45, h * 0.36), paintLines);

    // Right chat bubble
    final pathRight = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.53, w * 0.5, h * 0.25),
        const Radius.circular(16),
      ))
      ..moveTo(w * 0.8, h * 0.78)
      ..lineTo(w * 0.85, h * 0.85)
      ..lineTo(w * 0.72, h * 0.78)
      ..close();
    canvas.drawPath(pathRight, paintRight);

    // Text placeholders in right bubble
    canvas.drawLine(Offset(w * 0.42, h * 0.61), Offset(w * 0.78, h * 0.61), paintLines);
    canvas.drawLine(Offset(w * 0.42, h * 0.69), Offset(w * 0.65, h * 0.69), paintLines);

    // Mini emoji reaction badge
    final paintBadge = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(w * 0.35, h * 0.53), 14, paintBadge);

    // Emoji heart shape drawing
    final paintHeart = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final heartPath = Path()
      ..moveTo(w * 0.35, h * 0.56)
      ..cubicTo(w * 0.32, h * 0.52, w * 0.32, h * 0.48, w * 0.35, h * 0.49)
      ..cubicTo(w * 0.38, h * 0.48, w * 0.38, h * 0.52, w * 0.35, h * 0.56)
      ..close();
    canvas.drawPath(heartPath, paintHeart);
  }

  void _drawWorkflowIntegrations(Canvas canvas, double w, double h) {
    final paintCore = Paint()..color = AppColors.primary;
    final paintNode = Paint()..color = AppColors.secondary;
    final paintLine = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final center = Offset(w * 0.5, h * 0.5);

    // Node coordinates
    final nodes = [
      Offset(w * 0.2, h * 0.35),
      Offset(w * 0.25, h * 0.7),
      Offset(w * 0.75, h * 0.25),
      Offset(w * 0.8, h * 0.65),
    ];

    // Draw connecting lines
    for (var node in nodes) {
      canvas.drawLine(center, node, paintLine);
    }

    // Draw center core
    canvas.drawCircle(center, w * 0.12, paintCore);
    final paintInner = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(center, w * 0.07, paintInner);

    // Draw external nodes
    for (var node in nodes) {
      canvas.drawCircle(node, 16, paintNode);
      final paintInnerNode = Paint()..color = Colors.white;
      canvas.drawCircle(node, 7, paintInnerNode);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SuccessCheckmark extends StatelessWidget {
  final double size;
  const SuccessCheckmark({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SuccessCheckmarkPainter(),
      ),
    );
  }
}

class _SuccessCheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green circular background
    final paintCircle = Paint()
      ..color = AppColors.secondary.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, paintCircle);

    final paintCircleInner = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.4, paintCircleInner);

    // White Checkmark
    final paintCheck = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(w * 0.32, h * 0.5)
      ..lineTo(w * 0.45, h * 0.62)
      ..lineTo(w * 0.68, h * 0.38);

    canvas.drawPath(path, paintCheck);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
