# Changelog

## 0.2.2

- Fixed bug introduced in 0.2.1; (Conditional Imports are hard); `dart.library.js` seems to evaluate to false in DDC stable.
  Put back as `dart.library.html`.

## 0.2.1

- Fixed bug introduced in 0.2.0 causing TimeMachine.Initialize() to not fully await.

## 0.2.0

- No more specific imports for your platform. Flutter usage was streamlined significantly.

## 0.1.1

- Broke some things while making this work on many platforms. Fixed them (still need to do unit tests on js).

## 0.1.0

- Made some changes to try and less confuse Pana.

## 0.0.4

- Now works on Flutter, Web, and VM!

## 0.0.2

- Many things have been Dartified. Constructors consolidated, names are lowercased, @private usage heavily reduced.

## 0.0.1

- Initial version.
