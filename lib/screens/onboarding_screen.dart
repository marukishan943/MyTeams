import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _slides = [
    OnboardingItem(
      title: "Align Your Team's Goals",
      description: "Organize projects, assign tasks, and track milestones with visual timelines that keep everyone aligned.",
    ),
    OnboardingItem(
      title: "Move Conversations Out of Email",
      description: "Real-time threads, direct messages, and team huddles designed to reduce meeting fatigue and accelerate decision-making.",
    ),
    OnboardingItem(
      title: "Centralize Your Work Environment",
      description: "Connect your favorite tools—GitHub, Figma, Google Drive, and Slack integrations—directly into your team feeds.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _skip() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SynergyLogo(size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Synergy',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 18,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (_currentIndex < _slides.length - 1)
                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // PageView Slide content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final item = _slides[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OnboardingIllustration(index: index),
                          const SizedBox(height: 32),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? AppColors.secondary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // CTAs
                AppButton(
                  text: 'Create Account',
                  onPressed: () {
                    context.push('/signup');
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Sign In',
                  style: AppButtonStyle.outlined,
                  onPressed: () {
                    context.push('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;

  OnboardingItem({
    required this.title,
    required this.description,
  });
}
