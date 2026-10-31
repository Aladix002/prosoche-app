/// Repozitare a Riverpod providery pre obrazovky (D-02). Obrazovky
/// importuju len tento subor; fake implementacie su v `test/fakes/`.
library;

export 'package:sakina/data/repositories/calendar/calendar_repository.dart';
export 'package:sakina/data/repositories/cards/card_actions_repository.dart';
export 'package:sakina/data/repositories/cards/card_content_repository.dart';
export 'package:sakina/data/repositories/cards/hadith_extra_repository.dart';
export 'package:sakina/data/repositories/infra/databases.dart';
export 'package:sakina/data/repositories/infra/time_providers.dart';
export 'package:sakina/data/repositories/prayer/city_repository.dart';
export 'package:sakina/data/repositories/prayer/prayer_repository.dart';
export 'package:sakina/data/repositories/providers.dart';
export 'package:sakina/data/repositories/quran/quran_repository.dart';
export 'package:sakina/data/repositories/settings/drift_settings_repository.dart';
export 'package:sakina/data/repositories/settings/settings_providers.dart';
export 'package:sakina/data/repositories/today/daily_set_repository.dart';
export 'package:sakina/data/repositories/today/quest_repository.dart';
export 'package:sakina/data/repositories/today/streak_repository.dart';
