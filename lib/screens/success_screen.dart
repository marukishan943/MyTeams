import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_illustrations.dart';

class SuccessScreen extends StatefulWidget {
  final String message;
  final String buttonText;
  final bool isLoginFlow;
  final bool showChangePassword;

  const SuccessScreen({
    super.key,
    required this.message,
    required this.buttonText,
    this.isLoginFlow = false,
    this.showChangePassword = false,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}


class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleNavigate() {
    if (widget.isLoginFlow) {
      context.go('/dashboard');
    } else {
      // Return back to Login Screen
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Elastic checkmark animation
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    );
                  },
                  child: const SuccessCheckmark(size: 100),
                ),
                const SizedBox(height: 32),

                // Success Message
                Text(
                  'All Done!',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                
                const Spacer(),
                
                // CTA Action Button
                AppButton(
                  text: widget.buttonText,
                  onPressed: _handleNavigate,
                ),
                if (widget.isLoginFlow && widget.showChangePassword) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Change Password',
                    style: AppButtonStyle.outlined,
                    onPressed: () {
                      context.push('/change-password');
                    },
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
