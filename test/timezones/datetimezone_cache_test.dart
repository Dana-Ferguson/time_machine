// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';

import '../time_machine_testing.dart';

late DateTimeZoneProvider tzdb;

/// Tests for DateTimeZoneCache.
Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  tzdb = await DateTimeZoneProviders.tzdb;
}

// void Construction_NullProvider()
// {
//   expect(() async => await DateTimeZoneCache.getCache(null), throwsArgumentError);
// }

// @Test()
// void InvalidSource_NullVersionId()
// {
//   var source = TestDateTimeZoneSource(['Test1', "Test2"])..versionId = null;
//   expect(DateTimeZoneCache.getCache(source), willThrow<InvalidDateTimeZoneSourceError>());
// }

// @Test()
// Future InvalidSource_NullIdSequence() async
// {
//   List<String> ids;
//   var source = TestDateTimeZoneSource(ids);
//   expect(DateTimeZoneCache.getCache(source), willThrow<InvalidDateTimeZoneSourceError>());
// }

// @Test()
// Future InvalidSource_ReturnsNullForAdvertisedId() async
// {
//   var source = NullReturningTestDateTimeZoneSource(['foo', "bar"]);
//   var cache = await DateTimeZoneCache.getCache(source);
//   expect(() => cache.getZoneOrNull('foo'), willThrow<InvalidDateTimeZoneSourceError>());
// }

// @Test()
// void InvalidProvider_NullIdWithinSequence()
// {
//   var source = TestDateTimeZoneSource(['Test1', null]);
//   expect(DateTimeZoneCache.getCache(source), willThrow<InvalidDateTimeZoneSourceError>());
// }

@Test()
Future CachingForPresentValues() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  var zone1a = await provider['Test1'];
  expect(zone1a, isNotNull);
  expect('Test1', source.LastRequestedId);

  // Hit up the cache (and thus the source) for Test2
  expect(await provider['Test2'], isNotNull);
  expect('Test2', source.LastRequestedId);

  // Ask for Test1 again
  var zone1b = await provider['Test1'];
  // We won't have consulted the source again
  expect('Test2', source.LastRequestedId);

  expect(identical(zone1a, zone1b), isTrue);
}

@Test()
Future SourceIsNotAskedForUtcIfNotAdvertised() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  var zone = await provider[IDateTimeZone.utcId];
  expect(zone, isNotNull);
  expect(source.LastRequestedId, isNull);
}

@Test()
Future SourceIsAskedForUtcIfAdvertised() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2", "UTC"]);
  var provider = await DateTimeZoneCache.getCache(source);
  var zone = await provider[IDateTimeZone.utcId];
  expect(zone, isNotNull);
  expect('UTC', source.LastRequestedId);
}

@Test()
Future SourceIsNotAskedForUnknownIds() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  // todo: was InvalidDateTimeZoneSourceError ... why did this change? -- the returned error still makes sense.
  expect(provider['Unknown'], willThrow<DateTimeZoneNotFoundError>());
  expect(source.LastRequestedId, isNull);
}

@Test()
Future UtcIsReturnedInIdsIfAdvertisedByProvider() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2", "UTC"]);
  var provider = await DateTimeZoneCache.getCache(source);
  expect(provider.ids.contains(IDateTimeZone.utcId), isTrue);
}

@Test()
Future UtcIsNotReturnedInIdsIfNotAdvertisedByProvider() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  expect(provider.ids.contains(IDateTimeZone.utcId), isFalse);
}

@Test()
Future FixedOffsetSucceedsWhenNotAdvertised() async
{
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  String id = 'UTC+05:30';
  DateTimeZone zone = await provider[id];
  expect(DateTimeZone.forOffset(Offset.hoursAndMinutes(5, 30)), zone);
  expect(id, zone.id);
  expect(source.LastRequestedId, isNull);
}

@Test()
Future FixedOffsetConsultsSourceWhenAdvertised() async
{
  String id = 'UTC+05:30';
  var source = TestDateTimeZoneSource(['Test1', "Test2", id]);
  var provider = await DateTimeZoneCache.getCache(source);
  DateTimeZone zone = await provider[id];
  expect(id, zone.id);
  expect(id, source.LastRequestedId);
}

@Test()
Future FixedOffsetUncached() async
{
  String id = 'UTC+05:26';
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  DateTimeZone zone1 = await provider[id];
  DateTimeZone zone2 = await provider[id];
  expect(identical(zone1, zone2), isFalse);
  expect(zone1, zone2);
}

@Test()
Future FixedOffsetZeroReturnsUtc() async
{
  String id = 'UTC+00:00';
  var source = TestDateTimeZoneSource(['Test1', "Test2"]);
  var provider = await DateTimeZoneCache.getCache(source);
  DateTimeZone zone = await provider[id];
  expect(DateTimeZone.utc, zone);
  expect(source.LastRequestedId, isNull);
}

@Test()
void Tzdb_Indexer_InvalidFixedOffset()
{
  expect(tzdb['UTC+5Months'], willThrow<DateTimeZoneNotFoundError>());
}

// @Test()
// Future NullIdRejected() async
// {
//   var provider = await DateTimeZoneCache.getCache(TestDateTimeZoneSource(['Test1', "Test2"]));
//   expect(provider[null], throwsArgumentError);
// }

@Test()
Future EmptyIdAccepted() async
{
  var provider = await DateTimeZoneCache.getCache(TestDateTimeZoneSource(['Test1', "Test2"]));
  expect(provider[''], willThrow<DateTimeZoneNotFoundError>());
}

@Test()
Future VersionIdPassThrough() async
{
  var provider = await DateTimeZoneCache.getCache(TestDateTimeZoneSource(['Test1', "Test2"])..versionId = Future(() => "foo"));
  expect('foo', provider.versionId);
}

@Test('Test for issue 7 in bug tracker')
Future Tzdb_IterateOverIds() async
{
  // According to bug, this would go bang
  int count = tzdb.ids.length;

  expect(count > 1, isTrue);
  int utcCount = tzdb.ids.where((id) => id == IDateTimeZone.utcId).length;
  expect(1, utcCount);
}

@Test()
Future Tzdb_Indexer_UtcId() async
{
  expect(DateTimeZone.utc, await tzdb[IDateTimeZone.utcId]);
}

@Test()
Future Tzdb_Indexer_AmericaLosAngeles() async
{
  const String americaLosAngeles = 'America/Los_Angeles';
  var actual = await tzdb[americaLosAngeles];
  expect(actual, isNotNull);
  expect(DateTimeZone.utc, isNot(actual));
  expect(americaLosAngeles, actual.id);
}

@Test()
Future Tzdb_Ids_All() async
{
  // todo: we don't have Utc in here.... is this what we want? Need to refer to our faux TZDB
  var actual = tzdb.ids;
  var actualCount = actual.length;
  expect(actualCount > 1, isTrue);
  var utc = actual.firstWhere((id) => id == IDateTimeZone.utcId);
  expect(IDateTimeZone.utcId, utc);
}

/// Simply tests that every ID in the built-in database can be fetched. This is also
/// helpful for diagnostic debugging when we want to check that some potential
/// invariant holds for all time zones...
@Test()
void Tzdb_Indexer_AllIds()
{
  for (String id in tzdb.ids)
  {
    expect(tzdb[id], isNotNull);
  }
}

// @Test()
// Future GetSystemDefault_SourceReturnsNullId() async
// {
//   var source = NullReturningTestDateTimeZoneSource(['foo', "bar"]);
//   var cache = await DateTimeZoneCache.getCache(source);
//   expect(cache.getSystemDefault(), willThrow<DateTimeZoneNotFoundError>());
// }


class TestDateTimeZoneSource extends DateTimeZoneSource {
  String? LastRequestedId;
  final List<String> ids;

  TestDateTimeZoneSource(this.ids) {
    versionId = Future(() => 'test version');
  }

  @override
  Future<Iterable<String>>? getIds() => Future(() => ids);

  @override
  Future<DateTimeZone>? forId(String id) {
    return Future(() => forCachedId(id));
  }

  @override
  DateTimeZone forCachedId(String id) {
    LastRequestedId = id;
    return SingleTransitionDateTimeZone.withId(TimeConstants.unixEpoch, Offset.zero, Offset.hours(id.hashCode % 18), id);
  }

  @override
  late Future<String> versionId;

  @override
  String get systemDefaultId => 'map';
}

// A test source that returns null from ForId and GetSystemDefaultId()
// class NullReturningTestDateTimeZoneSource extends TestDateTimeZoneSource {
//   NullReturningTestDateTimeZoneSource(List<String> ids) : super(ids);

//   @override Future<DateTimeZone?> forId(String id) {
//     // Still remember what was requested.
//     // ignore: unused_local_variable
//     var _id = super.forId(id);
//     return Future(() => null);
//   }

//   @override String? get systemDefaultId => null;

//   @override DateTimeZone? forCachedId(String id) {
//     // ignore: unused_local_variable
//     var _id = super.forCachedId(id);
//     return null;
//   }
// }
