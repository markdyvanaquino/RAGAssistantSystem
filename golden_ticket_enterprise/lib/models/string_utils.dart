
class StringUtils {
  static String limitWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  static String filterApiKey(String apiKey, {int showStart = 4, int showEnd = 4}) {
    if (apiKey.length <= showStart + showEnd) {
      return '*' * apiKey.length;
    }

    final start = apiKey.substring(0, showStart);
    final end = apiKey.substring(apiKey.length - showEnd);
    final hiddenLength = apiKey.length - showStart - showEnd;

    return '$start${'*' * hiddenLength}$end';
  }

}
