import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The clinic calendar is authoritative in Asia/Damascus and must not shift
/// when the device is configured for another timezone.
abstract final class ClinicClock {
  static const String timezoneName = 'Asia/Damascus';
  static bool _initialized = false;
  static late final tz.Location _damascus;

  static void _ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _damascus = tz.getLocation(timezoneName);
    _initialized = true;
  }

  static tz.TZDateTime now() {
    _ensureInitialized();
    return tz.TZDateTime.now(_damascus);
  }

  static tz.TZDateTime today() {
    final current = now();
    return tz.TZDateTime(_damascus, current.year, current.month, current.day);
  }
}
