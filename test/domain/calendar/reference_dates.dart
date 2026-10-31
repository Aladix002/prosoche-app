/// Referencne datumy Umm al-Qura (gregoriansky den -> hijri datum).
///
/// Zdroj: kalendar Umm al-Qura (Saudska Arabia, KACST), prevzate cez Python
/// balik `hijridate` 2.6.0 (`Hijri(y, m, d).to_gregorian()`), ktory je
/// overeny proti archivu novin Umm al-Qura a datam KACST. Vygenerovane
/// 2026-10-29. Zaciatky Ramadanu sa zhoduju aj s verejne ohlasenymi
/// datumami (napr. 2020-04-24, 2023-03-23, 2024-03-11, 2026-02-18) a s
/// docs/03 5.3 (1. Ramadan 1448 ~ 2027-02-08, Eid al-Fitr ~ 2027-03-09).
///
/// Umm al-Qura je vypocitany kalendar; lokalne pozorovanie mesiaca sa moze
/// o den lisit (preto existuje offset -2..+2).
library;

/// (gregorian ISO, hijri rok, hijri mesiac, hijri den), komentar = event.
const umAlQuraReference = <(String, int, int, int)>[
  ('2020-04-24', 1441, 9, 1), // ramadan_start Fri
  ('2020-05-24', 1441, 10, 1), // eid_al_fitr Sun
  ('2020-07-30', 1441, 12, 9), // arafah Thu
  ('2020-07-31', 1441, 12, 10), // eid_al_adha Fri
  ('2020-08-20', 1442, 1, 1), // new_year Thu
  ('2020-08-29', 1442, 1, 10), // ashura Sat
  ('2021-04-13', 1442, 9, 1), // ramadan_start Tue
  ('2021-05-13', 1442, 10, 1), // eid_al_fitr Thu
  ('2021-07-19', 1442, 12, 9), // arafah Mon
  ('2021-07-20', 1442, 12, 10), // eid_al_adha Tue
  ('2021-08-09', 1443, 1, 1), // new_year Mon
  ('2021-08-18', 1443, 1, 10), // ashura Wed
  ('2022-04-02', 1443, 9, 1), // ramadan_start Sat
  ('2022-05-02', 1443, 10, 1), // eid_al_fitr Mon
  ('2022-07-08', 1443, 12, 9), // arafah Fri
  ('2022-07-09', 1443, 12, 10), // eid_al_adha Sat
  ('2022-07-30', 1444, 1, 1), // new_year Sat
  ('2022-08-08', 1444, 1, 10), // ashura Mon
  ('2023-03-23', 1444, 9, 1), // ramadan_start Thu
  ('2023-04-21', 1444, 10, 1), // eid_al_fitr Fri
  ('2023-06-27', 1444, 12, 9), // arafah Tue
  ('2023-06-28', 1444, 12, 10), // eid_al_adha Wed
  ('2023-07-19', 1445, 1, 1), // new_year Wed
  ('2023-07-28', 1445, 1, 10), // ashura Fri
  ('2024-03-11', 1445, 9, 1), // ramadan_start Mon
  ('2024-04-10', 1445, 10, 1), // eid_al_fitr Wed
  ('2024-06-15', 1445, 12, 9), // arafah Sat
  ('2024-06-16', 1445, 12, 10), // eid_al_adha Sun
  ('2024-07-07', 1446, 1, 1), // new_year Sun
  ('2024-07-16', 1446, 1, 10), // ashura Tue
  ('2025-03-01', 1446, 9, 1), // ramadan_start Sat
  ('2025-03-30', 1446, 10, 1), // eid_al_fitr Sun
  ('2025-06-05', 1446, 12, 9), // arafah Thu
  ('2025-06-06', 1446, 12, 10), // eid_al_adha Fri
  ('2025-06-26', 1447, 1, 1), // new_year Thu
  ('2025-07-05', 1447, 1, 10), // ashura Sat
  ('2026-02-18', 1447, 9, 1), // ramadan_start Wed
  ('2026-03-20', 1447, 10, 1), // eid_al_fitr Fri
  ('2026-05-26', 1447, 12, 9), // arafah Tue
  ('2026-05-27', 1447, 12, 10), // eid_al_adha Wed
  ('2026-06-16', 1448, 1, 1), // new_year Tue
  ('2026-06-25', 1448, 1, 10), // ashura Thu
  ('2027-02-08', 1448, 9, 1), // ramadan_start Mon
  ('2027-03-09', 1448, 10, 1), // eid_al_fitr Tue
  ('2027-05-15', 1448, 12, 9), // arafah Sat
  ('2027-05-16', 1448, 12, 10), // eid_al_adha Sun
  ('2027-06-06', 1449, 1, 1), // new_year Sun
  ('2027-06-15', 1449, 1, 10), // ashura Tue
  ('2028-01-28', 1449, 9, 1), // ramadan_start Fri
  ('2028-02-26', 1449, 10, 1), // eid_al_fitr Sat
  ('2028-05-04', 1449, 12, 9), // arafah Thu
  ('2028-05-05', 1449, 12, 10), // eid_al_adha Fri
  ('2028-05-25', 1450, 1, 1), // new_year Thu
  ('2028-06-03', 1450, 1, 10), // ashura Sat
  ('2029-01-16', 1450, 9, 1), // ramadan_start Tue
  ('2029-02-14', 1450, 10, 1), // eid_al_fitr Wed
  ('2029-04-23', 1450, 12, 9), // arafah Mon
  ('2029-04-24', 1450, 12, 10), // eid_al_adha Tue
  ('2029-05-14', 1451, 1, 1), // new_year Mon
  ('2029-05-23', 1451, 1, 10), // ashura Wed
  ('2030-01-05', 1451, 9, 1), // ramadan_start Sat
  ('2030-02-04', 1451, 10, 1), // eid_al_fitr Mon
  ('2030-04-12', 1451, 12, 9), // arafah Fri
  ('2030-04-13', 1451, 12, 10), // eid_al_adha Sat
  ('2030-05-03', 1452, 1, 1), // new_year Fri
  ('2030-05-12', 1452, 1, 10), // ashura Sun
  ('2030-12-26', 1452, 9, 1), // ramadan_start Thu
];

/// Ramadan dlzky (29/30) podla toho isteho zdroja, rok -> pocet dni.
const ramadanLengths = <int, int>{
  1441: 30,
  1442: 30,
  1443: 30,
  1444: 29,
  1445: 30,
  1446: 29,
  1447: 30,
  1448: 29,
  1449: 29,
  1450: 29,
  1451: 30,
  1452: 29,
};
