import 'package:logging/logging.dart';

final Logger _log = new Logger('Carrot');

// Log Levels:
// FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT
void printAllLogs() {
  Logger.root.level = Level.CONFIG; // Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}

bool _isDartVM = null;
bool get isDartVM => _isDartVM ?? (_isDartVM = _checkForDartVM());

bool _checkForDartVM() {
  double n = 1.0;
  String s = n.toString();
  if (s == '1.0') return true;
  else if (s == '1') return false;

  _log.warning('Performed simple isDart (or JS) check and it did not turn out as expected. s == $s;');

  return false;
}