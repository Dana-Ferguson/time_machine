// This file contains non-globalized text output.
// -- this is temporary code to be deleted later when we have a good globalization story.

import 'package:time_machine/time_machine.dart';

abstract class TextShim {
  static String toStringZonedDateTime(ZonedDateTime zdt) {
    var sb = new StringBuffer();

    sb..write(zdt.offsetDateTime)
      ..write(' ')
      ..write(zdt.zone);

    return sb.toString();
  }

  /*

  @private final YearMonthDayCalendar yearMonthDayCalendar;
  @private final int _nanosecondOfDay;
  @private final Offset _offset;

  */

  static String toStringOffsetDateTime(OffsetDateTime offsetDateTime) {
    var sb = new StringBuffer();

    sb//..write(offsetDateTime.yearMonthDayCalendar.toString())
      //..write(' ')
      ..write(offsetDateTime.localDateTime.toString())
      ..write(' ')
      ..write(offsetDateTime.offset.toString());

    return sb.toString();
  }

  static String toStringOffset(Offset offset) {
    if (offset.seconds % TimeConstants.secondsPerHour == 0) {
      return '${offset.seconds ~/ TimeConstants.secondsPerHour} offset-hours';
    }
    return '${offset.seconds} offset-seconds';
  }

  static String toStringLocalDateTime(LocalDateTime ldt) {
    return '${ldt.date} ${ldt.time}';
  }

  static String toStringLocalDate(LocalDate date) {
    return '${date.yearMonthDayCalendar.toString()}';
  }

  static String toStringLocalTime(LocalTime time) {
    return '${time.Hour}:${time.Minute}:${time.Second}';
  }

  static String toStringOffsetTime(OffsetTime offsetTime) {
    return '${offsetTime.TimeOfDay} ${offsetTime.offset}';
  }

  static String toStringOffsetDate(OffsetDate offsetDate) {
    return '${offsetDate.date} ${offsetDate.offset}';
  }

  static String toStringLocalInstant(LocalInstant localInstant) {
    var date = new LocalDate.fromDaysSinceEpoch(localInstant.DaysSinceEpoch);
    var utc = new LocalDateTime(date, LocalTime.FromNanosecondsSinceMidnight(localInstant.NanosecondOfDay));
    return utc.toString();
  }

  static String toStringInstant(Instant instant) {
    return '${instant.spanSinceEpoch.totalSeconds} seconds since epoch';
  }

  static String toStringInterval(Interval interval) {
    return '${interval.Start ?? 'noStart'} to ${interval.End ?? 'noEnd'}';
  }

  static String toStringDateInterval(DateInterval dateInterval) {
    String a = dateInterval.start.toString();
    String b = dateInterval.end.toString();
    return "[$a, $b]";
  }

}