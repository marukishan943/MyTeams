import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection_container.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/pin_code_field.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  int _countdown = 59;
  Timer? _timer;
  String _otpCode = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 59;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _resendCode(BuildContext context) {
    if (_countdown == 0) {
      context.read<AuthBloc>().add(
            AuthPasswordResetRequested(
              email: widget.email,
            ),
          );
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent successfully.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  void _handleVerify(BuildContext context) {
    if (_otpCode.length == 6) {
      context.read<AuthBloc>().add(
            AuthOTPVerificationRequested(
              email: widget.email,
              token: _otpCode,
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit verification code.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name.substring(0, 1)}**@$domain';
    return '${name.substring(0, 2)}**@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOTPVerified) {
            context.push('/reset-password');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify Email',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: 'We sent a 6-digit code to ',
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: _maskEmail(widget.email),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Pin code fields
                        PinCodeField(
                          length: 6,
                          onCompleted: (code) {
                            setState(() {
                              _otpCode = code;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Resend Timer Row
                        Center(
                          child: _countdown > 0
                              ? Text(
                                  'Resend code in 00:${_countdown.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive the code? ",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    GestureDetector(
                                      onTap: () => _resendCode(context),
                                      child: Text(
                                        'Resend code',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 32),

                        // Verify CTA Button
                        AppButton(
                          text: 'Verify',
                          isLoading: isLoading,
                          onPressed: () => _handleVerify(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
