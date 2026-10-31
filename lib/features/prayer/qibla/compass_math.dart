import 'dart:math' as math;

/// Azimut zariadenia z akcelerometra a magnetometra (stupne od magnetickeho
/// severu, v smere hodinovych ruciciek, 0..<360), ako Android
/// `SensorManager.getRotationMatrix` + `getOrientation`. Vrchna hrana
/// telefonu drzaneho na vysku je smer pohladu.
///
/// Null pri volnom pade alebo ked je magneticke pole rovnobezne s gravitaciou
/// (vektorovy sucin takmer nulovy).
double? headingFromSensors({
  required double ax,
  required double ay,
  required double az,
  required double mx,
  required double my,
  required double mz,
}) {
  final gNorm = math.sqrt(ax * ax + ay * ay + az * az);
  if (gNorm < 0.1) return null;
  var hx = my * az - mz * ay;
  var hy = mz * ax - mx * az;
  var hz = mx * ay - my * ax;
  final hNorm = math.sqrt(hx * hx + hy * hy + hz * hz);
  if (hNorm < 0.1) return null;
  hx /= hNorm;
  hy /= hNorm;
  hz /= hNorm;
  final gx = ax / gNorm;
  final gz = az / gNorm;
  final my2 = gz * hx - gx * hz;
  return normalizeDegrees(math.atan2(hy, my2) * 180 / math.pi);
}

/// Uhol do intervalu 0..<360.
double normalizeDegrees(double d) {
  final r = d % 360;
  return r < 0 ? r + 360 : r;
}

/// Najkratsie otocenie z [from] na [to] v stupnoch, -180..180 (kladne =
/// doprava, v smere hodinovych ruciciek).
double turnDelta(double from, double to) {
  final d = normalizeDegrees(to - from);
  return d > 180 ? d - 360 : d;
}

/// Sila magnetickeho pola Zeme je 25-65 uT; mimo toho je kompas rusenom
/// alebo nekalibrovany (Q-CALIBRATE).
bool magneticFieldPlausible(double mx, double my, double mz) {
  final b = math.sqrt(mx * mx + my * my + mz * mz);
  return b >= 20 && b <= 70;
}

/// Vyhladenie uhla (exponencialny filter po kruznici).
double smoothHeading(double? previous, double next, {double alpha = 0.2}) {
  if (previous == null) return next;
  return normalizeDegrees(previous + alpha * turnDelta(previous, next));
}
