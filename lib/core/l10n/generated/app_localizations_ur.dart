// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String gatePauseTitle(String app) {
    return 'A pause before $app';
  }

  @override
  String get gatePauseTitleGeneric => 'A pause before this app';

  @override
  String gateSubtitle(int count, String app) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards, then $app opens.',
      one: '1 card, then $app opens.',
    );
    return '$_temp0';
  }

  @override
  String gateSubtitleGeneric(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards, then the app opens.',
      one: '1 card, then the app opens.',
    );
    return '$_temp0';
  }

  @override
  String gateProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get gateNext => 'Next';

  @override
  String gateDwellLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String gateDwellA11y(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Next card in $seconds seconds',
      one: 'Next card in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get gateBack => 'Go back';

  @override
  String get gateEmergency => 'Emergency';

  @override
  String gateEmergencyTitle(String app) {
    return 'Opening $app';
  }

  @override
  String get gateEmergencyTitleGeneric => 'Opening the app';

  @override
  String gateEmergencyBody(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Opening in $_temp0.';
  }

  @override
  String get gateEmergencyCancel => 'Cancel';

  @override
  String gateEmergencyA11yDialog(String app, int minutes) {
    return 'Open $app without cards? It opens in 10 seconds for $minutes minutes.';
  }

  @override
  String gateEmergencyA11yDialogGeneric(int minutes) {
    return 'Open the app without cards? It opens in 10 seconds for $minutes minutes.';
  }

  @override
  String gateUnlockedTitle(String app, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$app is open for $minutes minutes',
      one: '$app is open for 1 minute',
    );
    return '$_temp0';
  }

  @override
  String gateUnlockedTitleGeneric(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'The app is open for $minutes minutes',
      one: 'The app is open for 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get gateUnlockedBody => 'Use them well.';

  @override
  String get gateSetFinished => 'You finished today\'s set.';

  @override
  String gateContinueTo(String app) {
    return 'Continue to $app';
  }

  @override
  String get gateContinue => 'Continue';

  @override
  String gateUnlockedClose(String app) {
    return 'Close $app instead';
  }

  @override
  String get gateUnlockedCloseGeneric => 'Go to home screen';

  @override
  String get gateKeepReading => 'Keep reading';

  @override
  String get gateFreeReadingNote =>
      'Today\'s cards are done. Here are a few verses from where you left off.';

  @override
  String gatePrayerTitle(String prayer) {
    return 'It\'s time for $prayer';
  }

  @override
  String gatePrayerBody(String app) {
    return '$app will still be here after you pray.';
  }

  @override
  String get gatePrayerBodyGeneric =>
      'The app will still be here after you pray.';

  @override
  String get gatePrayerPray => 'I\'ll pray first';

  @override
  String get gatePrayerContinue => 'Show cards anyway';

  @override
  String get gateErrorTitle => 'We couldn\'t load your cards';

  @override
  String get gateErrorBody =>
      'This is our mistake, not yours. You can continue.';

  @override
  String get gateLoadingSlow => 'Still loading…';

  @override
  String gateEmpty(String app) {
    return 'Nothing to show right now. $app is open.';
  }

  @override
  String get gateEmptyGeneric => 'Nothing to show right now. The app is open.';

  @override
  String get blkAppsTitle => 'Which apps should wait?';

  @override
  String get blkAppsBody =>
      'When you open an app you choose, Mursa shows you a few cards first. After that, the app opens for a while. There\'s always an emergency way through, and you can turn it off anytime.';

  @override
  String get blkAppsSearch => 'Search apps';

  @override
  String get blkAppsSuggested => 'Often chosen';

  @override
  String get blkAppsAll => 'All apps';

  @override
  String get blkAppsEmpty => 'No apps found';

  @override
  String get blkAppsError => 'Couldn\'t load your apps.';

  @override
  String blkAppsCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Continue with $count apps',
      one: 'Continue with 1 app',
      zero: 'Continue without the gate',
    );
    return '$_temp0';
  }

  @override
  String blkAddCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count apps',
      one: 'Add 1 app',
      zero: 'Add apps',
    );
    return '$_temp0';
  }

  @override
  String get blkCardsLabel => 'Cards to unlock';

  @override
  String get blkMinutesLabel => 'Unlock for';

  @override
  String blkMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String blkDecrease(String what) {
    return 'Decrease $what';
  }

  @override
  String blkIncrease(String what) {
    return 'Increase $what';
  }

  @override
  String get blkPermTitle => 'Permissions for the gate';

  @override
  String get blkPermIntro =>
      'Mursa checks which app is open, only to show the gate. This never leaves your phone.';

  @override
  String get permUsageTitle => 'Usage access';

  @override
  String get permUsageBody =>
      'Mursa uses Usage Access to notice when you open one of the apps you chose for the gate, so it can show your cards first.';

  @override
  String get permUsageDoes =>
      'What Mursa does: checks which app is on screen, only while your screen is on.';

  @override
  String get permUsageNever =>
      'What Mursa never does: it doesn\'t store or send your app history, time spent, or anything you do inside other apps.';

  @override
  String get permUsageSteps =>
      'On the next screen, find Mursa and turn on \"Permit usage access\". Then come back.';

  @override
  String get permOverlayTitle => 'Display over other apps';

  @override
  String get permOverlayBody =>
      'This lets Mursa open its gate screen on top of the app you just opened.';

  @override
  String get permOverlayNever =>
      'What Mursa never does: read, record or change what\'s on your screen.';

  @override
  String get permNotifTitle => 'Notifications';

  @override
  String get permNotifBody =>
      'While the gate is on, Android shows a small, silent notification. It means Mursa is ready to pause the apps you chose.';

  @override
  String get permLocal =>
      'This stays on your phone and is not shared with anyone.';

  @override
  String get permAllow => 'Allow in settings';

  @override
  String get permGranted => 'On';

  @override
  String get permNotYet => 'Not allowed yet';

  @override
  String permStateLabel(String name, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'true': 'on',
      'other': 'off',
    });
    return '$name: $_temp0';
  }

  @override
  String get blkTurnOn => 'Turn on the gate';

  @override
  String get blkTurnOnFailed => 'The gate couldn\'t start. Please try again.';

  @override
  String get batteryTitle => 'Battery';

  @override
  String batteryVendorTitle(String manufacturer) {
    return 'Battery ($manufacturer)';
  }

  @override
  String get batteryGuide => 'Guide';

  @override
  String get batteryBodyGeneric =>
      'Some phones stop apps running in the background to save battery. If the gate stops appearing, allow Mursa to run in the background.';

  @override
  String batteryBodyVendor(String manufacturer) {
    return '$manufacturer phones often stop background apps. These steps keep the gate working:';
  }

  @override
  String get batteryStepsSamsung =>
      '1. Open battery settings below.\n2. Find Mursa and choose \"Unrestricted\".\n3. In Settings > Battery > Background usage limits, make sure Mursa is not in \"Sleeping apps\".';

  @override
  String get batteryStepsXiaomi =>
      '1. Open battery settings below.\n2. Find Mursa and choose \"No restrictions\".\n3. In the app info of Mursa, turn on \"Autostart\".';

  @override
  String get batteryStepsHuawei =>
      '1. Open battery settings below.\n2. Find Mursa in App launch and turn off \"Manage automatically\".\n3. Allow auto-launch and running in background.';

  @override
  String get batteryStepsOppo =>
      '1. Open battery settings below.\n2. Find Mursa and allow background activity.\n3. In the app info of Mursa, turn on \"Allow auto launch\".';

  @override
  String get batteryOpen => 'Open battery settings';

  @override
  String get batteryDone => 'I\'ve done this';

  @override
  String get batteryNote => 'Mursa uses very little battery.';

  @override
  String get blkTitle => 'The gate';

  @override
  String get blkSwitch => 'Pause before chosen apps';

  @override
  String get blkStatusRunning => 'Running';

  @override
  String get blkStatusOff => 'Off';

  @override
  String get blkStatusNoUsage => 'Paused - usage access missing';

  @override
  String get blkStatusNoOverlay =>
      'Paused - \"Display over other apps\" missing';

  @override
  String get blkStatusStopped => 'Paused - Android stopped the service';

  @override
  String get blkFix => 'Fix';

  @override
  String get blkPermissions => 'Permissions';

  @override
  String get blkPermissionsMissing => 'Some are off';

  @override
  String get blkPermissionsOk => 'All on';

  @override
  String get blkApps => 'Apps';

  @override
  String get blkAppsNone => 'No apps yet. Add the apps that should wait.';

  @override
  String get blkAddApps => 'Add apps';

  @override
  String blkAppSummary(int cards, String minutes, String prayer) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    String _temp1 = intl.Intl.selectLogic(prayer, {
      'true': ' · prayer reminder',
      'other': '',
    });
    return '$_temp0 · $minutes min$_temp1';
  }

  @override
  String get blkPrayerSection => 'Prayer reminder';

  @override
  String get blkPrayerHelp =>
      'For apps with prayer reminder on, the gate first reminds you of the prayer for this many minutes after its time begins. You can always continue.';

  @override
  String get blkPrayerMinutes => 'Remind for';

  @override
  String get blkStatsSection => 'Last 7 days';

  @override
  String get blkStatsHelp => 'Only on this phone.';

  @override
  String get blkStatsGates => 'Pauses';

  @override
  String get blkStatsCards => 'Opened after cards';

  @override
  String get blkStatsEmergency => 'Emergency';

  @override
  String get blkStatsError => 'Opened after an error';

  @override
  String get blkStatsEmpty => 'No pauses yet.';

  @override
  String blkStatsPerApp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unlocks',
      one: '1 unlock',
    );
    return '$_temp0';
  }

  @override
  String get blkLoadError => 'Couldn\'t load the gate settings.';

  @override
  String get blkAppPrayerLock => 'Prayer reminder';

  @override
  String get blkAppPrayerLockHelp =>
      'Around prayer times, the gate asks if you\'d like to pray first.';

  @override
  String get blkAppRemove => 'Remove from the gate';

  @override
  String blkAppRemoveTitle(String app) {
    return 'Remove $app?';
  }

  @override
  String get blkAppRemoveConfirm => 'Remove';

  @override
  String get blkAppNotFound => 'This app is no longer in the gate.';

  @override
  String get cardTranslationNotYetAvailable =>
      'Translation not yet available in your language';

  @override
  String get cardTranslatorNoteTitle => 'Translator\'s note';

  @override
  String cardTranslatorNoteA11y(String number) {
    return 'Translator\'s note $number';
  }

  @override
  String get cardHadithDownloadExplanations => 'Download explanations';

  @override
  String cardHadithGradeLabel(String grade) {
    String _temp0 = intl.Intl.selectLogic(grade, {
      'sahih': 'Sahih (authentic)',
      'hasan': 'Hasan (good)',
      'daif': 'Da\'if (weak)',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get cardHadithAgreedUpon => 'Agreed upon (Bukhari & Muslim)';

  @override
  String get cardHadithExplanationsFailed =>
      'Couldn\'t download explanations. Check your connection and try again.';

  @override
  String get cardHadithExplanationsRetry => 'Retry';

  @override
  String questGenericReadVerses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count verses',
      one: 'Read 1 verse',
    );
    return '$_temp0';
  }

  @override
  String questGenericLearnWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Learn $count new words',
      one: 'Learn 1 new word',
    );
    return '$_temp0';
  }

  @override
  String questGenericLearnCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count hadith or dua cards',
      one: 'Read 1 hadith or dua card',
    );
    return '$_temp0';
  }

  @override
  String get shellSettings => 'Settings';

  @override
  String onbStepProgress(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get onbBack => 'Back';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbWelcomeBody =>
      'A few quiet minutes with the Quran each day. Then you\'re done.';

  @override
  String get onbWelcomeNote =>
      'No account. No ads. Your data stays on this phone.';

  @override
  String get onbLanguageTitle => 'Choose your language';

  @override
  String get onbLanguageBody => 'You can change this later in Settings.';

  @override
  String onbLanguageName(String lang) {
    String _temp0 = intl.Intl.selectLogic(lang, {
      'en': 'English',
      'ar': 'العربية',
      'id': 'Bahasa Indonesia',
      'ur': 'اردو',
      'bn': 'বাংলা',
      'tr': 'Türkçe',
      'other': '$lang',
    });
    return '$_temp0';
  }

  @override
  String get onbTranslationLabel => 'Quran translation';

  @override
  String get onbTranslationNone =>
      'No translation is available for this language yet.';

  @override
  String get onbFatalTitle => 'Something went wrong';

  @override
  String get onbFatalBody => 'Please reinstall the app.';

  @override
  String get onbNiyyahTitle => 'Why are you here?';

  @override
  String get onbNiyyahBody =>
      'Choose what matters to you. You can pick more than one. It stays on this phone.';

  @override
  String onbNiyyahOption(String option) {
    String _temp0 = intl.Intl.selectLogic(option, {
      'khatm': 'Read the Quran regularly',
      'arabic': 'Understand Quranic Arabic',
      'prayer': 'Pray on time',
      'less_social': 'Spend less time scrolling',
      'other': 'Write my own',
    });
    return '$_temp0';
  }

  @override
  String get onbNiyyahOwnHint => 'In your own words';

  @override
  String get onbLocationTitle => 'Prayer times for where you are';

  @override
  String get onbLocationBody =>
      'Prayer times are calculated on your phone. Your location is rounded to about 1 km and never leaves your device.';

  @override
  String get onbLocationGps => 'Use my location';

  @override
  String get onbLocationCity => 'Choose a city instead';

  @override
  String get onbLocationFinding => 'Finding your location…';

  @override
  String get onbLocationDenied => 'Location is off. Choose your city instead.';

  @override
  String get onbLocationFailed =>
      'Couldn\'t get your location. Choose your city instead.';

  @override
  String get onbLocationNoCity =>
      'No city found nearby. Choose your city instead.';

  @override
  String get onbCitySearchHint => 'Search for a city';

  @override
  String get onbCitySearchEmpty => 'No city found. Try a nearby larger city.';

  @override
  String get onbCitySearchError => 'Cities could not be loaded.';

  @override
  String onbMethodBody(String country) {
    return 'We picked the method most often used in $country. If your local mosque uses another, choose it here.';
  }

  @override
  String get onbMethodLabel => 'Calculation method';

  @override
  String onbMethodName(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'muslimWorldLeague': 'Muslim World League',
      'northAmerica': 'ISNA (North America)',
      'egyptian': 'Egyptian General Authority',
      'ummAlQura': 'Umm al-Qura, Makkah',
      'karachi': 'University of Islamic Sciences, Karachi',
      'turkiye': 'Diyanet, Türkiye',
      'indonesian': 'Kemenag, Indonesia',
      'singapore': 'MUIS, Singapore',
      'dubai': 'Dubai',
      'qatar': 'Qatar',
      'kuwait': 'Kuwait',
      'gulfRegion': 'Gulf region',
      'algerian': 'Algeria',
      'morocco': 'Morocco',
      'tunisia': 'Tunisia',
      'jordan': 'Jordan',
      'france': 'UOIF, France',
      'portugal': 'Portugal',
      'russia': 'Spiritual Administration, Russia',
      'tehran': 'Institute of Geophysics, Tehran',
      'jafari': 'Shia Ithna Ashari (Jafari)',
      'moonsightingCommittee': 'Moonsighting Committee',
      'jakim': 'JAKIM, Malaysia',
      'other': '$method',
    });
    return '$_temp0';
  }

  @override
  String get onbAsrLabel => 'Asr time';

  @override
  String get onbAsrShafi => 'Standard (Shafi\'i, Maliki, Hanbali)';

  @override
  String get onbAsrHanafi => 'Hanafi';

  @override
  String get onbHighLatNote =>
      'In summer, Isha and Fajr can be hard to calculate this far north. We use: Middle of the night. You can change this later in Settings.';

  @override
  String get onbTodayTimes => 'Today';

  @override
  String get onbNotifTitle => 'Gentle reminders';

  @override
  String get onbNotifBody =>
      'Get a quiet notice at each prayer time and one in the morning when your cards are ready. Nothing else.';

  @override
  String get onbNotifPrayers => 'Prayer times (5 a day)';

  @override
  String get onbNotifPrayersNoLocation => 'Set your location first';

  @override
  String onbNotifMorning(String time) {
    return 'Morning reminder at $time';
  }

  @override
  String get onbNotifPrivate => 'Private text on lock screen';

  @override
  String get onbNotifAllow => 'Allow notifications';

  @override
  String get onbNotifOn => 'Notifications are on';

  @override
  String get onbNotifDenied =>
      'Notifications are off. You can turn them on anytime in Settings.';

  @override
  String get onbOpenSettings => 'Open settings';

  @override
  String get onbExactTitle => 'On-time prayer reminders';

  @override
  String get onbExactBody =>
      'To remind you at the exact minute, Android needs \"Alarms & reminders\" to be allowed. Without it, reminders may arrive up to 10 minutes late or more.';

  @override
  String get onbExactCta => 'Allow in settings';

  @override
  String get onbPrivacyTitle => 'Your data stays here';

  @override
  String get onbPrivacyPoint1 => 'No account. No ads.';

  @override
  String get onbPrivacyPoint2 =>
      'Prayers, reading and progress never leave this phone.';

  @override
  String get onbAgeConfirm => 'I am 16 or older';

  @override
  String get onbAgeNote => 'Sharing is available only if you are 16 or older.';

  @override
  String get onbAnalyticsTitle => 'Help improve the app?';

  @override
  String get onbAnalyticsBody =>
      'Share anonymous usage, like which screens are used. Never your prayers, your reading, your location, or which apps you use.';

  @override
  String get onbAnalyticsYes => 'Share';

  @override
  String get onbAnalyticsNo => 'Don\'t share';

  @override
  String get onbCrashTitle => 'Send crash reports?';

  @override
  String get onbCrashBody =>
      'If the app crashes, send a technical report without your content.';

  @override
  String get onbCrashYes => 'Send';

  @override
  String get onbCrashNo => 'Don\'t send';

  @override
  String get onbWhatWeCollect => 'What we collect';

  @override
  String get onbWhatWeCollectBody =>
      'Only if you choose to share: anonymous events such as \"onboarding finished\" or \"daily cards completed\", the app version and the language. Never what you read or pray, your location, or which apps you use.';

  @override
  String get onbPrivacyNote =>
      'You can change this anytime in Settings > Privacy.';

  @override
  String get onbFinish => 'Finish';

  @override
  String get todaySettings => 'Settings';

  @override
  String get todayCalendarHint => 'Open the calendar';

  @override
  String todayHijriDate(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String todayHijriMonth(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Muharram',
      'm2': 'Safar',
      'm3': 'Rabi al-Awwal',
      'm4': 'Rabi al-Thani',
      'm5': 'Jumada al-Ula',
      'm6': 'Jumada al-Akhirah',
      'm7': 'Rajab',
      'm8': 'Shaban',
      'm9': 'Ramadan',
      'm10': 'Shawwal',
      'm11': 'Dhul Qadah',
      'm12': 'Dhul Hijjah',
      'other': '-',
    });
    return '$_temp0';
  }

  @override
  String todayNextPrayer(String prayer, String duration) {
    return '$prayer in $duration';
  }

  @override
  String todayPrayerNow(String prayer) {
    return '$prayer now';
  }

  @override
  String todayDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String todayDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get todaySetLocation => 'Set your location to see prayer times';

  @override
  String get todayQuestsTitle => 'Today\'s intentions';

  @override
  String get todayQuestSlotRead => 'Read';

  @override
  String get todayQuestSlotLearn => 'Learn';

  @override
  String get todayQuestSlotAct => 'Today\'s deed';

  @override
  String get todayQuestMarked => 'Marked as done.';

  @override
  String get todayQuestSkip => 'Skip for today';

  @override
  String get todayCtaBegin => 'Begin today\'s cards';

  @override
  String todayCtaBeginCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String todayCtaContinue(int done, int total) {
    return 'Continue · $done of $total';
  }

  @override
  String get todayCtaComplete => 'Today\'s cards are complete';

  @override
  String get todayCtaReadQuran => 'Read the Quran';

  @override
  String todayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String todayGraceDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grace days',
      one: '1 grace day',
      zero: 'no grace days left',
    );
    return '$_temp0';
  }

  @override
  String todayNiyyah(String text) {
    return '“$text”';
  }

  @override
  String get feedErrorTitle => 'Today\'s cards didn\'t load';

  @override
  String get feedErrorBody => 'Please try again. Your progress is safe.';

  @override
  String get feedClose => 'Close';

  @override
  String get feedBackToToday => 'Back to Today';

  @override
  String get feedTakeAMoment => 'Take a moment';

  @override
  String get feedSwipeUp => 'Swipe up for the next card';

  @override
  String get feedNextCard => 'Next card';

  @override
  String get feedPreviousCard => 'Previous card';

  @override
  String feedCardPosition(int n, int total) {
    return 'Card $n of $total';
  }

  @override
  String get feedCardErrorTitle => 'This card didn\'t load';

  @override
  String get feedSkipCard => 'Skip this card';

  @override
  String get feedNewDayTitle => 'A new day has started';

  @override
  String get feedNewDayBody => 'Continue yesterday\'s cards or start today\'s?';

  @override
  String get feedNewDayContinue => 'Continue yesterday\'s';

  @override
  String get feedNewDayToday => 'Start today\'s';

  @override
  String get cardTypeVerse => 'VERSE';

  @override
  String get cardTypeHadith => 'HADITH';

  @override
  String get cardTypeDua => 'DUA';

  @override
  String get cardTypeName => 'NAME OF ALLAH';

  @override
  String get cardTypeReflection => 'REFLECTION';

  @override
  String get cardTypeEvent => 'SPECIAL DAY';

  @override
  String get cardTypeFreeReading => 'FREE READING';

  @override
  String cardEyebrow(String type, String context) {
    return '$type · $context';
  }

  @override
  String cardAyahReference(String surah, String ref) {
    return '$surah $ref';
  }

  @override
  String cardAyahA11y(String surah, String ayah) {
    return '$surah, verse $ayah';
  }

  @override
  String get cardSave => 'Save';

  @override
  String get cardUnsave => 'Remove from saved';

  @override
  String get cardSaved => 'Saved';

  @override
  String get cardRemoved => 'Removed from saved';

  @override
  String get cardShare => 'Share';

  @override
  String get cardMore => 'More options';

  @override
  String cardTranslationLabel(String translator) {
    return 'Translation: $translator';
  }

  @override
  String get cardFallbackTag => 'EN';

  @override
  String get cardFallbackA11y => 'English translation';

  @override
  String get cardNoTranslation => 'Translation not available in your language';

  @override
  String get cardReadInContext => 'Read in context';

  @override
  String cardSourceRef(String source) {
    return 'Source: $source';
  }

  @override
  String cardHadithReference(String collection, String number) {
    return '$collection $number';
  }

  @override
  String cardHadithGrade(String grade) {
    return 'Grade: $grade';
  }

  @override
  String cardHadithGradeName(String grade) {
    String _temp0 = intl.Intl.selectLogic(grade, {
      'sahih': 'Sahih',
      'hasan': 'Hasan',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get cardHadithExplanation => 'Explanation';

  @override
  String cardDuaRepeat(int count) {
    return '×$count';
  }

  @override
  String cardDuaCounter(int n, int total) {
    return '$n / $total';
  }

  @override
  String get cardDuaCounterHint => 'Count a repetition';

  @override
  String cardNameIndex(String n) {
    return '$n of 99';
  }

  @override
  String cardNameMentionedIn(String ref) {
    return 'Mentioned in $ref';
  }

  @override
  String get cardOpen => 'Open';

  @override
  String get cardReflectionAttribution => 'Mursa reflection · reviewed';

  @override
  String cardEventSurah(String surah, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$surah · $_temp0';
  }

  @override
  String cardEventReadSurah(String surah) {
    return 'Read $surah';
  }

  @override
  String cardIntroEstimate(int count, int minutes) {
    return 'Today: $count cards · ~$minutes min';
  }

  @override
  String cardIntroQuests(String slots) {
    return 'Your intentions: $slots';
  }

  @override
  String cardIntroMoreEvents(int count) {
    return '+$count more';
  }

  @override
  String get cardSheetCopy => 'Copy text';

  @override
  String get cardSheetShareImage => 'Share as image';

  @override
  String get cardSheetShareText => 'Share as text';

  @override
  String get cardSheetSource => 'Show source';

  @override
  String get cardSheetReport => 'Report a problem';

  @override
  String get cardCopied => 'Copied';

  @override
  String get cardTooLongForImage =>
      'Too long for an image. Share as text instead.';

  @override
  String get cardSourceTitle => 'Source';

  @override
  String cardSourceLicense(String license) {
    return 'License: $license';
  }

  @override
  String cardShareVia(String appName) {
    return 'via $appName';
  }

  @override
  String get doneTitle => 'You\'re done for today';

  @override
  String doneSummary(int cards, int verses) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    String _temp1 = intl.Intl.pluralLogic(
      verses,
      locale: localeName,
      other: '$verses verses',
      one: '1 verse',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String doneQuests(int done, int total) {
    return 'Intentions: $done of $total';
  }

  @override
  String doneNextPrayer(String prayer, String time) {
    return 'Next: $prayer at $time';
  }

  @override
  String get doneClosed => 'The cards are closed until tomorrow.';

  @override
  String get doneKeepReading => 'Keep reading the Quran';

  @override
  String doneCountedFor(String weekday) {
    return 'Counted for $weekday';
  }

  @override
  String doneOpenDeed(String title) {
    return 'Still open: $title';
  }

  @override
  String get khatmTitle => 'You completed the Quran.';

  @override
  String khatmNumber(int n) {
    return 'Completion #$n';
  }

  @override
  String get khatmStartAgain => 'Start again from the beginning';

  @override
  String get quranSearchTooltip => 'Search the Quran';

  @override
  String quranContinue(String reference) {
    return 'Continue: $reference';
  }

  @override
  String quranStartReading(String reference) {
    return 'Start reading: $reference';
  }

  @override
  String quranLastOpened(String reference) {
    return 'Last opened: $reference';
  }

  @override
  String get quranTabSurahs => 'Surahs';

  @override
  String get quranTabJuz => 'Juz';

  @override
  String quranJuzTitle(String number) {
    return 'Juz $number';
  }

  @override
  String get quranRevelationMeccan => 'Meccan';

  @override
  String get quranRevelationMedinan => 'Medinan';

  @override
  String quranAyahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$_temp0';
  }

  @override
  String quranProgressRead(String percent) {
    return '$percent read';
  }

  @override
  String quranSurahNumber(String number) {
    return 'Surah $number';
  }

  @override
  String quranJuzPage(String juz, String page) {
    return 'Juz $juz · Page $page';
  }

  @override
  String get quranTextSettings => 'Text settings';

  @override
  String get quranArabicSize => 'Arabic text size';

  @override
  String get quranArabicSizeS => 'S';

  @override
  String get quranArabicSizeM => 'M';

  @override
  String get quranArabicSizeL => 'L';

  @override
  String get quranArabicSizeXL => 'XL';

  @override
  String get quranShowTranslation => 'Show translation';

  @override
  String get quranTranslationSource => 'Translation';

  @override
  String quranTranslationOfMeaning(String name) {
    return 'Translation of meaning: $name';
  }

  @override
  String quranTranslationVersion(String version, String attribution) {
    return 'Version $version · $attribution';
  }

  @override
  String get quranTranslationMissing =>
      'Translation not available in your language';

  @override
  String get quranTranslationFallbackTag => 'EN';

  @override
  String get quranTranslationFallbackLabel => 'English translation';

  @override
  String get quranFootnotesShow => 'Translator\'s notes';

  @override
  String get quranFootnotesHide => 'Hide notes';

  @override
  String get quranSajda => 'Prostration verse';

  @override
  String get quranVerseActions => 'Verse actions';

  @override
  String get quranCopy => 'Copy';

  @override
  String get quranCopied => 'Verse copied';

  @override
  String get quranSave => 'Save';

  @override
  String get quranRemoveSaved => 'Remove from saved';

  @override
  String quranShareVia(String appName) {
    return 'via $appName';
  }

  @override
  String quranNextSurah(String name) {
    return 'Next: $name';
  }

  @override
  String get quranBackToSurahs => 'Back to surahs';

  @override
  String get quranVerseNotFound => 'That verse could not be found.';

  @override
  String get quranKhatmTitle => 'You completed the Quran';

  @override
  String quranKhatmStartAgain(String name) {
    return 'Start again from $name';
  }

  @override
  String quranAyahSemantics(String surah, String ayah) {
    return 'Surah $surah, verse $ayah';
  }

  @override
  String get quranSearchHint => 'Word, surah or 2:255';

  @override
  String get quranSearchTips => 'Try a word like \'mercy\' or a surah name.';

  @override
  String quranSearchEmptyTitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get quranSearchEmptyBody =>
      'Try another word, a surah name or a number like 2:255.';

  @override
  String get quranSearchErrorTitle => 'Search isn\'t working right now';

  @override
  String get quranSearchErrorBody => 'Please try again.';

  @override
  String quranGoTo(String reference) {
    return 'Go to $reference';
  }

  @override
  String get quranSearchVerses => 'Verses';

  @override
  String get quranClearSearch => 'Clear';

  @override
  String get quranBack => 'Back';

  @override
  String get quranClose => 'Close';

  @override
  String prayerTimeName(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'other': 'Prayer',
    });
    return '$_temp0';
  }

  @override
  String get prayerQiblaTooltip => 'Qibla direction';

  @override
  String get prayerCalendarTooltip => 'Islamic calendar';

  @override
  String get prayerSettingsTooltip => 'Prayer settings';

  @override
  String get prayerPreviousDay => 'Previous day';

  @override
  String get prayerNextDay => 'Next day';

  @override
  String prayerInHoursMinutes(int hours, int minutes) {
    return 'in $hours h $minutes min';
  }

  @override
  String prayerInMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String prayerAdjustedLabel(String value) {
    return '$value min';
  }

  @override
  String prayerInfoLine(String method, String asr, String adjust) {
    return '$method · Asr $asr · $adjust';
  }

  @override
  String get prayerInfoNoAdjust => 'no adjustments';

  @override
  String prayerInfoAdjusted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times adjusted',
      one: '1 time adjusted',
    );
    return '$_temp0';
  }

  @override
  String get prayerLocationChange => 'Change location';

  @override
  String get prayerLocationTitle => 'Set your location';

  @override
  String get prayerLocationBody =>
      'Prayer times are calculated on your phone for where you are.';

  @override
  String get prayerUseMyLocation => 'Use my location';

  @override
  String get prayerChooseCity => 'Choose a city';

  @override
  String get prayerNoTimesHint =>
      'You can still log your prayers without times.';

  @override
  String get prayerErrorTitle => 'Prayer times couldn\'t be calculated';

  @override
  String get prayerErrorBody => 'Check your location and calculation method.';

  @override
  String get prayerIshaContinues => 'Isha time continues until Fajr';

  @override
  String get prayerTimeZoneTitle => 'New time zone detected';

  @override
  String get prayerTimeZoneBody => 'Update prayer times for where you are now?';

  @override
  String get prayerRemindersOffTitle => 'Prayer reminders are off';

  @override
  String get prayerRemindersOffBody =>
      'Turn on notifications to be reminded at each prayer time.';

  @override
  String get prayerRemindersTurnOn => 'Turn on';

  @override
  String get prayerExactInfo =>
      'Reminders may arrive up to 10 minutes late or more.';

  @override
  String get prayerExactAllow => 'Allow exact times';

  @override
  String get prayerEstimatedTitle => 'Estimated time';

  @override
  String prayerEstimatedBody(String prayer, String rule) {
    return 'On some nights the sun doesn\'t go low enough here to calculate $prayer. The time is estimated using: $rule.';
  }

  @override
  String get prayerEstimatedInfo => 'Why is this estimated?';

  @override
  String get prayerChangeRule => 'Change rule';

  @override
  String get prayerMarkOnTime => 'Mark on time';

  @override
  String get prayerMarkLate => 'Mark late';

  @override
  String get prayerMarkMissed => 'Mark missed';

  @override
  String get prayerMarkQada => 'Made up (qada)';

  @override
  String get prayerMarkQadaAction => 'Mark made up';

  @override
  String get prayerClearLog => 'Clear';

  @override
  String prayerLogCleared(String prayer) {
    return '$prayer log cleared.';
  }

  @override
  String get prayerFutureHint => 'You can log it after it begins.';

  @override
  String prayerUpdatedFor(String city) {
    return 'Prayer times updated for $city.';
  }

  @override
  String prayerMethodName(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'muslimWorldLeague': 'Muslim World League',
      'northAmerica': 'ISNA (North America)',
      'egyptian': 'Egyptian General Authority of Survey',
      'ummAlQura': 'Umm al-Qura, Makkah',
      'karachi': 'University of Islamic Sciences, Karachi',
      'turkiye': 'Diyanet (Türkiye)',
      'indonesian': 'Kemenag (Indonesia)',
      'singapore': 'MUIS (Singapore)',
      'dubai': 'Dubai',
      'qatar': 'Qatar',
      'kuwait': 'Kuwait',
      'gulfRegion': 'Gulf region',
      'algerian': 'Algeria',
      'morocco': 'Morocco',
      'tunisia': 'Tunisia',
      'jordan': 'Jordan',
      'france': 'France (UOIF)',
      'portugal': 'Portugal',
      'russia': 'Russia',
      'tehran': 'Institute of Geophysics, Tehran',
      'jafari': 'Shia Ithna Ashari (Jafari)',
      'moonsightingCommittee': 'Moonsighting Committee',
      'jakim': 'JAKIM (Malaysia)',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String prayerMethodAngles(String fajr, String isha) {
    return 'Fajr $fajr°, Isha $isha°';
  }

  @override
  String prayerMethodInterval(String fajr, String minutes) {
    return 'Fajr $fajr°, Isha $minutes min after Maghrib';
  }

  @override
  String get prayerMethodAutomatic => 'Automatic';

  @override
  String prayerMethodAutomaticFor(String method) {
    return 'Usual method for your location: $method';
  }

  @override
  String get prayerAsrShafi => 'Standard (Shafi\'i, Maliki, Hanbali)';

  @override
  String get prayerAsrHanafi => 'Hanafi';

  @override
  String get prayerAsrShortShafi => 'Shafi\'i';

  @override
  String get prayerAsrShortHanafi => 'Hanafi';

  @override
  String prayerHighLatName(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'middle_of_night': 'Middle of the night',
      'seventh_of_night': 'One seventh of the night',
      'twilight_angle': 'Twilight angle',
      'other': 'Automatic',
    });
    return '$_temp0';
  }

  @override
  String prayerHighLatDescription(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'middle_of_night': 'Fajr and Isha stay within the halves of the night.',
      'seventh_of_night': 'Isha at most one seventh of the night after Maghrib, Fajr at most one seventh before sunrise.',
      'twilight_angle': 'The night portion follows the angle of the method.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get prayerSettingsTitle => 'Prayer times';

  @override
  String get prayerSettingsLocation => 'Location';

  @override
  String get prayerSettingsMethod => 'Calculation method';

  @override
  String get prayerSettingsAsr => 'Asr';

  @override
  String get prayerSettingsHighLat => 'High latitude rule';

  @override
  String get prayerSettingsHighLatHelp =>
      'Used when the sun doesn\'t go low enough for Fajr or Isha.';

  @override
  String get prayerSettingsAdjust => 'Manual adjustments';

  @override
  String get prayerSettingsAdjustHelp =>
      'Move a time if your local mosque uses a different one.';

  @override
  String get prayerSettingsPreview => 'Today';

  @override
  String prayerAdjustMinutes(String value) {
    return '$value min';
  }

  @override
  String get prayerAdjustEarlier => 'Earlier by 1 minute';

  @override
  String get prayerAdjustLater => 'Later by 1 minute';

  @override
  String prayerAdjustSemantics(String prayer, String value) {
    return '$prayer adjustment, $value minutes';
  }

  @override
  String prayerMethodSuggestTitle(String method, String country) {
    return '$method is common in $country';
  }

  @override
  String get prayerMethodSuggestBody => 'Switch the calculation method?';

  @override
  String get prayerMethodSuggestSwitch => 'Switch';

  @override
  String prayerMethodSuggestKeep(String method) {
    return 'Keep $method';
  }

  @override
  String get citySearchTitle => 'Choose a city';

  @override
  String get citySearchHint => 'Search for a city';

  @override
  String get citySearchTips =>
      'Type the first letters of your city. The list works offline.';

  @override
  String citySearchEmptyTitle(String query) {
    return 'No cities found for \"$query\"';
  }

  @override
  String get citySearchEmptyBody =>
      'Check the spelling or try a bigger city nearby.';

  @override
  String get citySearchClear => 'Clear search';

  @override
  String citySearchCurrent(String city) {
    return 'Current: $city';
  }

  @override
  String get cityLocating => 'Finding your location…';

  @override
  String get cityLocationErrorTitle => 'We couldn\'t find your location';

  @override
  String get cityLocationErrorBody =>
      'Choose your city instead. It works just as well.';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String qiblaTurnRight(String degrees) {
    return 'Turn right $degrees°';
  }

  @override
  String qiblaTurnLeft(String degrees) {
    return 'Turn left $degrees°';
  }

  @override
  String get qiblaFacing => 'Facing the Qibla';

  @override
  String qiblaBearing(String degrees) {
    return 'Qibla $degrees° from north';
  }

  @override
  String get qiblaCalibrateTitle => 'Calibrating…';

  @override
  String get qiblaCalibrateBody => 'Move your phone in a figure 8.';

  @override
  String get qiblaNoSensorTitle => 'Compass not available';

  @override
  String qiblaNoSensorBody(String degrees) {
    return 'The Qibla is $degrees° from north.';
  }

  @override
  String get qiblaHint => 'Hold your phone flat, away from metal and magnets.';

  @override
  String qiblaDialSemantics(String degrees) {
    return 'Compass. Qibla is $degrees° from north.';
  }

  @override
  String qiblaFrom(String city) {
    return 'From $city';
  }

  @override
  String get qiblaNorth => 'N';

  @override
  String get calendarTitle => 'Islamic calendar';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarMonthTitle(String month, String year) {
    return '$month $year';
  }

  @override
  String get calendarEventsTitle => 'Events this month';

  @override
  String get calendarEmptyTitle => 'No special days this month';

  @override
  String calendarEmptyNext(String event, String date) {
    return 'Next: $event on $date.';
  }

  @override
  String get calendarErrorTitle => 'The calendar couldn\'t load';

  @override
  String get calendarErrorBody => 'Please try again.';

  @override
  String calendarOffsetLine(String offset) {
    return 'Hijri date offset: $offset';
  }

  @override
  String get calendarOffsetChange => 'Change';

  @override
  String get calendarOffsetTitle => 'Hijri date';

  @override
  String get calendarOffsetHelp =>
      'If your community began the month a day earlier or later, adjust the date here. Events move with it.';

  @override
  String calendarOffsetPreview(String date) {
    return 'Today is $date';
  }

  @override
  String calendarOffsetDays(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'p0': '0 days',
      'p1': '+1 day',
      'p2': '+2 days',
      'm1': '−1 day',
      'm2': '−2 days',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get calendarOffsetEarlier => 'One day earlier';

  @override
  String get calendarOffsetLater => 'One day later';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarHasEvents => 'has events';

  @override
  String get calendarDayEmpty => 'No special events on this day.';

  @override
  String get calendarEnglishTag => 'EN';

  @override
  String hijriDate(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String hijriMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Muharram',
      'm2': 'Safar',
      'm3': 'Rabi al-Awwal',
      'm4': 'Rabi al-Thani',
      'm5': 'Jumada al-Ula',
      'm6': 'Jumada al-Akhirah',
      'm7': 'Rajab',
      'm8': 'Sha\'ban',
      'm9': 'Ramadan',
      'm10': 'Shawwal',
      'm11': 'Dhu al-Qa\'dah',
      'm12': 'Dhu al-Hijjah',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get journeyTitle => 'My journey';

  @override
  String get journeyNiyyahEmpty => 'Add your intention';

  @override
  String get journeyNiyyahEdit => 'Edit intention';

  @override
  String get journeyNiyyahDialogTitle => 'Your intention';

  @override
  String get journeyNiyyahSave => 'Save';

  @override
  String get journeyNiyyahCancel => 'Cancel';

  @override
  String get journeyPreviousMonth => 'Previous month';

  @override
  String get journeyNextMonth => 'Next month';

  @override
  String journeyDayState(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': 'Completed',
      'grace': 'Covered by a grace day',
      'missed': 'Not completed',
      'excused': 'Excused',
      'today': 'Today',
      'future': 'Upcoming',
      'other': 'No record',
    });
    return '$_temp0';
  }

  @override
  String get journeyLegendDone => 'Completed';

  @override
  String get journeyLegendGrace => 'Grace day';

  @override
  String get journeyLegendMissed => 'Not completed';

  @override
  String journeyStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String journeyLongest(String count) {
    return 'Longest $count';
  }

  @override
  String journeyGraceLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grace days',
      one: '1 grace day',
      zero: 'no grace days left',
    );
    return '$_temp0';
  }

  @override
  String journeyGraceRefill(String date) {
    return 'Grace days refill on $date';
  }

  @override
  String get journeyEmptyTitle => 'Your journey starts today';

  @override
  String get journeyEmptyBody =>
      'Each day you complete your cards or an intention will appear here.';

  @override
  String get journeyErrorTitle => 'Something went wrong';

  @override
  String get journeyErrorBody => 'Your data is safe. Please try again.';

  @override
  String get journeyQuranTitle => 'Quran';

  @override
  String journeyQuranPercent(String percent) {
    return '$percent% read';
  }

  @override
  String get journeyQuranMapEmpty => 'Verses you read will fill this map.';

  @override
  String get journeyQuranMapLegend =>
      'Each square is a surah. The fuller it is, the more of it you have read.';

  @override
  String journeySurahProgress(String surah, String percent) {
    return '$surah, $percent% read';
  }

  @override
  String journeySurahFallback(String number) {
    return 'Surah $number';
  }

  @override
  String journeyKhatm(String count) {
    return 'Khatm: $count';
  }

  @override
  String journeyNextVerse(String ref) {
    return 'Next verse $ref';
  }

  @override
  String get journeyWords => 'Words';

  @override
  String journeySavedButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved cards ($count)',
      zero: 'Saved cards',
    );
    return '$_temp0';
  }

  @override
  String get journeySavedTitle => 'Saved cards';

  @override
  String journeySavedFilter(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'all': 'All',
      'ayah': 'Verses',
      'hadith': 'Hadith',
      'dua': 'Dua',
      'name': 'Names',
      'reflection': 'Reflections',
      'other': 'All',
    });
    return '$_temp0';
  }

  @override
  String journeyCardType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'ayah': 'Verse',
      'hadith': 'Hadith',
      'dua': 'Dua',
      'name': 'Name of Allah',
      'reflection': 'Reflection',
      'other': 'Card',
    });
    return '$_temp0';
  }

  @override
  String get journeySavedEmptyTitle => 'Nothing saved yet';

  @override
  String get journeySavedEmptyBody =>
      'Tap the bookmark on any card to keep it here.';

  @override
  String get journeySavedRemove => 'Remove';

  @override
  String get journeySavedRemoved => 'Removed from saved';

  @override
  String get journeyUndo => 'Undo';

  @override
  String get journeyClose => 'Close';

  @override
  String journeyCardPosition(String n, String total) {
    return '$n of $total';
  }

  @override
  String journeyDaySet(String done, String total) {
    return 'Daily cards: $done/$total';
  }

  @override
  String journeyDayCompletedAt(String time) {
    return 'Completed at $time';
  }

  @override
  String get journeyDayNoSet => 'No daily cards on this day.';

  @override
  String get journeyDayViewCards => 'View cards';

  @override
  String journeyDaySources(String source) {
    String _temp0 = intl.Intl.selectLogic(source, {
      'set': 'Daily cards completed',
      'quest': 'An intention completed',
      'other': '-',
    });
    return '$_temp0';
  }

  @override
  String get journeyDayPrayers => 'Prayers';

  @override
  String journeyPrayerStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'on_time': 'On time',
      'late': 'Late',
      'missed': 'Missed',
      'qada': 'Made up',
      'other': 'Not logged',
    });
    return '$_temp0';
  }

  @override
  String get setTitle => 'Settings';

  @override
  String get setGate => 'The gate';

  @override
  String setOnOff(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'true': 'On',
      'other': 'Off',
    });
    return '$_temp0';
  }

  @override
  String get setPrayerTimes => 'Prayer times';

  @override
  String get setNotifications => 'Notifications';

  @override
  String get setLanguage => 'Language & translation';

  @override
  String get setDisplay => 'Daily set & display';

  @override
  String get setAudio => 'Audio';

  @override
  String get setHijriCalendar => 'Hijri calendar';

  @override
  String get setPrivacy => 'Privacy';

  @override
  String get setSources => 'Sources & licenses';

  @override
  String get setAbout => 'About';

  @override
  String get setAppLanguage => 'App language';

  @override
  String get setDeviceLanguage => 'Phone language';

  @override
  String get setTranslation => 'Quran translation';

  @override
  String get setDisplayOptions => 'Display';

  @override
  String get setTranslit => 'Transliteration';

  @override
  String get setTranslitHelp => 'Show Arabic in Latin letters where available.';

  @override
  String get setTranslationArabic =>
      'In Arabic, the Quran is shown without a translation.';

  @override
  String get setTranslationNone =>
      'No translation is available in this language yet. English is shown instead.';

  @override
  String setSourceVersionLicense(String version, String license) {
    return 'Version $version · License: $license';
  }

  @override
  String get setTranslationDisclaimer =>
      'Translations convey the meanings of the Qur\'an; they are not the Qur\'an itself.';

  @override
  String get setLoadErrorTitle => 'Couldn\'t load this';

  @override
  String get setLoadErrorBody => 'Please try again.';

  @override
  String get setTheme => 'Theme';

  @override
  String get setHighContrastNote =>
      'High contrast follows your phone settings.';

  @override
  String setThemeName(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'light': 'Light',
      'dark': 'Dark',
      'other': 'Same as phone',
    });
    return '$_temp0';
  }

  @override
  String get setArabicSize => 'Arabic text size';

  @override
  String get setDailySet => 'Daily set';

  @override
  String get setSimpleMode => 'Simple mode';

  @override
  String get setSimpleModeHelp => 'Hide streaks and counters.';

  @override
  String get setCardsCount => 'Cards per day';

  @override
  String get setCardsCountHelp =>
      'Changes apply from tomorrow. Today\'s set stays the same.';

  @override
  String setCardsCountValue(int count) {
    return '$count cards';
  }

  @override
  String get setNotifBlocked => 'Notifications are blocked by Android.';

  @override
  String get setOpenSettings => 'Open settings';

  @override
  String get setPrayerReminders => 'Prayer reminders';

  @override
  String get setMorning => 'Morning';

  @override
  String get setMorningToggle => 'Morning reminder';

  @override
  String get setMorningHelp => 'A reminder that your daily cards are ready.';

  @override
  String get setMorningTime => 'Time';

  @override
  String get setLockScreen => 'Lock screen';

  @override
  String get setPrivateText => 'Private text';

  @override
  String get setPrivateTextHelp =>
      'Show only the app name and time on the lock screen, without what the reminder is about.';

  @override
  String get setExactAlarms => 'Exact reminders';

  @override
  String get setStatusUnknown => 'Checking…';

  @override
  String get setExactOn => 'Allowed';

  @override
  String get setExactOff => 'Not allowed';

  @override
  String get setExactHelp =>
      'Without exact reminders, prayer reminders may arrive up to 10 minutes late or more.';

  @override
  String get setAllow => 'Allow';

  @override
  String get setOsDelayNote =>
      'Reminders may be delayed by Android or battery settings.';

  @override
  String get setPrivacyIntro =>
      'Your prayers, reading and other logs stay on this phone. We do not receive them.';

  @override
  String get setSharing => 'Sharing';

  @override
  String get setSharingHelp =>
      'Both are off unless you turn them on. You can turn them off at any time.';

  @override
  String get setAnalytics => 'Anonymous usage';

  @override
  String get setCrashReports => 'Crash reports';

  @override
  String get setPrivacyPolicy => 'Privacy policy';

  @override
  String get setYourData => 'Your data';

  @override
  String get setYourDataHelp =>
      'Deleting removes everything you saved in the app and starts again from the beginning.';

  @override
  String get setDeleteAll => 'Delete all my data';

  @override
  String get setDeleteTitle => 'Delete all data?';

  @override
  String get setDeleteBody =>
      'Your logs, saved cards, settings and progress will be deleted from this phone. This can\'t be undone.';

  @override
  String setDeleteTypeLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get setDeleteConfirm => 'Delete';

  @override
  String get setSourcesIntro =>
      'Mursa shows these texts without any changes, as published by their sources.';

  @override
  String get setSourcesEmpty => 'No sources found';

  @override
  String setSourceKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'quran_text': 'Quran text',
      'quran_text_search': 'Quran text for search',
      'quran_metadata': 'Quran metadata',
      'translation': 'Translations of the meanings',
      'word': 'Word by word',
      'hadith': 'Hadith',
      'dua': 'Dua',
      'name': 'Names of Allah',
      'reflection': 'Reflections',
      'curated': 'Mursa content',
      'audio': 'Recitations',
      'city': 'Places',
      'font': 'Fonts',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String setContentVersion(String version) {
    return 'Content version $version';
  }

  @override
  String get setSourcesReport =>
      'If you notice an error in a text, please report it. We will review it and pass it on to the source.';

  @override
  String get setLicenseLink => 'License';

  @override
  String setLinkFailed(String url) {
    return 'Couldn\'t open $url';
  }

  @override
  String get setOpenSourceLicenses => 'Open-source licenses';

  @override
  String get setAppVersion => 'App version';

  @override
  String get setContentVersionTitle => 'Content version';

  @override
  String get setUnavailable => 'Unavailable';

  @override
  String get setDisclaimers => 'Please note';

  @override
  String get setDisclaimerPrayer =>
      'Prayer times are calculated on your device using the method you selected. Results can differ from your local mosque by several minutes, especially at high latitudes and around daylight saving changes. Please confirm times with your local mosque or Islamic authority and adjust them in Settings if needed. Reminders may be delayed by the operating system or battery settings.';

  @override
  String get setDisclaimerQuran =>
      'The Arabic text of the Qur\'an is the Tanzil Uthmani text (Tanzil Project, tanzil.net), shown without any modification. Translations convey the meanings of the Qur\'an; they are not the Qur\'an itself.';

  @override
  String get setDisclaimerRulings =>
      'Mursa is a reminder and habit tool. It does not issue religious rulings (fatwas). For questions of religious practice, please consult a qualified scholar.';

  @override
  String get setMore => 'More';

  @override
  String get setFeedback => 'Send feedback';

  @override
  String get setHadithExtra => 'Hadith explanations';

  @override
  String setSizeMb(String size) {
    return '$size MB on this phone';
  }

  @override
  String get setHadithExtraDeleteTitle => 'Delete hadith explanations?';

  @override
  String get setHadithExtraDeleteBody =>
      'You can download them again from a hadith card.';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramadan · day $day';
  }

  @override
  String ramadanNightLabel(int night) {
    return 'Ramadan · night $night';
  }

  @override
  String ramadanSuhurEndsAt(String time) {
    return 'Suhur ends at $time';
  }

  @override
  String ramadanIftarAt(String time) {
    return 'Iftar at $time';
  }

  @override
  String ramadanInHoursMinutes(int hours, int minutes) {
    return 'in $hours h $minutes min';
  }

  @override
  String ramadanInMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String get ramadanSetLocation =>
      'Set your location to see suhur and iftar times.';

  @override
  String get ramadanSetLocationAction => 'Set location';

  @override
  String ramadanExpectedStart(String date) {
    return 'Ramadan is expected to start on $date.';
  }

  @override
  String ramadanStartsOn(String date) {
    return 'Ramadan starts on $date.';
  }

  @override
  String get ramadanStartQuestion =>
      'When does Ramadan start in your community?';

  @override
  String get ramadanStartTomorrow => 'Tomorrow';

  @override
  String get ramadanStartDayAfter => 'Day after tomorrow';

  @override
  String get ramadanUseCalculation => 'I don\'t know, use the calculation';

  @override
  String get ramadanEndQuestion => 'Is Eid tomorrow in your community?';

  @override
  String get ramadanAnswerYes => 'Yes';

  @override
  String get ramadanAnswerNo => 'No';

  @override
  String ramadanFastTitle(int day) {
    return 'Your fast on day $day';
  }

  @override
  String get ramadanFastFasted => 'Fasted';

  @override
  String get ramadanFastNotFasted => 'Not today';

  @override
  String get ramadanFastExcused => 'Excused';

  @override
  String ramadanNotifSuhurTitle(String time) {
    return 'Suhur · $time';
  }

  @override
  String ramadanNotifSuhurBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Suhur ends in $minutes minutes.',
      one: 'Suhur ends in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String ramadanNotifIftarTitle(String time) {
    return 'Iftar · $time';
  }

  @override
  String cardSourceLine(String attribution) {
    return 'Source: $attribution';
  }

  @override
  String cardSourceLineVersion(String attribution, String version) {
    return 'Source: $attribution, version $version';
  }

  @override
  String get reportBody =>
      'The report is a text file that you send yourself, for example by e-mail. It contains the card reference and technical details from the app. Your prayers, reading and location are not included.';

  @override
  String get reportDescriptionLabel => 'What is wrong? (optional)';

  @override
  String get reportIncludeLog => 'Attach technical log';

  @override
  String get reportIncludeLogHelp =>
      'Errors and app events, without your data.';

  @override
  String get reportPreview => 'Show the exact text';

  @override
  String get reportShare => 'Share report';

  @override
  String get reportShareFailed => 'Sharing did not open. Try again.';

  @override
  String reportShareSubject(String app) {
    return '$app problem report';
  }

  @override
  String get setReportProblem => 'Report a problem';

  @override
  String get todayGatePaused => 'The gate is paused';

  @override
  String get todayGatePausedBody => 'A permission it needs is off.';

  @override
  String get todayGateFix => 'Fix';

  @override
  String get setGateNeedsAttention => 'Needs attention';

  @override
  String get notifChannelPrayer => 'Prayer times';

  @override
  String get notifChannelPrayerDescription =>
      'A quiet notice at each prayer time.';

  @override
  String get notifChannelDaily => 'Daily reminder';

  @override
  String get notifChannelDailyDescription =>
      'One reminder in the morning when your cards are ready.';

  @override
  String get notifChannelSystem => 'App messages';

  @override
  String get notifChannelSystemDescription =>
      'Rare messages about reminders and permissions.';

  @override
  String notifPrayerName(String prayer) {
    String _temp0 = intl.Intl.selectLogic(prayer, {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'jumuah': 'Jumu\'ah',
      'other': 'Prayer',
    });
    return '$_temp0';
  }

  @override
  String notifPrayerTitle(String prayer, String time) {
    return '$prayer · $time';
  }

  @override
  String notifPrayerBody(String prayer) {
    return 'It\'s time for $prayer.';
  }

  @override
  String notifPrivateTitle(String appName, String time) {
    return '$appName · $time';
  }

  @override
  String get notifPrivateBody => 'Reminder';

  @override
  String get notifMorningTitle => 'Good morning';

  @override
  String notifMorningBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'About $minutes minutes.',
      one: 'About 1 minute.',
    );
    return 'Today\'s cards are ready. $_temp0';
  }

  @override
  String notifMorningEventBody(String eventName) {
    return 'Today\'s cards are ready, with something special for $eventName.';
  }

  @override
  String get notifMorningPrivateBody => 'Your daily reminder';

  @override
  String get notifOpenAppTitle => 'Prayer reminders paused soon';

  @override
  String notifOpenAppBody(String appName) {
    return 'Open $appName to keep your prayer reminders coming.';
  }

  @override
  String get notifOpenAppPrivateBody => 'Open the app to keep reminders on';

  @override
  String get notifInexactNote =>
      'Reminders may arrive up to 10 minutes late or more. Allow \"Alarms & reminders\" for exact times.';

  @override
  String get appTitle => 'Mursa';

  @override
  String get tabToday => 'Today';

  @override
  String get tabQuran => 'Quran';

  @override
  String get tabPrayer => 'Prayer';

  @override
  String get tabJourney => 'Journey';

  @override
  String get feedTitle => 'Daily cards';

  @override
  String get gateTitle => 'Pause';

  @override
  String get beginTodaysCards => 'Begin today\'s cards';

  @override
  String get errorGeneric => 'This part could not be loaded.';

  @override
  String get skLoading => 'Loading';

  @override
  String get skStillLoading => 'Still loading…';

  @override
  String get skTryAgain => 'Try again';

  @override
  String get skDismiss => 'Dismiss';

  @override
  String get skUndo => 'Undo';

  @override
  String get skCancel => 'Cancel';

  @override
  String get skDone => 'Done';

  @override
  String get skSkippedForToday => 'Skipped for today';

  @override
  String get skIDidIt => 'I did it';

  @override
  String get skNow => 'Now';

  @override
  String get skFreeReading => 'Free reading';

  @override
  String get skDailyCards => 'Daily cards';

  @override
  String get skScrollForMore => 'Scroll for more';

  @override
  String get skNotificationsOff => 'Notifications off';

  @override
  String get skEstimated => 'Estimated';

  @override
  String get skHoldToConfirm => 'Press and hold to confirm';

  @override
  String get skContentUnavailableTitle => 'This text can’t be shown';

  @override
  String get skContentUnavailableBody =>
      'Mursa couldn’t verify this content. Please try again later.';

  @override
  String skProgressOf(int n, int total) {
    return '$n of $total';
  }

  @override
  String get skPrayerStatusUnlogged => 'Not logged';

  @override
  String get skPrayerStatusOnTime => 'On time';

  @override
  String get skPrayerStatusLate => 'Late';

  @override
  String get skPrayerStatusMissed => 'Missed';

  @override
  String get skPrayerStatusQada => 'Made up';
}
