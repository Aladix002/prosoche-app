Nastavenia (/settings/*), push routy mimo shell. Vlastnik F-07.

- `settings_screen.dart` koren (A10.0), `*_settings_screen.dart` podobrazovky
  (A10.4 notifikacie, A10.5 jazyk, A10.6 zobrazenie, A10.9 sukromie).
- `sources_screen.dart` Zdroje a licencie (A11) z tabulky `source`,
  `about_screen.dart` O appke (A10.10).
- Modlitby a hijri kalendar dodava F-05, zalohu F-09.
- `blocking/` brana (B-03, len `FEATURE_GATE`): A10.1 prehlad, A10.2 detail
  appky, povolenia (zdielane s O6), pridanie appiek (picker zdielany s O5).
- `settings_providers.dart`: tema (`display.theme`), odkazy, zdroje, akcie
  (zmena prekladu, zmazanie dat).
