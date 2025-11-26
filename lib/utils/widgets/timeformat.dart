class TimeUtils {
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    // Agar 7 din se zyada purana hai to date dikhao
    return '${timestamp.day}/${timestamp.month}';
  }
}
