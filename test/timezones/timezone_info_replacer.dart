// https://github.com/nodatime/nodatime/blob/master/src/NodaTime.Test/TimeZones/TimeZoneInfoReplacer.cs
// 407f018  on Aug 31, 2017

import 'dart:async';
import 'dart:math' as math;

import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine_utilities.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

import '../time_machine_testing.dart';

/// Class used to temporarily replace the shim used by [TimeZoneInfoInterceptor],
/// for test purposes. On disposal, the original is restored.
Future main() async {
  await runTests();
}

internal class TimeZoneInfoReplacer extends TimeZoneInfo TimeZoneInfoInterceptor // .ITimeZoneInfoShim
{
final TimeZoneInfoInterceptor.ITimeZoneInfoShim originalShim;
final ReadOnlyCollection<TimeZoneInfo> zones;

TimeZoneInfo Local; //{ get; }

/*private*/ TimeZoneInfoReplacer(TimeZoneInfo local, ReadOnlyCollection<TimeZoneInfo> zones)
{
originalShim = TimeZoneInfoInterceptor.Shim;
Local = local;
this.zones = zones;
TimeZoneInfoInterceptor.Shim = this;

}

internal static IDisposable Replace(TimeZoneInfo local, params TimeZoneInfo[] allZones) =>
new TimeZoneInfoReplacer(local, allZones.ToList().AsReadOnly());

TimeZoneInfo FindSystemTimeZoneById(string id)
{
var zone = zones.FirstOrDefault(z => z.Id == id);
if (zone != null)
{
return zone;
}
// TimeZoneNotFoundException doesn't exist in netstandard. We're unlikely to use
// this method in non-NET45 tests anyway, as it's only used in BclDateTimeZoneSource.
throw new Exception("No such time zone: $id");
}

ReadOnlyCollection<TimeZoneInfo> GetSystemTimeZones() => zones;

void Dispose() => TimeZoneInfoInterceptor.Shim = originalShim;
}

