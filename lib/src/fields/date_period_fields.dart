// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Fields/DatePeriodFields.cs
// a209e60  on Mar 18, 2015

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_fields.dart';

/// All the period fields.
@internal abstract class DatePeriodFields
{
  @internal static final IDatePeriodField DaysField = new FixedLengthDatePeriodField(1);
  @internal static final IDatePeriodField WeeksField = new FixedLengthDatePeriodField(7);
  @internal static final IDatePeriodField MonthsField = new MonthsPeriodField();
  @internal static final IDatePeriodField YearsField = new YearsPeriodField();
}