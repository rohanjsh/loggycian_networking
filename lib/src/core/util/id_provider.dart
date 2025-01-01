import 'dart:math' as math;

final class IdProvider {
  static final _random = math.Random.secure();
  static const _chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates an alphanumeric ID of specified length
  static String generateId([int length = 12]) {
    return List.generate(
      length,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }
}
