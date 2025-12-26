import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/game_api.dart';
import '../../core/auth/session_provider.dart';
import '../../widgets/gradient_background.dart';

/// Screen for joining an existing game with a code.
class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key, this.initialCode});

  /// Optional code from deep link.
  final String? initialCode;

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _codeFocusNode = FocusNode();

  bool _isJoining = false;
  bool _isGuest = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Get name from session
    final session = ref.read(sessionProvider);
    if (session is SessionGuest) {
      _nameController.text = session.guestName;
      _isGuest = true;
    } else if (session is SessionAuthenticated) {
      _nameController.text = session.displayName;
    }

    // Pre-fill code from deep link
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim().toUpperCase();

    try {
      final response = await GameApi.instance.joinGame(
        code: code,
        playerName: _nameController.text.trim(),
      );

      if (!mounted) return;

      // Navigate to lobby with data from API
      context.go('/lobby/$code', extra: {
        'playerName': _nameController.text.trim(),
        'playerId': response.playerId,
        'isHost': false,
        'config': response.gameState.config.toJson(),
      });
    } on GameNotFoundException {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'Game not found. Check the code and try again.';
      });
    } on GameFullException {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'Game is full (max 8 players).';
      });
    } on GameAlreadyStartedException {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'Game has already started.';
      });
    } on NameTakenException {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'That name is already taken.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'Failed to join. Please try again.';
      });
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
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Join Game',
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
                    const SizedBox(height: 20),

                    // Name display (read-only for guests)
                    Text(
                      'Your Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isGuest) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.secondary, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _nameController.text,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Playing as guest',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        maxLength: 20,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _codeFocusNode.requestFocus();
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Game code input
                    Text(
                      'Game Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      decoration: InputDecoration(
                        hintText: 'ABCD',
                        counterText: '',
                        errorText: _errorMessage,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                        UpperCaseTextFormatter(),
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _joinGame(),
                      validator: (value) {
                        if (value == null || value.trim().length != 4) {
                          return 'Enter the 4-letter code';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // Help text
                    Text(
                      'Ask the host for the 4-letter game code',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Join button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _isJoining ? null : _joinGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isJoining
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Join Game'),
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
}

/// Converts text to uppercase as it's typed.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
