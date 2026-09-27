import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection_container.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../theme/app_colors.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Navigation timer
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        final currentUser = sl<AuthRepository>().currentUser;
        if (currentUser != null) {
          context.go('/dashboard');
        } else {
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ultra-sharp Vector Logo Card with Rounded Rectangle Border
                    const _MyTeamsVectorLogo(size: 96),
                    const SizedBox(height: 22),

                    // App Title
                    Text(
                      'MY TEAMS',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: _kPrimaryBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Enterprise Field Force & CRM',
                        style: TextStyle(
                          color: _kPrimaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Loading Indicator & Version
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_kPrimaryBlue),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Version 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ultra-Crisp Vector Logo Widget (Zero pixelation / Zero blur on any display)
class _MyTeamsVectorLogo extends StatelessWidget {
  final double size;

  const _MyTeamsVectorLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryBlue.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF283593), Color(0xFF3949AB), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _MyTeamsEmblemPainter(),
          ),
        ),
      ),
    );
  }
}

class _MyTeamsEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background soft halo glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.32, glowPaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final wingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final cutoutPaint = Paint()
      ..color = const Color(0xFF3949AB)
      ..style = PaintingStyle.fill;

    // Central Building
    final centerBuildingRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.35, h * 0.33, w * 0.30, h * 0.37),
      topLeft: Radius.circular(w * 0.04),
      topRight: Radius.circular(w * 0.04),
    );
    canvas.drawRRect(centerBuildingRect, whitePaint);

    // Left Wing Building
    final leftWingRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.22, h * 0.44, w * 0.15, h * 0.26),
      topLeft: Radius.circular(w * 0.03),
      topRight: Radius.circular(w * 0.03),
    );
    canvas.drawRRect(leftWingRect, wingPaint);

    // Right Wing Building
    final rightWingRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.63, h * 0.44, w * 0.15, h * 0.26),
      topLeft: Radius.circular(w * 0.03),
      topRight: Radius.circular(w * 0.03),
    );
    canvas.drawRRect(rightWingRect, wingPaint);

    // Base Foundation Bar
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.69, w * 0.68, h * 0.035),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(baseRect, whitePaint);

    // Windows - Central Grid (2 columns x 3 rows)
    final winW = w * 0.045;
    final winH = h * 0.04;
    for (int row = 0; row < 3; row++) {
      final wy = h * 0.38 + (row * (winH + h * 0.03));
      final wx1 = w * 0.40;
      final wx2 = w * 0.555;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(wx1, wy, winW, winH), Radius.circular(w * 0.01)),
        cutoutPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(wx2, wy, winW, winH), Radius.circular(w * 0.01)),
        cutoutPaint,
      );
    }

    // Central Entrance Door
    final doorRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.46, h * 0.60, w * 0.08, h * 0.09),
      topLeft: Radius.circular(w * 0.02),
      topRight: Radius.circular(w * 0.02),
    );
    canvas.drawRRect(doorRect, cutoutPaint);

    // Golden Achievement Star above central roof
    final goldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final starPath = Path();
    final sx = w * 0.5;
    final sy = h * 0.24;
    final r = w * 0.055;
    starPath.moveTo(sx, sy - r);
    starPath.lineTo(sx + r * 0.32, sy - r * 0.32);
    starPath.lineTo(sx + r, sy);
    starPath.lineTo(sx + r * 0.32, sy + r * 0.32);
    starPath.lineTo(sx, sy + r);
    starPath.lineTo(sx - r * 0.32, sy + r * 0.32);
    starPath.lineTo(sx - r, sy);
    starPath.lineTo(sx - r * 0.32, sy - r * 0.32);
    starPath.close();

    canvas.drawPath(starPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
