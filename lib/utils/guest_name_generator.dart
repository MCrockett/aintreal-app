import 'dart:math';

/// Generates fun guest names like "SwiftPenguin42" or "BoldNoodle07"
class GuestNameGenerator {
  static final _random = Random();

  // Simple, readable adjectives
  static const _adjectives = [
    'Swift',
    'Bold',
    'Brave',
    'Clever',
    'Lucky',
    'Sneaky',
    'Zippy',
    'Mighty',
    'Fuzzy',
    'Witty',
    'Jolly',
    'Crafty',
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
  /// Example: "SwiftPenguin42", "BoldNoodle07"
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
