import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../widgets/gradient_background.dart';

/// Screen for creating a new game with configuration options.
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Game configuration (matching web defaults)
  int _rounds = 6;
  int _timePerRound = 5;
  bool _speedBonus = true;
  bool _randomBonuses = true;

  bool _isCreating = false;

  static const List<int> roundOptions = [4, 5, 6, 8, 10];
  static const List<int> timeOptions = [3, 5, 7, 10];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    // TODO: Epic 3.1 - Call API to create game
    // For now, simulate and navigate to lobby with mock code
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Navigate to lobby with game code
    // In real implementation, code comes from API response
    context.go('/lobby/ABCD', extra: {
      'playerName': _nameController.text.trim(),
      'isHost': true,
      'config': {
        'rounds': _rounds,
        'timePerRound': _timePerRound,
        'speedBonus': _speedBonus,
        'randomBonuses': _randomBonuses,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Party Mode',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Name input
                    Text(
                      'Your Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 20,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Game Settings header
                    Text(
                      'Game Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Rounds selector
                    _buildOptionRow(
                      label: 'Rounds',
                      options: roundOptions,
                      selectedValue: _rounds,
                      onSelected: (value) => setState(() => _rounds = value),
                    ),

                    const SizedBox(height: 16),

                    // Time per round selector
                    _buildOptionRow(
                      label: 'Time (seconds)',
                      options: timeOptions,
                      selectedValue: _timePerRound,
                      onSelected: (value) =>
                          setState(() => _timePerRound = value),
                    ),

                    const SizedBox(height: 24),

                    // Bonuses toggles
                    _buildToggleRow(
                      label: 'Speed Bonus',
                      subtitle: '+50 for fastest correct',
                      value: _speedBonus,
                      onChanged: (value) =>
                          setState(() => _speedBonus = value),
                    ),

                    const SizedBox(height: 12),

                    _buildToggleRow(
                      label: 'Random Bonuses',
                      subtitle: 'Lucky, Comeback, Tricky...',
                      value: _randomBonuses,
                      onChanged: (value) =>
                          setState(() => _randomBonuses = value),
                    ),

                    const SizedBox(height: 40),

                    // Create button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Game'),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required String label,
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: option != options.last ? 8 : 0,
                ),
                child: _OptionChip(
                  label: option.toString(),
                  isSelected: isSelected,
                  onTap: () => onSelected(option),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(color: AppTheme.secondary, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
