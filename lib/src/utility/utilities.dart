import 'dart:math' as math;
import 'package:logging/logging.dart';

// todo: should this be called Utility? or even be packaged like it is?
abstract class Utility {
  static final Logger _log = new Logger('Utility');

  // Log Levels:
  // FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT
  static void printAllLogs() {
    Logger.root.level = Level.CONFIG; // Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  static bool _isDartVM = null;
  static bool get isDartVM => _isDartVM ?? (_isDartVM = _checkForDartVM());
  static bool _checkForDartVM() {
    double n = 1.0;
    String s = n.toString();
    if (s == '1.0')
      return true;
    else if (s == '1') return false;

    _log.warning('Performed simple isDart (or JS) check and it did not turn out as expected. s == $s;');

    return false;
  }

  static int _intMaxValue = null;
  static int get intMaxValue => _intMaxValue ?? (_intMaxValue = _getIntMaxValue());
  static int _getIntMaxValue() {
    if (_isDartVM) return math.pow(2, 63);
    return math.pow(2, 52);
  }
}