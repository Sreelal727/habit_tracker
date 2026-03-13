import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.track_changes,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Habit Tracker',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Build better habits, achieve your goals,\nand earn rewards along the way.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              // Feature highlights
              _FeatureChip(
                icon: Icons.check_circle_outline,
                text: 'Track daily habits & goals',
              ),
              const SizedBox(height: 8),
              _FeatureChip(
                icon: Icons.monetization_on_outlined,
                text: 'Earn coins with daily rewards',
              ),
              const SizedBox(height: 8),
              _FeatureChip(
                icon: Icons.bar_chart,
                text: 'Visualize your progress',
              ),
              const Spacer(flex: 3),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
        ),
      ],
    );
  }
}
