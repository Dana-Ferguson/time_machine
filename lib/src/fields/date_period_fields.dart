// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_fields.dart';

/// All the period fields.
@internal
abstract class DatePeriodFields
{
  @internal static final IDatePeriodField daysField = new FixedLengthDatePeriodField(1);
  @internal static final IDatePeriodField weeksField = new FixedLengthDatePeriodField(7);
  @internal static final IDatePeriodField monthsField = new MonthsPeriodField();
  @internal static final IDatePeriodField yearsField = new YearsPeriodField();
}
