import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/game_api.dart';
import '../../core/auth/session_provider.dart';
import '../../utils/guest_name_generator.dart';
import '../../widgets/gradient_background.dart';

/// Screen for joining an existing game with a code.
class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key, this.initialCode});

  /// Optional code from deep link or push notification.
  final String? initialCode;

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _codeFocusNode = FocusNode();

  bool _isJoining = false;
  bool _isGuest = false;
  String? _selectedName;
  String? _authenticatedName;
  List<String> _nameChoices = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _populateNameFromSession();

    ref.listenManual<SessionState>(sessionProvider, (previous, next) {
      if (_selectedName == null && _nameChoices.isEmpty) {
        _populateNameFromSession();
      }
    });

    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!.toUpperCase();
    }
  }

  void _populateNameFromSession() {
    final session = ref.read(sessionProvider);
    final playerName = ref.read(playerNameProvider);
    if (session is SessionGuest) {
      _isGuest = true;
      _generateNameChoices();
    } else if (session is SessionAuthenticated) {
      _authenticatedName = playerName ?? session.displayName;
      _selectedName = _authenticatedName;
    }
  }

  void _generateNameChoices() {
    final names = <String>{};
    while (names.length < 3) {
      names.add(GuestNameGenerator.generate());
    }
    setState(() {
      _nameChoices = names.toList();
      _selectedName = null;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    if (_selectedName == null || _selectedName!.trim().isEmpty) {
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a name first')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim().toUpperCase();
    final playerName = _selectedName!.trim();

    final session = ref.read(sessionProvider);
    if (session is! SessionGuest && session is! SessionAuthenticated) {
      try {
        await ref.read(sessionProvider.notifier).startGuestSession(playerName);
      } catch (e) {
        debugPrint('JoinGameScreen: Failed to create guest session (non-fatal): $e');
      }
    }

    try {
      String? idToken;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          idToken = await currentUser.getIdToken();
          debugPrint('JoinGameScreen: Got idToken for user ${currentUser.uid}');
        }
      } catch (e) {
        debugPrint('JoinGameScreen: Failed to get idToken (non-fatal): $e');
      }

      final response = await GameApi.instance.joinGame(
        code: code,
        playerName: playerName,
        idToken: idToken,
      );

      if (!mounted) return;

      AnalyticsService.instance.logGameJoined(asHost: false);

      context.go('/lobby/$code', extra: {
        'playerName': playerName,
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
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
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

                    // Name section
                    Text(
                      'Your Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isGuest) ...[
                      // 3-choice name picker for guests
                      ..._nameChoices.map((name) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedName = name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedName == name
                                    ? AppTheme.primary
                                    : AppTheme.secondary,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: _selectedName == name
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                  ),
                                ),
                                if (_selectedName == name)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: AppTheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: _generateNameChoices,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Shuffle'),
                        ),
                      ),
                    ] else ...[
                      // Authenticated user - show their display name
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _authenticatedName ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
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
                        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                        UpperCaseTextFormatter(),
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _joinGame(),
                      validator: (value) {
                        if (value == null || value.trim().length != 4) {
                          return 'Enter the 4-character code';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Ask the host for the 4-character game code',
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
