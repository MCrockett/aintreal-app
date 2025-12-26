import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/session_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/logo.dart';

/// Sign-in screen with Google, Apple, and Guest options.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      // Router redirect will handle navigation
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to sign in with Google';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).signInWithApple();
      // Router redirect will handle navigation
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to sign in with Apple';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(sessionProvider.notifier).startGuestSession();
      // Router redirect will handle navigation
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to start guest session';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthLoading = authState is AuthStateLoading;

    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and tagline
              const Logo(),
              const SizedBox(height: 8),
              Text(
                'Spot the AI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),

              // Sign in text
              Text(
                'Sign in to save your stats',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Google Sign-In button
              _SignInButton(
                onPressed: _isLoading || isAuthLoading ? null : _signInWithGoogle,
                icon: _GoogleIcon(),
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
              ),
              const SizedBox(height: 12),

              // Apple Sign-In button (iOS only - hidden on web)
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                _SignInButton(
                  onPressed: _isLoading || isAuthLoading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                  label: 'Continue with Apple',
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.secondary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppTheme.secondary)),
                ],
              ),

              const SizedBox(height: 20),

              // Guest button
              _SignInButton(
                onPressed: _isLoading || isAuthLoading ? null : _continueAsGuest,
                icon: const Icon(Icons.person_outline, color: AppTheme.textPrimary, size: 24),
                label: 'Play as Guest',
                backgroundColor: AppTheme.secondary,
                textColor: AppTheme.textPrimary,
                subtitle: 'Stats won\'t be saved',
              ),

              const Spacer(flex: 2),

              // Loading indicator
              if (_isLoading || isAuthLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
              ],

              // Terms text
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom sign-in button widget.
class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.subtitle,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: subtitle != null ? 64 : 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Google "G" icon widget.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4), // Blue
                  Color(0xFF34A853), // Green
                  Color(0xFFFBBC05), // Yellow
                  Color(0xFFEA4335), // Red
                ],
                stops: [0.0, 0.33, 0.66, 1.0],
              ).createShader(const Rect.fromLTWH(0, 0, 24, 24)),
          ),
        ),
      ),
    );
  }
}
