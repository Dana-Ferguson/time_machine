// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:time_machine/src/fields/time_machine_fields.dart';

/// All the period fields.
@isInternal
abstract class DatePeriodFields
{
  static final IDatePeriodField daysField = FixedLengthDatePeriodField(1);
  static final IDatePeriodField weeksField = FixedLengthDatePeriodField(7);
  static final IDatePeriodField monthsField = MonthsPeriodField();
  static final IDatePeriodField yearsField = YearsPeriodField();
}
