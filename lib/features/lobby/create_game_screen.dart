import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/game_api.dart';
import '../../models/game.dart';
import '../../widgets/gradient_background.dart';

/// Screen for creating a new game with configuration options.
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({
    super.key,
    this.mode = GameMode.party,
    this.initialName,
    this.initialRounds,
    this.initialTimePerRound,
    this.initialSpeedBonus,
    this.initialRandomBonuses,
  });

  final GameMode mode;
  final String? initialName;
  final int? initialRounds;
  final int? initialTimePerRound;
  final bool? initialSpeedBonus;
  final bool? initialRandomBonuses;

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

  /// Whether this is a solo mode (no multiplayer lobby)
  bool get _isSoloMode =>
      widget.mode == GameMode.classic || widget.mode == GameMode.marathon;

  /// Whether config options should be shown (hidden for marathon)
  bool get _showConfigOptions => widget.mode != GameMode.marathon;

  /// Get display title for the current mode
  String get _modeTitle {
    return switch (widget.mode) {
      GameMode.party => 'Party Mode',
      GameMode.classic => 'Classic Solo',
      GameMode.marathon => 'Marathon',
    };
  }

  /// Get mode description
  String get _modeDescription {
    return switch (widget.mode) {
      GameMode.party => '2-8 players compete together',
      GameMode.classic => 'Practice at your own pace',
      GameMode.marathon => '26 rounds - one miss and it\'s over!',
    };
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill from initial values if provided (e.g., from Play Again)
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialRounds != null) {
      _rounds = widget.initialRounds!;
    }
    if (widget.initialTimePerRound != null) {
      _timePerRound = widget.initialTimePerRound!;
    }
    if (widget.initialSpeedBonus != null) {
      _speedBonus = widget.initialSpeedBonus!;
    }
    if (widget.initialRandomBonuses != null) {
      _randomBonuses = widget.initialRandomBonuses!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Marathon mode has fixed 26 rounds, no bonuses
      final effectiveRounds = widget.mode == GameMode.marathon ? 26 : _rounds;
      final effectiveSpeedBonus =
          widget.mode == GameMode.marathon ? false : _speedBonus;
      final effectiveRandomBonuses =
          widget.mode == GameMode.marathon ? false : _randomBonuses;

      final config = GameConfig(
        rounds: effectiveRounds,
        timePerRound: _timePerRound,
        speedBonus: effectiveSpeedBonus,
        randomBonuses: effectiveRandomBonuses,
        mode: widget.mode,
      );

      final response = await GameApi.instance.createGame(
        playerName: _nameController.text.trim(),
        config: config,
      );

      if (!mounted) return;

      // Navigate to lobby with game code from API
      context.go('/lobby/${response.code}', extra: {
        'playerName': _nameController.text.trim(),
        'playerId': response.playerId,
        'isHost': true,
        'config': config.toJson(),
        'isSoloMode': _isSoloMode,
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create game. Please try again.')),
      );
    }
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
                        onPressed: () {
                          // Use canPop to check if there's a screen to go back to
                          // If not (e.g., navigated via go() from results), go to home
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _modeTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _modeDescription,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
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

                    // Game Settings - only show for non-marathon modes
                    if (_showConfigOptions) ...[
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
                    ] else ...[
                      // Marathon mode info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.secondary),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 48,
                              color: AppTheme.bonusRank,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '26 Rounds',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Answer all 26 to complete the marathon.\nOne wrong answer ends your run!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // Create/Start button
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
                            : Text(_isSoloMode ? 'Start Game' : 'Create Game'),
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
