import 'package:adhan_dart/adhan_dart.dart' as adhan;

/// Azimut qibly (smer ku Kabe) v stupnoch od severu v smere hodinovych
/// ruciciek, 0 az < 360. Pocita sa po velkej kruznici (adhan_dart).
double qiblaBearing(double lat, double lng) =>
    adhan.Qibla.qibla(adhan.Coordinates(lat, lng));
