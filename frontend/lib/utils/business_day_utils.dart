class BusinessDayUtils {
  /// Returns the business date for a given time (normalized to 00:00:00).
  /// If the time is before 06:00 AM, it's considered part of the previous day's shift.
  static DateTime getBusinessDayFor(DateTime time) {
    if (time.hour < 6) {
      return DateTime(time.year, time.month, time.day).subtract(const Duration(days: 1));
    }
    return DateTime(time.year, time.month, time.day);
  }

  /// Returns the current business date based on the system time (normalized to 00:00:00).
  static DateTime getBusinessDay() {
    return getBusinessDayFor(DateTime.now());
  }
}
