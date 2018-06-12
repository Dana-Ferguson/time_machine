// todo: Should this be an internal only meta-file?
// with a separate public only file later

export 'src/calendars/gj_yearmonthday_calculator.dart';
export 'src/calendars/gregorian_yearmonthday_calculator.dart';
export 'src/calendars/julian_yearmonthday_calculator.dart';
export 'src/calendars/regular_yearmonthday_calculator.dart';
export 'src/calendars/year_start_cache_entry.dart';
export 'src/calendars/yearmonthday_calculator.dart';
export 'src/calendars/single_era_calculator.dart';
export 'src/calendars/gj_era_calculator.dart';
export 'src/calendars/era_calculator.dart';
export 'src/calendars/era.dart';

export 'src/calendars/i_week_rule.dart';
export 'src/calendars/week_year_rules.dart';
export 'src/calendars/simple_week_year_rule.dart';

import 'time_machine.dart';
import 'src/calendars/gregorian_yearmonthday_calculator.dart';
import 'src/utility/preconditions.dart';

// from CalendarSystem.cs
YearMonthDayCalendar GetYearMonthDayCalendarFromDaysSinceEpoch(int daysSinceEpoch)
{
  var gregorianCalculator = new GregorianYearMonthDayCalculator();
  var minDays = gregorianCalculator.getStartOfYearInDays(gregorianCalculator.minYear);
  var maxDays = gregorianCalculator.getStartOfYearInDays(gregorianCalculator.maxYear);

  Preconditions.checkArgumentRange('daysSinceEpoch', daysSinceEpoch, minDays, maxDays);

  return gregorianCalculator.getYearMonthDayFromDaysSinceEpoch(daysSinceEpoch).withCalendarOrdinal(CalendarOrdinal.gregorian);
}