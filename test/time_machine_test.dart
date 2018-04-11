import 'dart:async';

import 'package:time_machine/time_machine.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/time_machine_timezones.dart';

void main() {
  test('InZone', () async => await InstantTests.InZone());


  return;
  test('calculate', () {
    // expect(calculate(), 42);

    MySpanTests.BasicSpanTests();
    // InstantTest.FromUtcNoSeconds();

    // InstantTest.MoreJulianDateConversions();

  });

  InstantTests.Test();
}

abstract class MySpanTests {
  static void BasicSpanTests() {
    var aSpan = new Span.complex(days: 11, nanoseconds: 2 * TimeConstants.nanosecondsPerDay);
    // print('aSpan.totalDays = ${aSpan.totalDays}');

    expect(aSpan.totalDays, 11+2);
  }
}

Matcher instantIsCloseTo(Instant value) => new InstantIsCloseTo(value, Span.epsilon);

class InstantIsCloseTo extends Matcher {
  final Instant _value;
  final Span _delta;

  const InstantIsCloseTo(this._value, this._delta);

  bool matches(item, Map matchState) {
    if (item is Instant) {
      var diff = (item > _value) ? item - _value : _value - item;
      // if (diff < 0) diff = -diff;
      return (diff <= _delta);
    } else {
      return false;
    }
  }

  Description describe(Description description) => description
      .add('a Instant value within ')
      .addDescriptionOf(_delta)
      .add(' of ')
      .addDescriptionOf(_value);

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is Instant) {
      var diff = (item > _value) ? item - _value : _value - item;
      // if (diff < Span.zero) diff = -diff;
      return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
    } else {
      return mismatchDescription.add(' not Instant');
    }
  }
}

abstract class InstantTests {
  static final Instant one = new Instant.untrusted(new Span(nanoseconds: 1));
  static final Instant threeMillion = new Instant.untrusted(new Span(nanoseconds: 3000000));
  static final Instant negativeFiftyMillion = new Instant.untrusted(new Span(nanoseconds: -50000000));

  // todo: will probably become a main();
  static void Test() {
    test('FromUtcNoSeconds', () => InstantTests.FromUtcNoSeconds());
    // test('MoreJulianDateConversions', () => InstantTests.MoreJulianDateConversions());
    test('InUtc', () => InstantTests.InUtc());
    test('WithOffset', () => InstantTests.WithOffset());
    test('FromTicksSinceUnixEpoch', () => InstantTests.FromTicksSinceUnixEpoch());
    test('FromUnixTimeMilliseconds_Valid', () => InstantTests.FromUnixTimeMilliseconds_Valid());
    test('FromUnixTimeMilliseconds_TooLarge', () => InstantTests.FromUnixTimeMilliseconds_TooLarge());
    test('FromUnixTimeMilliseconds_TooSmall', () => InstantTests.FromUnixTimeMilliseconds_TooSmall());
    test('FromUnixTimeSeconds_Valid', () => InstantTests.FromUnixTimeSeconds_Valid());
    test('FromUnixTimeSeconds_TooLarge', () => InstantTests.FromUnixTimeSeconds_TooLarge());
    test('FromUnixTimeSeconds_TooSmall', () => InstantTests.FromUnixTimeSeconds_TooSmall());

    // WithOffset_NonIsoCalendar
    test('InZone', () async => await InstantTests.InZone());
  }

  static void FromUtcNoSeconds()
  {
    Instant viaUtc = DateTimeZone.Utc.AtStrictly(new LocalDateTime.fromYMDHMS(2008, 4, 3, 10, 35, 0)).ToInstant();
    expect(viaUtc, new Instant.fromUtc(2008, 4, 3, 10, 35));
  }

  static void FromUtcWithSeconds()
  {
    Instant viaUtc = DateTimeZone.Utc.AtStrictly(new LocalDateTime.fromYMDHMS(2008, 4, 3, 10, 35, 23)).ToInstant();
    expect(viaUtc, new Instant.fromUtc(2008, 4, 3, 10, 35, 23));
  }

  
  static void InUtc()
  {
    ZonedDateTime viaInstant = new Instant.fromUtc(2008, 4, 3, 10, 35, 23).inUtc();
    ZonedDateTime expected = DateTimeZone.Utc.AtStrictly(new LocalDateTime.fromYMDHMS(2008, 4, 3, 10, 35, 23));
    expect(expected, viaInstant);
  }

  
  static Future InZone () async
  {
    // todo: this is absurd
    DateTimeZone london = await (await DateTimeZoneProviders.Tzdb)["Europe/London"];
    ZonedDateTime viaInstant = new Instant.fromUtc(2008, 6, 10, 13, 16, 17).InZone(london);

    // London is UTC+1 in the Summer, so the above is 14:16:17 local.
    LocalDateTime local = new LocalDateTime.fromYMDHMS(2008, 6, 10, 14, 16, 17);
    ZonedDateTime expected = london.AtStrictly(local);

    expect(expected, viaInstant);
  }

  
  static void WithOffset()
  {
    // Jon talks about Noda Time at Leetspeak in Sweden on October 12th 2013, at 13:15 UTC+2
    Instant instant = new Instant.fromUtc(2013, 10, 12, 11, 15);
    Offset offset = Offset.fromHours(2);
    OffsetDateTime actual = instant.WithOffset(offset);
    OffsetDateTime expected = new OffsetDateTime(new LocalDateTime.fromYMDHM(2013, 10, 12, 13, 15), offset);
    expect(expected, actual);
  }

  
  static void WithOffset_NonIsoCalendar()
  {
    // October 12th 2013 ISO is 1434-12-07 Islamic
    CalendarSystem calendar = CalendarSystem.GetIslamicCalendar(IslamicLeapYearPattern.Base15, IslamicEpoch.Civil);
    Instant instant = new Instant.fromUtc(2013, 10, 12, 11, 15);
    Offset offset = Offset.fromHours(2);
    OffsetDateTime actual = instant.WithOffset(offset, calendar);
    OffsetDateTime expected = new OffsetDateTime(new LocalDateTime.fromYMDHMC(1434, 12, 7, 13, 15, calendar), offset);
    expect(expected, actual);
  }

  
  static void FromTicksSinceUnixEpoch()
  {
    Instant instant = new Instant.fromUnixTimeTicks(12345);
    expect(12345, instant.toUnixTimeTicks());
  }

  
  static void FromUnixTimeMilliseconds_Valid()
  {
    Instant actual = new Instant.fromUnixTimeMilliseconds(12345);
    Instant expected = new Instant.fromUnixTimeTicks(12345 * TimeConstants.ticksPerMillisecond);
    expect(expected, instantIsCloseTo(actual));
  }

  
  static void FromUnixTimeMilliseconds_TooLarge()
  {
    expect(() => new Instant.fromUnixTimeMilliseconds(Utility.int64MaxValue ~/ 100), throwsException);
  }

  
  static void FromUnixTimeMilliseconds_TooSmall()
  {
    // expect(() => throw new Exception('boom'), throwsException);
    expect(new Instant.fromUnixTimeMilliseconds(Utility.int64MinValue ~/ 100), throwsException);
  }

  
  static void FromUnixTimeSeconds_Valid()
  {
    Instant actual = new Instant.fromUnixTimeSeconds(12345);
    Instant expected = new Instant.fromUnixTimeTicks(12345 * TimeConstants.ticksPerSecond);
    expect(expected, instantIsCloseTo(actual));
  }

  
  static void FromUnixTimeSeconds_TooLarge()
  {
    expect(() => new Instant.fromUnixTimeSeconds(Utility.int64MaxValue ~/ 1000000), throwsException);
  }

  
  static void FromUnixTimeSeconds_TooSmall()
  {
    expect(() => new Instant.fromUnixTimeSeconds(Utility.int64MinValue ~/ 1000000), throwsException);
  }

  static void MoreJulianDateConversions() {
    var cases = [
      // Gregorian calendar: 1957-10-04
      [2436116.31, 1957, 9, 21, 19, 26, 24, "Sample from Astronomical Algorithms 2nd Edition, chapter 7"],
      // Gregorian calendar: 2013-01-01
      [2456293.520833, 2012, 12, 19, 0, 30, 0, "Sample from Wikipedia"],
      [1842713.0, 333, 1, 27, 12, 0, 0, "Another sample from Astronomical Algorithms 2nd Edition, chapter 7"],
      [0.0, -4712, 1, 1, 12, 0, 0, "Julian epoch"]
    ];

    cases.forEach((t) => JulianDateConversions(t[0], t[1], t[2], t[3], t[4], t[5], t[6]));
  }

  static void JulianDateConversions(double julianDate, int year, int month, int day, int hour, int minute, int second)
  {
    print('TEST!');

    // When dealing with floating point binary data, if we're accurate to 50 milliseconds, that's fine...
    // (0.000001 days = ~86ms, as a guide to the scale involved...)
    Instant actual = new Instant.fromJulianDate(julianDate);
    Instant expected = new LocalDateTime.fromYMDHMSC(year, month, day, hour, minute, second, CalendarSystem.Julian).InUtc().ToInstant();

    // TimeConstants.julianEpoch + new Span.complex(days: julianDate);
    //print ('Juilian Epoch = ${TimeConstants.julianEpoch}');
    //print (new Span.complex(days: julianDate));
    var ldt2 = new LocalDateTime.fromYMDHMSC(year, month, day, hour, minute, second, CalendarSystem.Julian).WithOffset(Offset.zero);
    print('LocalDateTime2 = ${ldt2.DayOfYear} of ${ldt2.Year} :: ${ldt2.NanosecondOfDay} ?');


    // var ld = new LocalDateTime.fromYMDHMSC(year, month, day, hour, minute, second, CalendarSystem.Julian);
    var ldt = new LocalDateTime.fromYMDHMSC(year, month, day, hour, minute, second, CalendarSystem.Julian).InUtc();
    print('LocalDateTime = ${ldt.DayOfYear} of ${ldt.Year} :: ${ldt.NanosecondOfDay} ?');

    // ld.Sec
    int days = ldt.offsetDateTime.Calendar.GetDaysSinceEpoch(ldt.offsetDateTime.yearMonthDayCalendar.toYearMonthDay());
    print("The days = $days;");

    print('ldt.nano = ${ldt.offsetDateTime.NanosecondOfDay}');
    print ('ldt.offsetDateTime = ${ldt.offsetDateTime.NanosecondOfDay}');
    var ts = ldt.offsetDateTime.ToElapsedTimeSinceEpoch().totalSeconds;
    print('ts = $ts');
    var span = new Span.complex(seconds: ts);
    print('span = $span');
    var ldti = new Instant.untrusted(span); //  ldt.ToInstant();
    print('InstantSeconds = ${ldti.toUnixTimeSeconds()}');


    print('TEST!!!');

    // Assert.AreEqual(expected.toUnixTimeMilliseconds(), actual.toUnixTimeMilliseconds(), 50, "Expected $expected, was $actual");
    // Assert.AreEqual(julianDate, expected.toJulianDate(), 0.000001);
    print('${expected.toUnixTimeMilliseconds()} =?? ${actual.toUnixTimeMilliseconds()}');
    print('${julianDate} =?? ${expected.toJulianDate()}');

    expect(expected.toUnixTimeMilliseconds(), closeTo(actual.toUnixTimeMilliseconds(), 50), reason: "Expected $expected, was $actual");
    expect(julianDate, closeTo(expected.toJulianDate(), 0.000001));

    print('TEST!!!!!!');
  }
}