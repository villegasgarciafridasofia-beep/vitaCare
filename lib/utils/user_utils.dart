import 'dart:math';

class UserUtils {
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();

    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  static bool isOlderAdult(DateTime birthDate) {
    return calculateAge(birthDate) >= 60;
  }

  static String generateLinkCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    final code = List.generate(
      6,
          (_) => chars[random.nextInt(chars.length)],
    ).join();

    return 'VC-$code';
  }
}