import 'dart:math';
import 'dart:ui';

class Utility{
  // Utility._();

  final _random = Random();

  Color getRandomColor() {
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );
  }
}