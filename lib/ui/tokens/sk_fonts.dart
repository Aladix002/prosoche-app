/// Rodiny fontov pribalenych v `assets/fonts/` (docs/01 2.3.1, PLAN U-01).
///
/// Ziadne runtime stahovanie (offline a sukromie). Ziadny KFGQPC.
abstract final class SkFonts {
  /// UI latinka (EN, ID, TR).
  static const inter = 'Inter';

  /// Citanie prekladu a dlhsich textov.
  static const literata = 'Literata';

  /// Iba text Koranu (Uthmani). Nesubsetuje sa.
  static const amiriQuran = 'AmiriQuran';

  /// Arabcina mimo Koranu (hadis, dua, mena) a arabske UI.
  static const notoNaskhArabic = 'NotoNaskhArabic';

  /// Urdcina (Nastaliq) - vyssia vyska riadku.
  static const notoNastaliqUrdu = 'NotoNastaliqUrdu';

  /// Bengalcina.
  static const notoSansBengali = 'NotoSansBengali';

  /// Fallback pre UI text: `ﷺ` a arabske/bengalske slova v latinskej vete.
  static const List<String> uiFallback = [notoNaskhArabic, notoSansBengali];

  /// Adresare v `assets/fonts/` s `OFL.txt` (pre `LicenseRegistry`).
  static const Map<String, String> licenseDirs = {
    'Inter': 'inter',
    'Literata': 'literata',
    'Amiri Quran': 'amiri_quran',
    'Noto Naskh Arabic': 'noto_naskh_arabic',
    'Noto Nastaliq Urdu': 'noto_nastaliq_urdu',
    'Noto Sans Bengali': 'noto_sans_bengali',
  };
}
