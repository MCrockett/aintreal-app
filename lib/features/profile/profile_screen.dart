import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/session_provider.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/stats_card.dart';

/// Profile screen showing user info and stats.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(String currentName) {
    setState(() {
      _nameController.text = currentName;
      _isEditing = true;
    });
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    // TODO: Save display name to backend when API is ready
    // For now, just update locally via Firebase Auth
    final authState = ref.read(authProvider);
    if (authState is AuthStateAuthenticated) {
      try {
        await authState.user.updateDisplayName(_nameController.text.trim());
        await authState.user.reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update name: $e')),
          );
        }
      }
    }

    setState(() {
      _isEditing = false;
      _isSaving = false;
    });
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundLight,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(sessionProvider.notifier).endSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final authState = ref.watch(authProvider);

    // Get user info based on session type
    String displayName;
    String? email;
    String? photoUrl;
    bool isGuest = false;

    if (session is SessionGuest) {
      displayName = session.guestName;
      isGuest = true;
    } else if (authState is AuthStateAuthenticated) {
      displayName = authState.displayName;
      email = authState.email;
      photoUrl = authState.photoUrl;
    } else {
      displayName = 'Player';
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Profile'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile header
                _ProfileHeader(
                  displayName: displayName,
                  email: email,
                  photoUrl: photoUrl,
                  isGuest: isGuest,
                  isEditing: _isEditing,
                  isSaving: _isSaving,
                  nameController: _nameController,
                  onEditTap: () => _startEditing(displayName),
                  onSave: _saveName,
                  onCancel: _cancelEditing,
                ),

                const SizedBox(height: 32),

                // Stats card
                const StatsCard(),

                const SizedBox(height: 24),

                // Account section for guests
                if (isGuest) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Playing as Guest',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to save your stats and play across devices.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(sessionProvider.notifier).endSession();
                            },
                            child: const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(isGuest ? 'Exit Guest Mode' : 'Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile header with avatar, name, and edit button.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.isGuest,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.onEditTap,
    required this.onSave,
    required this.onCancel,
  });

  final String displayName;
  final String? email;
  final String? photoUrl;
  final bool isGuest;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            image: photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: photoUrl == null
              ? Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),

        const SizedBox(height: 16),

        // Name (editable for non-guests)
        if (isEditing)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => onSave(),
                ),
              ),
              const SizedBox(width: 8),
              if (isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.check, color: AppTheme.success),
                  onPressed: onSave,
                  tooltip: 'Save',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.error),
                  onPressed: onCancel,
                  tooltip: 'Cancel',
                ),
              ],
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (!isGuest) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEditTap,
                  tooltip: 'Edit name',
                ),
              ],
            ],
          ),

        // Email for signed-in users
        if (email != null) ...[
          const SizedBox(height: 4),
          Text(
            email!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],

        // Guest badge
        if (isGuest) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Guest',
              style: TextStyle(
                color: AppTheme.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
