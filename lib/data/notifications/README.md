Notifikacie (P-02): NotificationService nad flutter_local_notifications.

- Plan robi lib/domain/notifications (NotificationPlanner, 10 dni, max 64).
- Preplanovanie: start a resume (NotificationTriggers), zmena nastaveni,
  workmanager 12 h (NotificationBackground), po boote receiver pluginu.
- Presne alarmy len cez SCHEDULE_EXACT_ALARM, inak inexact fallback.
  USE_EXACT_ALARM nepouzivat.
- Zmena casovej zony pozastavi modlitby do confirmTimeZone().
- Overenie na emulatore: test/data/notifications/probe/.
