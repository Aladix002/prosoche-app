Testy pre lib/domain/prayer. Struktura zrkadli lib/.

## Referencne tabulky (`reference/*.csv`)

Kazde CSV ma v hlavicke (`# kluc: hodnota`) zdroj, URL, datum stiahnutia,
polohu, metodu a toleranciu. Riadky: `date,fajr,sunrise,dhuhr,asr,maghrib,isha`
v lokalnom case mesta. `skip:` vynecha modlitbu (volitelne v rozsahu dni),
dovod je v `note:`.

| Subor | Zdroj | Typ |
|---|---|---|
| istanbul_diyanet | Diyanet (namazvakitleri.diyanet.gov.tr) | oficialny |
| jakarta_kemenag | Kemenag Bimas Islam cez zrkadlo api.myquran.com | oficialny |
| kuala_lumpur_jakim | JAKIM e-Solat, zona WLY01 | oficialny |
| sarajevo_vaktija | Islamska zajednica BiH (vaktija.ba) | oficialny, len fajr/dhuhr/asr |
| ostatne `*_aladhan` | AlAdhan API, metoda a pravidlo v hlavicke | verejny vypocet |

Pre Bratislavu, London, Mekku, Karachi, Lahore, Dhaku, Oslo a Reykjavik
sa oficialna strojovo citatelna tabulka nenasla, pouzity je AlAdhan.

Stiahnute 2026-10-29, testy bezia bez siete.
