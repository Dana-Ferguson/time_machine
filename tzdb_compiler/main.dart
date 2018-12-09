// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:io';

import 'package:time_machine/src/time_machine_internal.dart';

import 'compiler_options.dart';
import 'tzdb/tzdb_zone_info_compiler.dart';

/// Main entry point for the time zone information compiler. In theory we could support
/// multiple sources and formats but currently we only support one:
/// http://www.twinsun.com/tz/tz-link.htm. This system refers to it as TZDB.
/// This also requires a windowsZone.xml file from the Unicode CLDR repository, to
/// map Windows time zone names to TZDB IDs.

/// Runs the compiler from the command line.
///
/// <param name="arguments">The command line arguments. Each compiler defines its own.</param>
/// <returns>0 for success, non-0 for error.</returns>
main(List<String> args) {
  CompilerOptions options = CompilerOptions(args);

  var tzdbCompiler = new TzdbZoneInfoCompiler();
  var tzdb = tzdbCompiler.Compile(options.sourceDirectoryName);
  tzdb.logCounts();
  if (options.zoneId != null) {
    tzdb.generateDateTimeZone(options.zoneId);
    return 0;
  }

  var windowsZones = LoadWindowsZones(options, tzdb.version);
  if (options.windowsOverride != null) {
    var overrideFile = CldrWindowsZonesParser.parserStream(options.WindowsOverride);
    windowsZones = MergeWindowsZones(windowsZones, overrideFile);
  }
  LogWindowsZonesSummary(windowsZones);
  var writer = new TzdbStreamWriter();
  // todo: using (var stream = CreateOutputStream(options))
      {
    writer.Write(tzdb, windowsZones, NameIdMappingSupport.StandardNameToIdMap, stream);
  }

  if (options.outputFileName != null) {
    print("Reading generated data and validating...");
    var source = Read(options);
    source.validate();
  }
  return 0;
}

  /// <summary>
  /// Loads the best windows zones file based on the options. If the WindowsMapping option is
  /// just a straight file, that's used. If it's a directory, this method loads all the XML files
  /// in the directory (expecting them all to be mapping files) and then picks the best one based
  /// on the version of TZDB we're targeting - basically, the most recent one before or equal to the
  /// target version.
  /// </summary>
  WindowsZones LoadWindowsZones(CompilerOptions options, string targetTzdbVersion)
  {
    var mappingPath = options.WindowsMapping;
    if (File.Exists(mappingPath))
    {
      return CldrWindowsZonesParser.parserStream(mappingPath);
    }
    if (!Directory(mappingPath).existsSync())
    {
      throw new Exception("$mappingPath does not exist as either a file or a directory");
    }
    var xmlFiles = Directory.GetFiles(mappingPath, "*.xml");
    if (xmlFiles.Length == 0)
    {
      throw new Exception("$mappingPath does not contain any XML files");
    }
    var allFiles = xmlFiles
        .Select((file) => CldrWindowsZonesParser.parserStream(file))
        .OrderByDescending((zones) => zones.TzdbVersion)
        .ToList();

    var versions = String.join(", ", allFiles.Select((z) => z.TzdbVersion).ToArray());

    var bestFile = allFiles
        .where((zones) => (zones.tzdbVersion.compareTo(targetTzdbVersion)) <= 0)
        .FirstOrDefault();

    if (bestFile == null)
    {
    throw new Exception("No zones files suitable for version $targetTzdbVersion. Found versions targeting: [$versions]");
    }
    print("Picked Windows Zones with TZDB version ${bestFile.TzdbVersion} out of [$versions] as best match for $targetTzdbVersion");
    return bestFile;
  }

  void LogWindowsZonesSummary(WindowsZones windowsZones)
  {
    print("Windows Zones:");
    print("  Version: ${windowsZones.version}");
    print("  TZDB version: ${windowsZones.TzdbVersion}");
    print("  Windows version: ${windowsZones.WindowsVersion}");
    print("  ${windowsZones.MapZones.Count} MapZones");
    print("  ${windowsZones.PrimaryMapping.Count} primary mappings");
  }

  Stream CreateOutputStream(CompilerOptions options)
  {
    // If we don't have an actual file, just write to an empty stream.
    // That way, while debugging, we still get to see all the data written etc.
    if (options.outputFileName is null)
    {
      return new MemoryStream();
    }
    String file = Path.ChangeExtension(options.outputFileName, "nzd");
    return File.create(file);
  }

  TzdbDateTimeZoneSource Read(CompilerOptions options)
  {
    String file = Path.ChangeExtension(options.outputFileName, "nzd");
    // todo: using (var stream = File.OpenRead(file))
    {
    return TzdbDateTimeZoneSource.FromStream(stream);
    }
  }

  /// Merge two WindowsZones objects together. The result has versions present in override,
  /// but falling back to the original for versions absent in the override. The set of MapZones
  /// in the result is the union of those in the original and override, but any ID/Territory
  /// pair present in both results in the override taking priority, unless the override has an
  /// empty "type" entry, in which case the entry is removed entirely.
  ///
  /// While this method could reasonably be in WindowsZones class, it's only needed in
  /// TzdbCompiler - and here is as good a place as any.
  ///
  /// The resulting MapZones will be ordered by Windows ID followed by territory.
  /// </summary>
  /// <param name="windowsZones">The original WindowsZones</param>
  /// <param name="overrideFile">The WindowsZones to override entries in the original</param>
  /// <returns>A merged zones object.</returns>
  WindowsZones MergeWindowsZones(WindowsZones originalZones, WindowsZones overrideZones)
  {
    var version = overrideZones.version == "" ? originalZones.version : overrideZones.version;
    var tzdbVersion = overrideZones.TzdbVersion == "" ? originalZones.TzdbVersion : overrideZones.TzdbVersion;
    var windowsVersion = overrideZones.WindowsVersion == "" ? originalZones.WindowsVersion : overrideZones.WindowsVersion;

    // Work everything out using dictionaries, and then sort.
    var mapZones = originalZones.MapZones.ToDictionary((mz) => new { mz.WindowsId, mz.Territory });
    foreach (var overrideMapZone in overrideZones.MapZones)
    {
      var key = new { overrideMapZone.WindowsId, overrideMapZone.Territory };
  if (overrideMapZone.TzdbIds.Count == 0)
  {
  mapZones.Remove(key);
  }
  else
  {
  mapZones[key] = overrideMapZone;
  }
  }
  var mapZoneList = mapZones
      .OrderBy((pair) => pair.Key.WindowsId)
      .ThenBy((pair) => pair.Key.Territory)
      .Select((pair) => pair.Value)
      .ToList();
  return new WindowsZones(version, tzdbVersion, windowsVersion, mapZoneList);
  }