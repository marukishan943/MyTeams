import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonStyle { primary, secondary, outlined, google }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonStyle style;
  final IconData? prefixIcon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.style = AppButtonStyle.primary,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkText = style == AppButtonStyle.secondary || style == AppButtonStyle.outlined || style == AppButtonStyle.google;
    
    Color getBgColor() {
      if (onPressed == null) return theme.disabledColor;
      switch (style) {
        case AppButtonStyle.primary:
          return AppColors.primary;
        case AppButtonStyle.secondary:
          return AppColors.primaryContainer;
        case AppButtonStyle.outlined:
          return Colors.transparent;
        case AppButtonStyle.google:
          return Colors.white;
      }
    }

    Color getTextColor() {
      if (onPressed == null) return AppColors.textLight;
      switch (style) {
        case AppButtonStyle.primary:
          return Colors.white;
        case AppButtonStyle.secondary:
          return AppColors.primary;
        case AppButtonStyle.outlined:
          return AppColors.primary;
        case AppButtonStyle.google:
          return AppColors.textPrimary;
      }
    }

    BorderSide? getBorder() {
      if (style == AppButtonStyle.outlined) {
        return const BorderSide(color: AppColors.primary, width: 1.5);
      }
      if (style == AppButtonStyle.google) {
        return const BorderSide(color: AppColors.border, width: 1);
      }
      return null;
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: getBgColor(),
          foregroundColor: getTextColor(),
          side: getBorder(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: style == AppButtonStyle.google ? 0.5 : 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkText ? AppColors.primary : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (style == AppButtonStyle.google) ...[
                    // Custom Google G Icon drawing instead of local asset
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(
                        painter: _GoogleIconPainter(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else if (prefixIcon != null) ...[
                    Icon(prefixIcon, size: 18, color: getTextColor()),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: getTextColor(),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw Google's 4-color brand G
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Red sector
    paint.color = const Color(0xFFEA4335);
    final pathRed = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.15, h * 0.2)
      ..cubicTo(w * 0.25, h * 0.08, w * 0.38, h * 0.02, w * 0.5, h * 0.02)
      ..cubicTo(w * 0.65, h * 0.02, w * 0.78, h * 0.08, w * 0.88, h * 0.2)
      ..lineTo(w * 0.72, h * 0.35)
      ..cubicTo(w * 0.66, h * 0.28, w * 0.58, h * 0.24, w * 0.5, h * 0.24)
      ..cubicTo(w * 0.44, h * 0.24, w * 0.38, h * 0.26, w * 0.33, h * 0.3)
      ..close();
    canvas.drawPath(pathRed, paint);

    // Yellow sector
    paint.color = const Color(0xFFFBBC05);
    final pathYellow = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.33, h * 0.3)
      ..cubicTo(w * 0.27, h * 0.35, w * 0.24, h * 0.42, w * 0.24, h * 0.5)
      ..cubicTo(w * 0.24, h * 0.58, w * 0.27, h * 0.65, w * 0.33, h * 0.7)
      ..lineTo(w * 0.15, h * 0.8)
      ..cubicTo(w * 0.05, h * 0.72, 0, h * 0.62, 0, h * 0.5)
      ..cubicTo(0, h * 0.38, w * 0.05, h * 0.28, w * 0.15, h * 0.2)
      ..close();
    canvas.drawPath(pathYellow, paint);

    // Green sector
    paint.color = const Color(0xFF34A853);
    final pathGreen = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.33, h * 0.7)
      ..cubicTo(w * 0.38, h * 0.74, w * 0.44, h * 0.76, w * 0.5, h * 0.76)
      ..cubicTo(w * 0.58, h * 0.76, w * 0.66, h * 0.72, w * 0.72, h * 0.65)
      ..lineTo(w * 0.88, h * 0.8)
      ..cubicTo(w * 0.78, h * 0.92, w * 0.65, h * 0.98, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.38, h * 0.98, w * 0.25, h * 0.92, w * 0.15, h * 0.8)
      ..close();
    canvas.drawPath(pathGreen, paint);

    // Blue sector
    paint.color = const Color(0xFF4285F4);
    final pathBlue = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.96, h * 0.5)
      ..cubicTo(w * 0.96, h * 0.6, w * 0.93, h * 0.7, w * 0.88, h * 0.8)
      ..lineTo(w * 0.72, h * 0.65)
      ..cubicTo(w * 0.74, h * 0.6, w * 0.75, h * 0.55, w * 0.75, h * 0.5)
      ..cubicTo(w * 0.75, h * 0.45, w * 0.74, h * 0.4, w * 0.72, h * 0.35)
      ..lineTo(w * 0.88, h * 0.2)
      ..cubicTo(w * 0.93, h * 0.3, w * 0.96, h * 0.4, w * 0.96, h * 0.5)
      ..close();
    canvas.drawPath(pathBlue, paint);

    // Draw the horizontal bar representing Google's G middle arm
    final rectBar = Rect.fromLTWH(w * 0.5, h * 0.38, w * 0.45, h * 0.14);
    canvas.drawRect(rectBar, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
