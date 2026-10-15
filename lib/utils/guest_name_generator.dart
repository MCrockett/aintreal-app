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
  static String generate() => _build(_random);

  /// A stable name for [seed] (e.g. a Firebase uid): the same seed always
  /// gives the same name, so an account without a display name keeps one
  /// leaderboard identity across launches.
  static String forSeed(String seed) {
    // Own FNV-1a hash: String.hashCode is not guaranteed stable across runs.
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return _build(Random(hash));
  }

  static String _build(Random random) {
    final adjective = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    // Avoid inappropriate numbers
    int num = random.nextInt(100);
    if (num == 69) num = random.nextInt(100);
    final number = num.toString().padLeft(2, '0');
    return '$adjective$noun$number';
  }
}
