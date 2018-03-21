#https://github.com/unicode-cldr

Notes for the weak. CLDR is for the strong -- I must bridge the gap, so I can reach.

* cldr-numbers-modern
* cldr-numbers-full
    * currencies
    * numbers
        * timeSeparator and stuff; (*)
* cldr-localenames-modern
* cldr-localenames-full
    * languages
        *  "localeDisplayNames": { "languages": { "en-US": "American English" } }
    * localeDisplayNames
        * "localeDisplayNames": { "localeDisplayPattern": { } }
        * calendar names, 
    * scripts
        * "localeDisplayNames": {
                  "scripts": {
                    "Adlm": "Adlam",
    * territories
        * localeDisplayNames": {
                "territories": {
                  "001": "World"
    * variants.json
        * "localeDisplayNames": {
                  "variants": {
                    "1901": "Traditional German orthography",
* cldr-dates-modern
* cldr-dates-full
    * **ca-generic**
        * month formats
        * weekday formats
        * day periods
        * eras
        * date formats 
        * time formats 
        * datetime formats
        * interval formats
    * ca-gregorian
        * probably, actually the one we want (same as above, but gregorian)
    * dateFields
        * more date format information
    * timeZoneNames
        * names of all timezones        
* cldr-segments-modern
    * _tbd_ ?? unsure? == suppressions:  segmentations    
* cldr-core
    * aliases
        * oldName --> newName
    * calendarData
        * calendar start dates and eras
    * calendarPreferenceData
    * characterFallbacks
    * codeMappings
        * language code fallbacks?
    * currencyData
    * dayPeriods
    * gender
    * languageData
    * languageGroups
    * languageMatching
    * likelySubtags
    * measurementData
    * metaZones
        * This looks important but I don't fully get it
    * numberingSystems
    * ordinals
    * parentLocales
    * plurals
    * primaryZones
        * Maybe?
    * references
    * telephoneCodeData
    * territoryContainment
    * territoryInfo
    * timeData
        * format preferences
    * unitPreferenceData    
    * weekData
        * ordering rules (for days\periods?)
    * windowsZones
        * This is useful

**Don't need**
* cldr-rbnf -- RuleBasedNumberFormat
* cldr-units-modern
* cldr-units-full
* cldr-misc-modern
* cldr-misc-full
    * characters
      * contextTransforms
      * delimiters
      * layout
      * listPatterns
      * posix


**Calendars**
* cldr-cal-buddhist-modern
* cldr-cal-buddhist-full
* cldr-cal-chinese-modern
* cldr-cal-chinese-full
* cldr-cal-coptic-modern
* cldr-cal-coptic-full
* cldr-cal-dangi-modern
* cldr-cal-dangi-full
* cldr-cal-ethiopic-modern
* cldr-cal-ethiopic-full
* cldr-cal-hebrew-modern
* cldr-cal-hebrew-full
* cldr-cal-islamic-modern
* cldr-cal-islamic-full
* cldr-cal-indian-modern
* cldr-cal-indian-full
* cldr-cal-japanese-modern
* cldr-cal-japanese-full
* cldr-cal-persian-modern
* cldr-cal-persian-full
* cldr-cal-roc-modern
* cldr-cal-roc-full
