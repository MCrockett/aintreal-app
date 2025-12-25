import 'dart:math';

/// Generates AI-themed guest names like "GrAINyPixel42" or "NeurALNova07"
class GuestNameGenerator {
  static final _random = Random();

  // AI-themed adjectives (with "AI" embedded where possible)
  static const _adjectives = [
    'GrAINy',
    'BrAINy',
    'NeurAL',
    'DigitAL',
    'VirtuAL',
    'PixelAI',
    'CyberAI',
    'RobotAI',
    'SynthAI',
    'LogicAL',
    'BinAIry',
    'GlitchAI',
    'VectorAI',
    'TensorAI',
    'QuantAI',
  ];

  // Tech/AI-themed nouns
  static const _nouns = [
    'Bot',
    'Node',
    'Pixel',
    'Nova',
    'Core',
    'Byte',
    'Wave',
    'Pulse',
    'Spark',
    'Ghost',
    'Signal',
    'Matrix',
    'Cipher',
    'Nexus',
    'Glitch',
  ];

  /// Generate a random guest name.
  /// Format: {Adjective}{Noun}{2-digit number}
  /// Example: "GrAINyPixel42", "NeurALNova07"
  static String generate() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    final number = _random.nextInt(100).toString().padLeft(2, '0');
    return '$adjective$noun$number';
  }
}
