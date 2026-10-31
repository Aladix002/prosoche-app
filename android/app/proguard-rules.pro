# R8 pravidla pre release build (docs/06 B.5).
# Flutter Gradle plugin pridava vlastne pravidla pre embedding, pluginy
# (jni, jni_flutter, Gson pre flutter_local_notifications) maju consumer
# rules v AAR. Sem patri len to, co chyba.

# Citatelne stack traces v Sentry/Play (mapping.txt + cisla riadkov).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter deferred components nepouzivame, Play Core triedy chybaju.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# flutter_local_notifications serializuje naplanovane notifikacie cez Gson
# (RuntimeTypeAdapterFactory) a modely cita reflexiou. Gson ma consumer
# rules, toto je poistka, aby po update pluginu neprestali chodit
# naplanovane notifikacie po reboote (ulozene JSON v shared prefs).
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Pigeon: generovane triedy sa volaju bez reflexie, netreba keep.
# Ak by nativny kod brany (src/full) pouzival reflexiu, pridat konkretne
# keep pravidla, napr.:
# -keep class app.mursa.blocker.model.** { *; }

# WorkManager / Room maju consumer rules v AAR. Nic navyse.
