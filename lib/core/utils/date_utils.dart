class AppDateUtils {
  const AppDateUtils._();

  static bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(dueDate.year, dueDate.month, dueDate.day).isBefore(today);
  }
}
