import 'dart:math';

/// Generates AI-themed guest names like "BrAINyToaster42" or "ChAInedLlama07"
class GuestNameGenerator {
  static final _random = Random();

  // Adjectives with "AI" naturally embedded
  static const _adjectives = [
    'BrAINy',
    'GrAINy',
    'TrAIned',
    'ChAIned',
    'UnchAIned',
    'PAInted',
    'DetAIled',
    'ContAIned',
    'SustAIned',
    'CertAIn',
    'QuAInt',
    'MAIntAIned',
  ];

  // Funny/fun nouns
  static const _nouns = [
    'Bot',
    'Pixel',
    'Toaster',
    'Potato',
    'Noodle',
    'Banana',
    'Pickle',
    'Waffle',
    'Nugget',
    'Gremlin',
    'Goblin',
    'Wizard',
    'Pirate',
    'Ninja',
    'Llama',
    'Penguin',
    'Raccoon',
    'Walrus',
    'Muffin',
    'Taco',
  ];

  /// Generate a random guest name.
  /// Format: {Adjective}{Noun}{2-digit number}
  /// Example: "BrAINyToaster42", "ChAInedLlama07"
  static String generate() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final noun = _nouns[_random.nextInt(_nouns.length)];
    // Avoid inappropriate numbers
    int num = _random.nextInt(100);
    if (num == 69) num = _random.nextInt(100);
    final number = num.toString().padLeft(2, '0');
    return '$adjective$noun$number';
  }
}
