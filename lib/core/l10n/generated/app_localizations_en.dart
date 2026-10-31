// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
      'Today\'s cards are done. Here are a few more to read.';

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
      'When you open an app you choose, Prosoche shows you a few cards first. After that, the app opens for a while. There\'s always an emergency way through, and you can turn it off anytime.';

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
      'Prosoche checks which app is open, only to show the gate. This never leaves your phone.';

  @override
  String get permUsageTitle => 'Usage access';

  @override
  String get permUsageBody =>
      'Prosoche uses Usage Access to notice when you open one of the apps you chose for the gate, so it can show your cards first.';

  @override
  String get permUsageDoes =>
      'What Prosoche does: checks which app is on screen, only while your screen is on.';

  @override
  String get permUsageNever =>
      'What Prosoche never does: it doesn\'t store or send your app history, time spent, or anything you do inside other apps.';

  @override
  String get permUsageSteps =>
      'On the next screen, find Prosoche and turn on \"Permit usage access\". Then come back.';

  @override
  String get permOverlayTitle => 'Display over other apps';

  @override
  String get permOverlayBody =>
      'This lets Prosoche open its gate screen on top of the app you just opened.';

  @override
  String get permOverlayNever =>
      'What Prosoche never does: read, record or change what\'s on your screen.';

  @override
  String get permNotifTitle => 'Notifications';

  @override
  String get permNotifBody =>
      'While the gate is on, Android shows a small, silent notification. It means Prosoche is ready to pause the apps you chose.';

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
      'Some phones stop apps running in the background to save battery. If the gate stops appearing, allow Prosoche to run in the background.';

  @override
  String batteryBodyVendor(String manufacturer) {
    return '$manufacturer phones often stop background apps. These steps keep the gate working:';
  }

  @override
  String get batteryStepsSamsung =>
      '1. Open battery settings below.\n2. Find Prosoche and choose \"Unrestricted\".\n3. In Settings > Battery > Background usage limits, make sure Prosoche is not in \"Sleeping apps\".';

  @override
  String get batteryStepsXiaomi =>
      '1. Open battery settings below.\n2. Find Prosoche and choose \"No restrictions\".\n3. In the app info of Prosoche, turn on \"Autostart\".';

  @override
  String get batteryStepsHuawei =>
      '1. Open battery settings below.\n2. Find Prosoche in App launch and turn off \"Manage automatically\".\n3. Allow auto-launch and running in background.';

  @override
  String get batteryStepsOppo =>
      '1. Open battery settings below.\n2. Find Prosoche and allow background activity.\n3. In the app info of Prosoche, turn on \"Allow auto launch\".';

  @override
  String get batteryOpen => 'Open battery settings';

  @override
  String get batteryDone => 'I\'ve done this';

  @override
  String get batteryNote => 'Prosoche uses very little battery.';

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
  String blkAppSummary(int cards, String minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    return '$_temp0 · $minutes min';
  }

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
      'Text not yet available in your language';

  @override
  String get onbWelcomeMeaning => 'προσοχή · attention';

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
      'A few quiet minutes with the Stoics each day. Then you\'re done.';

  @override
  String get onbWelcomeNote =>
      'No account. No ads. Your data stays on this phone.';

  @override
  String get onbIntentionTitle => 'Why are you here?';

  @override
  String get onbIntentionBody =>
      'Choose what matters to you. You can pick more than one. It stays on this phone.';

  @override
  String onbIntentionOption(String option) {
    String _temp0 = intl.Intl.selectLogic(option, {
      'less_scrolling': 'Spend less time scrolling',
      'calm': 'Stay calm under pressure',
      'read_daily': 'Read the Stoics daily',
      'reflect': 'Reflect each evening',
      'other': 'Write my own',
    });
    return '$_temp0';
  }

  @override
  String get onbIntentionOwnHint => 'In your own words';

  @override
  String get onbNotifTitle => 'Gentle reminders';

  @override
  String get onbNotifBody =>
      'Get one quiet notice in the morning when your cards are ready. Nothing else.';

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
  String get onbPrivacyTitle => 'Your data stays here';

  @override
  String get onbPrivacyPoint1 => 'No account. No ads.';

  @override
  String get onbPrivacyPoint2 =>
      'Your reading, notes and progress never leave this phone.';

  @override
  String get onbAgeConfirm => 'I am 16 or older';

  @override
  String get onbAgeNote => 'Sharing is available only if you are 16 or older.';

  @override
  String get onbAnalyticsTitle => 'Help improve the app?';

  @override
  String get onbAnalyticsBody =>
      'Share anonymous usage, like which screens are used. Never your reading, your notes, or which apps you use.';

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
      'Only if you choose to share: anonymous events such as \"onboarding finished\" or \"daily cards completed\", the app version and the language. Never what you read or write, or which apps you use.';

  @override
  String get onbPrivacyNote =>
      'You can change this anytime in Settings > Privacy.';

  @override
  String get onbFinish => 'Finish';

  @override
  String get cardTypePassage => 'Passage';

  @override
  String get cardTypePractice => 'Practice';

  @override
  String get cardTypePrompt => 'Reflect';

  @override
  String get cardTypeConcept => 'Concept';

  @override
  String get cardTypeAuthor => 'Author';

  @override
  String cardTranslatedBy(String translator) {
    return 'Translated by $translator';
  }

  @override
  String cardTranslatedByYear(String translator, int year) {
    return 'Translated by $translator ($year)';
  }

  @override
  String get cardReadInContext => 'Read in context';

  @override
  String cardReadReference(String reference) {
    return 'Read $reference';
  }

  @override
  String cardRelatedReference(String reference) {
    return 'Related: $reference';
  }

  @override
  String cardReadWork(String title) {
    return 'Read $title';
  }

  @override
  String get cardOpenPractice => 'Open in Practice';

  @override
  String get cardWriteInJournal => 'Write in journal';

  @override
  String get librarySearch => 'Search';

  @override
  String get librarySearchHint => 'Search the works';

  @override
  String get librarySearchHintTitle => 'Search all works';

  @override
  String get librarySearchHintBody =>
      'Find a word or phrase in every book and section.';

  @override
  String get librarySearchEmpty => 'Nothing found';

  @override
  String get libraryBookmarks => 'Bookmarks';

  @override
  String get libraryBookmarksEmptyTitle => 'No bookmarks yet';

  @override
  String get libraryBookmarksEmptyBody =>
      'Tap the bookmark in the reader to keep a section here.';

  @override
  String get libraryEmptyTitle => 'No works';

  @override
  String get libraryEmptyBody => 'The texts could not be found.';

  @override
  String libraryBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String librarySections(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections',
      one: '1 section',
    );
    return '$_temp0';
  }

  @override
  String libraryContinueAt(String reference) {
    return 'Continue at $reference';
  }

  @override
  String get readerContents => 'Contents';

  @override
  String get readerAddBookmark => 'Bookmark this section';

  @override
  String get readerRemoveBookmark => 'Remove bookmark';

  @override
  String get readerBookmarkAdded => 'Bookmarked';

  @override
  String get readerBookmarkRemoved => 'Bookmark removed';

  @override
  String get readerPrevious => 'Previous section';

  @override
  String get readerNext => 'Next section';

  @override
  String get readerProgressA11y => 'Reading position';

  @override
  String readerProgressValue(int current, int total) {
    return '$current / $total';
  }

  @override
  String get readerMissingTitle => 'This work is not available';

  @override
  String get readerMissingBody =>
      'It may have been removed in a content update.';

  @override
  String get practiceMorning => 'Morning';

  @override
  String get practiceEvening => 'Evening';

  @override
  String get practiceMorningTitle => 'Morning preparation';

  @override
  String get practiceEveningTitle => 'Evening reflection';

  @override
  String get practiceMarkDone => 'Done';

  @override
  String get practiceDoneToday => 'Done today';

  @override
  String get practiceMarkedDone => 'Marked as done.';

  @override
  String get practiceIDidThis => 'I did this';

  @override
  String get practiceExercises => 'Exercises';

  @override
  String get exerciseMissing => 'This exercise is not available';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalSubtitleEmpty => 'Notes stay on this device';

  @override
  String journalSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get journalPrivacyNote =>
      'Your journal stays on this device. It is never sent anywhere.';

  @override
  String get journalYourAnswer => 'Your answer';

  @override
  String get journalSave => 'Save';

  @override
  String get journalNewNote => 'New note';

  @override
  String get journalNote => 'Note';

  @override
  String get journalDelete => 'Delete';

  @override
  String get journalDeleteAllTitle => 'Delete journal';

  @override
  String get journalDeleteAllBody =>
      'All journal entries will be deleted from this device. This cannot be undone.';

  @override
  String get journalExport => 'Export journal';

  @override
  String journalExportTitle(String app) {
    return '$app journal';
  }

  @override
  String get journalEmptyTitle => 'No entries yet';

  @override
  String get journalEmptyBody =>
      'Answers from the morning and evening practice appear here.';

  @override
  String get mementoTitle => 'Memento mori';

  @override
  String get mementoSubtitle => 'Your life in weeks';

  @override
  String get mementoAddYear => 'Add birth year';

  @override
  String get mementoBirthYear => 'Year of birth';

  @override
  String get mementoBirthYearHelp => 'Optional. Used only to draw the weeks.';

  @override
  String get mementoChangeYear => 'Change year';

  @override
  String get mementoClearYear => 'Remove year';

  @override
  String mementoWeeks(int lived, int total) {
    final intl.NumberFormat livedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String livedString = livedNumberFormat.format(lived);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$livedString of $totalString weeks';
  }

  @override
  String mementoGridA11y(int lived, int left) {
    return '$lived weeks lived, $left weeks left of 80 years';
  }

  @override
  String get mementoNote => 'Each square is one week of an 80 year life.';

  @override
  String get mementoPrivacy => 'The year stays on this device.';

  @override
  String get notifEveningTitle => 'Evening reflection';

  @override
  String get notifEveningBody => 'A few minutes to look back at the day.';

  @override
  String get notifEveningPrivateBody => 'A reminder for this evening.';

  @override
  String get setEvening => 'Evening';

  @override
  String get setEveningToggle => 'Evening reflection';

  @override
  String get setEveningHelp =>
      'A quiet reminder to review the day. Off by default.';

  @override
  String get setEveningTime => 'Time';

  @override
  String get todaySettings => 'Settings';

  @override
  String todayDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String todayDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get todayQuestsTitle => 'Today\'s intentions';

  @override
  String get todayQuestSlotRead => 'Read';

  @override
  String get todayQuestSlotLearn => 'Learn';

  @override
  String get todayQuestSlotAct => 'Today\'s practice';

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
  String todayIntention(String text) {
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
  String get cardFallbackTag => 'EN';

  @override
  String get cardFallbackA11y => 'English translation';

  @override
  String cardIntroEstimate(int count, int minutes) {
    return 'Today: $count cards · ~$minutes min';
  }

  @override
  String cardIntroQuests(String slots) {
    return 'Your intentions: $slots';
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
  String cardShareVia(String appName) {
    return 'via $appName';
  }

  @override
  String get doneTitle => 'You\'re done for today';

  @override
  String doneSummary(int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String doneQuests(int done, int total) {
    return 'Intentions: $done of $total';
  }

  @override
  String get doneClosed => 'The cards are closed until tomorrow.';

  @override
  String get doneKeepReading => 'Keep reading';

  @override
  String doneCountedFor(String weekday) {
    return 'Counted for $weekday';
  }

  @override
  String doneOpenDeed(String title) {
    return 'Still open: $title';
  }

  @override
  String get journeyTitle => 'My journey';

  @override
  String get journeyIntentionEmpty => 'Add your intention';

  @override
  String get journeyIntentionEdit => 'Edit intention';

  @override
  String get journeyIntentionDialogTitle => 'Your intention';

  @override
  String get journeyIntentionSave => 'Save';

  @override
  String get journeyIntentionCancel => 'Cancel';

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
      'quote': 'Quotes',
      'passage': 'Passages',
      'practice': 'Practices',
      'prompt': 'Questions',
      'concept': 'Ideas',
      'author': 'Authors',
      'other': 'All',
    });
    return '$_temp0';
  }

  @override
  String journeyCardType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'quote': 'Quote',
      'passage': 'Passage',
      'practice': 'Practice',
      'prompt': 'Question',
      'concept': 'Idea',
      'author': 'Author',
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
  String get setNotifications => 'Notifications';

  @override
  String get setDisplay => 'Daily set & display';

  @override
  String get setPrivacy => 'Privacy';

  @override
  String get setSources => 'Sources & licenses';

  @override
  String get setAbout => 'About';

  @override
  String setSourceVersionLicense(String version, String license) {
    return 'Version $version · License: $license';
  }

  @override
  String get setTranslationDisclaimer =>
      'Older translations may use old-fashioned language. The text is kept as published.';

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
  String get setOsDelayNote =>
      'Reminders may be delayed by Android or battery settings.';

  @override
  String get setPrivacyIntro =>
      'Your reading, notes and other logs stay on this phone. We do not receive them.';

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
      'Prosoche shows these texts without any changes, as published by their sources.';

  @override
  String get setSourcesEmpty => 'No sources found';

  @override
  String setSourceKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'text': 'Texts',
      'translation': 'Translations',
      'curated': 'Prosoche content',
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
  String get setMore => 'More';

  @override
  String get setFeedback => 'Send feedback';

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
      'The report is a text file that you send yourself, for example by e-mail. It contains the card reference and technical details from the app. Your notes and reading are not included.';

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
  String get notifMorningPrivateBody => 'Your daily reminder';

  @override
  String get notifOpenAppTitle => 'Reminders pause soon';

  @override
  String notifOpenAppBody(String appName) {
    return 'Open $appName to keep your reminders coming.';
  }

  @override
  String get notifOpenAppPrivateBody => 'Open the app to keep reminders on';

  @override
  String get appTitle => 'Prosoche';

  @override
  String get tabToday => 'Today';

  @override
  String get tabJourney => 'Journey';

  @override
  String get errorGeneric => 'This part could not be loaded.';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabPractice => 'Practice';

  @override
  String get libraryPlaceholderBody =>
      'Whole works to read, book by book. Coming soon.';

  @override
  String get practicePlaceholderBody =>
      'Morning preparation and evening review. Coming soon.';

  @override
  String get cardTypeQuote => 'Quote';

  @override
  String cardQuoteAttribution(String author, String reference) {
    return '$author, $reference';
  }

  @override
  String cardQuoteA11y(String author) {
    return 'Quote by $author';
  }

  @override
  String questGenericReadCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count cards',
      one: 'Read 1 card',
    );
    return '$_temp0';
  }

  @override
  String get questGenericLearnIdea => 'Learn one idea';

  @override
  String get questGenericActPractice => 'Try one practice';

  @override
  String get todayCtaKeepReading => 'Keep reading';

  @override
  String get setDisclaimerTexts =>
      'Texts are public domain translations, shown as published. Short notes and questions are written for this app.';

  @override
  String get setDisclaimerAdvice =>
      'Prosoche is not medical or psychological advice.';

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
  String get skFreeReading => 'Free reading';

  @override
  String get skDailyCards => 'Daily cards';

  @override
  String get skScrollForMore => 'Scroll for more';

  @override
  String get skHoldToConfirm => 'Press and hold to confirm';

  @override
  String get skContentUnavailableTitle => 'This text can’t be shown';

  @override
  String get skContentUnavailableBody =>
      'Prosoche couldn’t verify this content. Please try again later.';

  @override
  String skProgressOf(int n, int total) {
    return '$n of $total';
  }
}
