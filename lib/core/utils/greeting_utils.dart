class GreetingUtils {
  GreetingUtils._();

  static String greetingFor(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  static String greetingEmojiFor(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return '🌤️';
    if (hour >= 12 && hour < 17) return '☀️';
    if (hour >= 17 && hour < 21) return '🌆';
    return '🌙';
  }
}
