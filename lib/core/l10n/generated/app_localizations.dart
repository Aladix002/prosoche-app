import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('id'),
    Locale('tr'),
    Locale('ur'),
  ];

  /// Gate header before a blocked app. {app} is the app name, e.g. 'A pause before Instagram'. Never judge the app or the user.
  ///
  /// In en, this message translates to:
  /// **'A pause before {app}'**
  String gatePauseTitle(String app);

  /// Gate header when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'A pause before this app'**
  String get gatePauseTitleGeneric;

  /// Gate subtitle: how many cards before the app opens.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 card, then {app} opens.} other{{count} cards, then {app} opens.}}'**
  String gateSubtitle(int count, String app);

  /// Gate subtitle when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 card, then the app opens.} other{{count} cards, then the app opens.}}'**
  String gateSubtitleGeneric(int count);

  /// Screen reader progress of the gate cards, e.g. '1 of 3'.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String gateProgress(int done, int total);

  /// Button that moves to the next card in the gate.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get gateNext;

  /// Short countdown under the current gate card, e.g. '3 s'.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String gateDwellLeft(int seconds);

  /// Screen reader text of the card countdown.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, one{Next card in 1 second} other{Next card in {seconds} seconds}}'**
  String gateDwellA11y(int seconds);

  /// Closes the gate and goes to the home screen. The blocked app does not open. No guilt.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get gateBack;

  /// Hold-to-confirm button that opens the app without cards after a 10 second countdown.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get gateEmergency;

  /// Title of the emergency countdown.
  ///
  /// In en, this message translates to:
  /// **'Opening {app}'**
  String gateEmergencyTitle(String app);

  /// Title of the emergency countdown when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Opening the app'**
  String get gateEmergencyTitleGeneric;

  /// Emergency countdown text.
  ///
  /// In en, this message translates to:
  /// **'Opening in {seconds, plural, one{1 second} other{{seconds} seconds}}.'**
  String gateEmergencyBody(int seconds);

  /// Cancels the emergency countdown; nothing is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gateEmergencyCancel;

  /// Dialog shown instead of hold-to-confirm when a screen reader is on.
  ///
  /// In en, this message translates to:
  /// **'Open {app} without cards? It opens in 10 seconds for {minutes} minutes.'**
  String gateEmergencyA11yDialog(String app, int minutes);

  /// Screen reader emergency dialog when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Open the app without cards? It opens in 10 seconds for {minutes} minutes.'**
  String gateEmergencyA11yDialogGeneric(int minutes);

  /// Shown after the required cards.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{{app} is open for 1 minute} other{{app} is open for {minutes} minutes}}'**
  String gateUnlockedTitle(String app, int minutes);

  /// Unlocked title when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one{The app is open for 1 minute} other{The app is open for {minutes} minutes}}'**
  String gateUnlockedTitleGeneric(int minutes);

  /// Short line under the unlocked title.
  ///
  /// In en, this message translates to:
  /// **'Use them well.'**
  String get gateUnlockedBody;

  /// Extra line on the unlocked screen when the gate cards completed the daily set.
  ///
  /// In en, this message translates to:
  /// **'You finished today\'s set.'**
  String get gateSetFinished;

  /// Opens the blocked app (after cards, or after an error).
  ///
  /// In en, this message translates to:
  /// **'Continue to {app}'**
  String gateContinueTo(String app);

  /// Opens the blocked app when its name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get gateContinue;

  /// Goes to the home screen instead of the app. Equal option, no guilt.
  ///
  /// In en, this message translates to:
  /// **'Close {app} instead'**
  String gateUnlockedClose(String app);

  /// Goes to the home screen when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Go to home screen'**
  String get gateUnlockedCloseGeneric;

  /// Continues with more cards after the app is unlocked.
  ///
  /// In en, this message translates to:
  /// **'Keep reading'**
  String get gateKeepReading;

  /// Shown above free reading verses in the gate.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cards are done. Here are a few verses from where you left off.'**
  String get gateFreeReadingNote;

  /// Prayer reminder in the gate. {prayer} is the prayer name, e.g. 'Asr'.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer}'**
  String gatePrayerTitle(String prayer);

  /// Prayer reminder text.
  ///
  /// In en, this message translates to:
  /// **'{app} will still be here after you pray.'**
  String gatePrayerBody(String app);

  /// Prayer reminder text when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'The app will still be here after you pray.'**
  String get gatePrayerBodyGeneric;

  /// Goes to the home screen.
  ///
  /// In en, this message translates to:
  /// **'I\'ll pray first'**
  String get gatePrayerPray;

  /// Continues to the normal gate with cards.
  ///
  /// In en, this message translates to:
  /// **'Show cards anyway'**
  String get gatePrayerContinue;

  /// Gate error state (database or timeout).
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your cards'**
  String get gateErrorTitle;

  /// Gate error body.
  ///
  /// In en, this message translates to:
  /// **'This is our mistake, not yours. You can continue.'**
  String get gateErrorBody;

  /// Shown when the gate takes long to load.
  ///
  /// In en, this message translates to:
  /// **'Still loading…'**
  String get gateLoadingSlow;

  /// Gate empty state; the app will open.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show right now. {app} is open.'**
  String gateEmpty(String app);

  /// Gate empty state when the app name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show right now. The app is open.'**
  String get gateEmptyGeneric;

  /// O5 title: choose apps for the gate.
  ///
  /// In en, this message translates to:
  /// **'Which apps should wait?'**
  String get blkAppsTitle;

  /// O5 body: explains the gate before choosing apps.
  ///
  /// In en, this message translates to:
  /// **'When you open an app you choose, Prosoche shows you a few cards first. After that, the app opens for a while. There\'s always an emergency way through, and you can turn it off anytime.'**
  String get blkAppsBody;

  /// Hint of the app search field.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get blkAppsSearch;

  /// Section header: social apps that are installed.
  ///
  /// In en, this message translates to:
  /// **'Often chosen'**
  String get blkAppsSuggested;

  /// Section header: all other launchable apps.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get blkAppsAll;

  /// Empty app list or no search result.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get blkAppsEmpty;

  /// Error loading the list of installed apps.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your apps.'**
  String get blkAppsError;

  /// O5 primary button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Continue without the gate} one{Continue with 1 app} other{Continue with {count} apps}}'**
  String blkAppsCta(int count);

  /// Primary button of the 'Add apps' picker in settings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add apps} one{Add 1 app} other{Add {count} apps}}'**
  String blkAddCta(int count);

  /// Label of the number of cards before an app opens.
  ///
  /// In en, this message translates to:
  /// **'Cards to unlock'**
  String get blkCardsLabel;

  /// Label of how long the app stays open after the cards.
  ///
  /// In en, this message translates to:
  /// **'Unlock for'**
  String get blkMinutesLabel;

  /// Duration in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String blkMinutes(String minutes);

  /// Screen reader label of the minus button.
  ///
  /// In en, this message translates to:
  /// **'Decrease {what}'**
  String blkDecrease(String what);

  /// Screen reader label of the plus button.
  ///
  /// In en, this message translates to:
  /// **'Increase {what}'**
  String blkIncrease(String what);

  /// O6 title and title of the permissions screen in settings.
  ///
  /// In en, this message translates to:
  /// **'Permissions for the gate'**
  String get blkPermTitle;

  /// O6 intro, part of the prominent disclosure.
  ///
  /// In en, this message translates to:
  /// **'Prosoche checks which app is open, only to show the gate. This never leaves your phone.'**
  String get blkPermIntro;

  /// Name of the Android usage access permission.
  ///
  /// In en, this message translates to:
  /// **'Usage access'**
  String get permUsageTitle;

  /// Prominent disclosure for usage access (Google Play).
  ///
  /// In en, this message translates to:
  /// **'Prosoche uses Usage Access to notice when you open one of the apps you chose for the gate, so it can show your cards first.'**
  String get permUsageBody;

  /// Prominent disclosure: what is done with usage access.
  ///
  /// In en, this message translates to:
  /// **'What Prosoche does: checks which app is on screen, only while your screen is on.'**
  String get permUsageDoes;

  /// Prominent disclosure: what is never done.
  ///
  /// In en, this message translates to:
  /// **'What Prosoche never does: it doesn\'t store or send your app history, time spent, or anything you do inside other apps.'**
  String get permUsageNever;

  /// Steps in system settings for usage access.
  ///
  /// In en, this message translates to:
  /// **'On the next screen, find Prosoche and turn on \"Permit usage access\". Then come back.'**
  String get permUsageSteps;

  /// Name of the Android overlay permission.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get permOverlayTitle;

  /// Prominent disclosure for the overlay permission.
  ///
  /// In en, this message translates to:
  /// **'This lets Prosoche open its gate screen on top of the app you just opened.'**
  String get permOverlayBody;

  /// Prominent disclosure: what is never done with overlay.
  ///
  /// In en, this message translates to:
  /// **'What Prosoche never does: read, record or change what\'s on your screen.'**
  String get permOverlayNever;

  /// Name of the notification permission.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifTitle;

  /// Why notifications matter for the gate (foreground service).
  ///
  /// In en, this message translates to:
  /// **'While the gate is on, Android shows a small, silent notification. It means Prosoche is ready to pause the apps you chose.'**
  String get permNotifBody;

  /// Prominent disclosure: data is not shared.
  ///
  /// In en, this message translates to:
  /// **'This stays on your phone and is not shared with anyone.'**
  String get permLocal;

  /// Button that opens the system settings for a permission.
  ///
  /// In en, this message translates to:
  /// **'Allow in settings'**
  String get permAllow;

  /// Permission state: granted.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get permGranted;

  /// Permission state after coming back without granting it.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet'**
  String get permNotYet;

  /// Screen reader label of a permission row.
  ///
  /// In en, this message translates to:
  /// **'{name}: {state, select, true{on} other{off}}'**
  String permStateLabel(String name, String state);

  /// O6 primary button; enabled when usage access and overlay are on.
  ///
  /// In en, this message translates to:
  /// **'Turn on the gate'**
  String get blkTurnOn;

  /// Error when the gate service couldn't start.
  ///
  /// In en, this message translates to:
  /// **'The gate couldn\'t start. Please try again.'**
  String get blkTurnOnFailed;

  /// Battery row in the permissions list.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get batteryTitle;

  /// Battery row with the phone maker.
  ///
  /// In en, this message translates to:
  /// **'Battery ({manufacturer})'**
  String batteryVendorTitle(String manufacturer);

  /// Button that opens the battery guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get batteryGuide;

  /// Generic battery guide.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop apps running in the background to save battery. If the gate stops appearing, allow Prosoche to run in the background.'**
  String get batteryBodyGeneric;

  /// Intro of the vendor battery guide.
  ///
  /// In en, this message translates to:
  /// **'{manufacturer} phones often stop background apps. These steps keep the gate working:'**
  String batteryBodyVendor(String manufacturer);

  /// Battery guide steps for Samsung (One UI). Check the paths on current devices.
  ///
  /// In en, this message translates to:
  /// **'1. Open battery settings below.\n2. Find Prosoche and choose \"Unrestricted\".\n3. In Settings > Battery > Background usage limits, make sure Prosoche is not in \"Sleeping apps\".'**
  String get batteryStepsSamsung;

  /// Battery guide steps for Xiaomi, Redmi, POCO (HyperOS/MIUI). Check the paths on current devices.
  ///
  /// In en, this message translates to:
  /// **'1. Open battery settings below.\n2. Find Prosoche and choose \"No restrictions\".\n3. In the app info of Prosoche, turn on \"Autostart\".'**
  String get batteryStepsXiaomi;

  /// Battery guide steps for Huawei and Honor. Check the paths on current devices.
  ///
  /// In en, this message translates to:
  /// **'1. Open battery settings below.\n2. Find Prosoche in App launch and turn off \"Manage automatically\".\n3. Allow auto-launch and running in background.'**
  String get batteryStepsHuawei;

  /// Battery guide steps for Oppo, Realme, OnePlus (ColorOS). Check the paths on current devices.
  ///
  /// In en, this message translates to:
  /// **'1. Open battery settings below.\n2. Find Prosoche and allow background activity.\n3. In the app info of Prosoche, turn on \"Allow auto launch\".'**
  String get batteryStepsOppo;

  /// Button that opens the battery optimization list.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get batteryOpen;

  /// Checkbox: user confirms the battery steps (can't be verified).
  ///
  /// In en, this message translates to:
  /// **'I\'ve done this'**
  String get batteryDone;

  /// Short reassurance under the battery guide.
  ///
  /// In en, this message translates to:
  /// **'Prosoche uses very little battery.'**
  String get batteryNote;

  /// Title of the gate settings screen.
  ///
  /// In en, this message translates to:
  /// **'The gate'**
  String get blkTitle;

  /// Main switch of the gate.
  ///
  /// In en, this message translates to:
  /// **'Pause before chosen apps'**
  String get blkSwitch;

  /// Gate status: service running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get blkStatusRunning;

  /// Gate status: turned off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get blkStatusOff;

  /// Gate status: usage access was removed.
  ///
  /// In en, this message translates to:
  /// **'Paused - usage access missing'**
  String get blkStatusNoUsage;

  /// Gate status: overlay permission was removed.
  ///
  /// In en, this message translates to:
  /// **'Paused - \"Display over other apps\" missing'**
  String get blkStatusNoOverlay;

  /// Gate status: the background service is not running.
  ///
  /// In en, this message translates to:
  /// **'Paused - Android stopped the service'**
  String get blkStatusStopped;

  /// Button that fixes the paused gate.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get blkFix;

  /// Row that opens the permissions screen.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get blkPermissions;

  /// Value of the permissions row when something is missing.
  ///
  /// In en, this message translates to:
  /// **'Some are off'**
  String get blkPermissionsMissing;

  /// Value of the permissions row when all needed permissions are on.
  ///
  /// In en, this message translates to:
  /// **'All on'**
  String get blkPermissionsOk;

  /// Section header: blocked apps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get blkApps;

  /// Empty list of blocked apps.
  ///
  /// In en, this message translates to:
  /// **'No apps yet. Add the apps that should wait.'**
  String get blkAppsNone;

  /// Button that opens the app picker.
  ///
  /// In en, this message translates to:
  /// **'Add apps'**
  String get blkAddApps;

  /// Summary of one blocked app.
  ///
  /// In en, this message translates to:
  /// **'{cards, plural, one{1 card} other{{cards} cards}} · {minutes} min{prayer, select, true{ · prayer reminder} other{}}'**
  String blkAppSummary(int cards, String minutes, String prayer);

  /// Section header: prayer reminder in the gate.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminder'**
  String get blkPrayerSection;

  /// Explains the prayer reminder (not a lock).
  ///
  /// In en, this message translates to:
  /// **'For apps with prayer reminder on, the gate first reminds you of the prayer for this many minutes after its time begins. You can always continue.'**
  String get blkPrayerHelp;

  /// Label of the prayer reminder window.
  ///
  /// In en, this message translates to:
  /// **'Remind for'**
  String get blkPrayerMinutes;

  /// Section header: local gate statistics.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get blkStatsSection;

  /// Statistics are local and never sent.
  ///
  /// In en, this message translates to:
  /// **'Only on this phone.'**
  String get blkStatsHelp;

  /// Number of times the gate was shown.
  ///
  /// In en, this message translates to:
  /// **'Pauses'**
  String get blkStatsGates;

  /// Unlocks after reading the cards.
  ///
  /// In en, this message translates to:
  /// **'Opened after cards'**
  String get blkStatsCards;

  /// Emergency unlocks.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get blkStatsEmergency;

  /// Unlocks because the gate failed.
  ///
  /// In en, this message translates to:
  /// **'Opened after an error'**
  String get blkStatsError;

  /// No gate statistics yet.
  ///
  /// In en, this message translates to:
  /// **'No pauses yet.'**
  String get blkStatsEmpty;

  /// Unlocks of one app in the last 7 days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 unlock} other{{count} unlocks}}'**
  String blkStatsPerApp(int count);

  /// Error state of the gate settings.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the gate settings.'**
  String get blkLoadError;

  /// Switch: remind of the prayer before this app.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminder'**
  String get blkAppPrayerLock;

  /// Explains the per-app prayer reminder.
  ///
  /// In en, this message translates to:
  /// **'Around prayer times, the gate asks if you\'d like to pray first.'**
  String get blkAppPrayerLockHelp;

  /// Button: remove the app from the gate.
  ///
  /// In en, this message translates to:
  /// **'Remove from the gate'**
  String get blkAppRemove;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Remove {app}?'**
  String blkAppRemoveTitle(String app);

  /// Confirm remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get blkAppRemoveConfirm;

  /// Detail of an app that was removed.
  ///
  /// In en, this message translates to:
  /// **'This app is no longer in the gate.'**
  String get blkAppNotFound;

  /// Small note under the Arabic original of a card (hadith, dua, name of Allah, verse) when there is no translation in the user's language yet. Religious text is never shown in English instead.
  ///
  /// In en, this message translates to:
  /// **'Translation not yet available in your language'**
  String get cardTranslationNotYetAvailable;

  /// Title of the sheet opened by tapping a footnote marker like [2] in a verse translation.
  ///
  /// In en, this message translates to:
  /// **'Translator\'s note'**
  String get cardTranslatorNoteTitle;

  /// Screen reader label of a tappable footnote marker in a verse translation.
  ///
  /// In en, this message translates to:
  /// **'Translator\'s note {number}'**
  String cardTranslatorNoteA11y(String number);

  /// Button on a hadith card when the optional hadith explanations pack is not downloaded yet.
  ///
  /// In en, this message translates to:
  /// **'Download explanations'**
  String get cardHadithDownloadExplanations;

  /// Authenticity grade of a hadith: the technical term and its meaning in brackets. In the Arabic UI the app shows the Arabic original from the source instead.
  ///
  /// In en, this message translates to:
  /// **'{grade, select, sahih{Sahih (authentic)} hasan{Hasan (good)} daif{Da\'if (weak)} other{Other}}'**
  String cardHadithGradeLabel(String grade);

  /// Hadith reference for 'muttafaq alayh': the hadith is narrated by both al-Bukhari and Muslim. Shown in the card header.
  ///
  /// In en, this message translates to:
  /// **'Agreed upon (Bukhari & Muslim)'**
  String get cardHadithAgreedUpon;

  /// Inline message on a hadith card when downloading the optional hadith explanations pack failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download explanations. Check your connection and try again.'**
  String get cardHadithExplanationsFailed;

  /// Button under the failed-download message that downloads the hadith explanations pack again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cardHadithExplanationsRetry;

  /// Generic READ quest shown when no quest text exists in the user's language. Neutral UI text, no religious content.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 verse} other{Read {count} verses}}'**
  String questGenericReadVerses(int count);

  /// Generic LEARN quest (word cards enabled) shown when no quest text exists in the user's language.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Learn 1 new word} other{Learn {count} new words}}'**
  String questGenericLearnWords(int count);

  /// Generic LEARN quest (word cards disabled) shown when no quest text exists in the user's language.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 hadith or dua card} other{Read {count} hadith or dua cards}}'**
  String questGenericLearnCards(int count);

  /// Tooltip and screen reader label of the gear icon that opens Settings (app bar of Today and Journey).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shellSettings;

  /// Onboarding progress at the top of each step, e.g. 'Step 2 of 5'. Numbers come formatted in the digits of the language.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onbStepProgress(String current, String total);

  /// Onboarding: go to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// Onboarding: skip the current step.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// Onboarding: save the step and go to the next one.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbContinue;

  /// Welcome text in the header of the first onboarding step (language).
  ///
  /// In en, this message translates to:
  /// **'A few quiet minutes with the Quran each day. Then you\'re done.'**
  String get onbWelcomeBody;

  /// Short privacy note under the welcome text.
  ///
  /// In en, this message translates to:
  /// **'No account. No ads. Your data stays on this phone.'**
  String get onbWelcomeNote;

  /// Title of the language step.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onbLanguageTitle;

  /// Body of the language step.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get onbLanguageBody;

  /// Name of a language in that language (endonym). Do not translate: every language shows the same names.
  ///
  /// In en, this message translates to:
  /// **'{lang, select, en{English} ar{العربية} id{Bahasa Indonesia} ur{اردو} bn{বাংলা} tr{Türkçe} other{{lang}}}'**
  String onbLanguageName(String lang);

  /// Label of the Quran translation picker on the language step.
  ///
  /// In en, this message translates to:
  /// **'Quran translation'**
  String get onbTranslationLabel;

  /// Shown instead of the translation picker when the content has no translation for the chosen language.
  ///
  /// In en, this message translates to:
  /// **'No translation is available for this language yet.'**
  String get onbTranslationNone;

  /// Title of the fatal state when the bundled content cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get onbFatalTitle;

  /// Body of the fatal state when the bundled content cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Please reinstall the app.'**
  String get onbFatalBody;

  /// Title of the intention step.
  ///
  /// In en, this message translates to:
  /// **'Why are you here?'**
  String get onbNiyyahTitle;

  /// Body of the intention step.
  ///
  /// In en, this message translates to:
  /// **'Choose what matters to you. You can pick more than one. It stays on this phone.'**
  String get onbNiyyahBody;

  /// Options of the intention step. 'other' opens a text field for the user's own words.
  ///
  /// In en, this message translates to:
  /// **'{option, select, khatm{Read the Quran regularly} arabic{Understand Quranic Arabic} prayer{Pray on time} less_social{Spend less time scrolling} other{Write my own}}'**
  String onbNiyyahOption(String option);

  /// Hint of the text field for the user's own intention (max 140 characters).
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get onbNiyyahOwnHint;

  /// Title of the location step.
  ///
  /// In en, this message translates to:
  /// **'Prayer times for where you are'**
  String get onbLocationTitle;

  /// Body of the location step (prominent disclosure before the system location dialog).
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated on your phone. Your location is rounded to about 1 km and never leaves your device.'**
  String get onbLocationBody;

  /// Button: get the location once from the phone.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get onbLocationGps;

  /// Button: open the offline city search.
  ///
  /// In en, this message translates to:
  /// **'Choose a city instead'**
  String get onbLocationCity;

  /// Shown while the phone is getting the location (max 10 s).
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get onbLocationFinding;

  /// Shown when the location permission is denied or location is turned off.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Choose your city instead.'**
  String get onbLocationDenied;

  /// Shown when getting the location fails or times out after 10 s.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Choose your city instead.'**
  String get onbLocationFailed;

  /// Shown when the location is known but no city from the offline list is near.
  ///
  /// In en, this message translates to:
  /// **'No city found nearby. Choose your city instead.'**
  String get onbLocationNoCity;

  /// Hint of the city search field.
  ///
  /// In en, this message translates to:
  /// **'Search for a city'**
  String get onbCitySearchHint;

  /// City search without results.
  ///
  /// In en, this message translates to:
  /// **'No city found. Try a nearby larger city.'**
  String get onbCitySearchEmpty;

  /// City search failed to read the offline city list.
  ///
  /// In en, this message translates to:
  /// **'Cities could not be loaded.'**
  String get onbCitySearchError;

  /// Explains the preselected calculation method. country = country name, e.g. 'Slovakia'.
  ///
  /// In en, this message translates to:
  /// **'We picked the method most often used in {country}. If your local mosque uses another, choose it here.'**
  String onbMethodBody(String country);

  /// Label of the prayer time calculation method picker.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get onbMethodLabel;

  /// Names of prayer time calculation methods (official bodies, keep proper names).
  ///
  /// In en, this message translates to:
  /// **'{method, select, muslimWorldLeague{Muslim World League} northAmerica{ISNA (North America)} egyptian{Egyptian General Authority} ummAlQura{Umm al-Qura, Makkah} karachi{University of Islamic Sciences, Karachi} turkiye{Diyanet, Türkiye} indonesian{Kemenag, Indonesia} singapore{MUIS, Singapore} dubai{Dubai} qatar{Qatar} kuwait{Kuwait} gulfRegion{Gulf region} algerian{Algeria} morocco{Morocco} tunisia{Tunisia} jordan{Jordan} france{UOIF, France} portugal{Portugal} russia{Spiritual Administration, Russia} tehran{Institute of Geophysics, Tehran} jafari{Shia Ithna Ashari (Jafari)} moonsightingCommittee{Moonsighting Committee} jakim{JAKIM, Malaysia} other{{method}}}'**
  String onbMethodName(String method);

  /// Label of the Asr calculation picker.
  ///
  /// In en, this message translates to:
  /// **'Asr time'**
  String get onbAsrLabel;

  /// Asr calculation option: standard shadow length.
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi\'i, Maliki, Hanbali)'**
  String get onbAsrShafi;

  /// Asr calculation option: Hanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get onbAsrHanafi;

  /// Info box on the location step for latitudes above 48 degrees.
  ///
  /// In en, this message translates to:
  /// **'In summer, Isha and Fajr can be hard to calculate this far north. We use: Middle of the night. You can change this later in Settings.'**
  String get onbHighLatNote;

  /// Heading of the preview of today's prayer times on the location step.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get onbTodayTimes;

  /// Title of the notifications step.
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders'**
  String get onbNotifTitle;

  /// Body of the notifications step (shown before the system dialog).
  ///
  /// In en, this message translates to:
  /// **'Get a quiet notice at each prayer time and one in the morning when your cards are ready. Nothing else.'**
  String get onbNotifBody;

  /// Switch: reminders at each prayer time.
  ///
  /// In en, this message translates to:
  /// **'Prayer times (5 a day)'**
  String get onbNotifPrayers;

  /// Subtitle of the disabled prayer reminder switch when the location step was skipped.
  ///
  /// In en, this message translates to:
  /// **'Set your location first'**
  String get onbNotifPrayersNoLocation;

  /// Switch: one reminder in the morning. time = local time, e.g. '07:30'.
  ///
  /// In en, this message translates to:
  /// **'Morning reminder at {time}'**
  String onbNotifMorning(String time);

  /// Switch: notifications show neutral text on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Private text on lock screen'**
  String get onbNotifPrivate;

  /// Button: asks for the notification permission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get onbNotifAllow;

  /// Shown instead of the allow button when notifications are already allowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on'**
  String get onbNotifOn;

  /// Shown after the notification permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can turn them on anytime in Settings.'**
  String get onbNotifDenied;

  /// Button: opens the system settings of the app.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get onbOpenSettings;

  /// Title of the exact alarm section on the notifications step.
  ///
  /// In en, this message translates to:
  /// **'On-time prayer reminders'**
  String get onbExactTitle;

  /// Explains the exact alarm permission (Android 12+).
  ///
  /// In en, this message translates to:
  /// **'To remind you at the exact minute, Android needs \"Alarms & reminders\" to be allowed. Without it, reminders may arrive up to 10 minutes late or more.'**
  String get onbExactBody;

  /// Button: opens the system 'Alarms & reminders' setting.
  ///
  /// In en, this message translates to:
  /// **'Allow in settings'**
  String get onbExactCta;

  /// Title of the privacy step (last step).
  ///
  /// In en, this message translates to:
  /// **'Your data stays here'**
  String get onbPrivacyTitle;

  /// Privacy step, first point.
  ///
  /// In en, this message translates to:
  /// **'No account. No ads.'**
  String get onbPrivacyPoint1;

  /// Privacy step, second point.
  ///
  /// In en, this message translates to:
  /// **'Prayers, reading and progress never leave this phone.'**
  String get onbPrivacyPoint2;

  /// Checkbox: sharing choices are available only after confirming the age.
  ///
  /// In en, this message translates to:
  /// **'I am 16 or older'**
  String get onbAgeConfirm;

  /// Shown while the age is not confirmed.
  ///
  /// In en, this message translates to:
  /// **'Sharing is available only if you are 16 or older.'**
  String get onbAgeNote;

  /// Title of the anonymous usage choice.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app?'**
  String get onbAnalyticsTitle;

  /// Explains the anonymous usage choice.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage, like which screens are used. Never your prayers, your reading, your location, or which apps you use.'**
  String get onbAnalyticsBody;

  /// Choice: share anonymous usage.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get onbAnalyticsYes;

  /// Choice: do not share anonymous usage (equal to 'Share').
  ///
  /// In en, this message translates to:
  /// **'Don\'t share'**
  String get onbAnalyticsNo;

  /// Title of the crash report choice.
  ///
  /// In en, this message translates to:
  /// **'Send crash reports?'**
  String get onbCrashTitle;

  /// Explains the crash report choice.
  ///
  /// In en, this message translates to:
  /// **'If the app crashes, send a technical report without your content.'**
  String get onbCrashBody;

  /// Choice: send crash reports.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get onbCrashYes;

  /// Choice: do not send crash reports (equal to 'Send').
  ///
  /// In en, this message translates to:
  /// **'Don\'t send'**
  String get onbCrashNo;

  /// Button: opens a sheet with the list of collected anonymous events.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get onbWhatWeCollect;

  /// Content of the 'What we collect' sheet.
  ///
  /// In en, this message translates to:
  /// **'Only if you choose to share: anonymous events such as \"onboarding finished\" or \"daily cards completed\", the app version and the language. Never what you read or pray, your location, or which apps you use.'**
  String get onbWhatWeCollectBody;

  /// Note under the sharing choices.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings > Privacy.'**
  String get onbPrivacyNote;

  /// Button on the last onboarding step: finish and open Today.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onbFinish;

  /// Tooltip of the gear button on Today that opens Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get todaySettings;

  /// Screen reader hint of the Hijri date on Today.
  ///
  /// In en, this message translates to:
  /// **'Open the calendar'**
  String get todayCalendarHint;

  /// Hijri date on Today and on the intro card, e.g. '17 Jumada al-Ula 1448'. Digits are already localized.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}'**
  String todayHijriDate(String day, String month, String year);

  /// Name of the Hijri month (calendar name, transliterated). The value is m1..m12.
  ///
  /// In en, this message translates to:
  /// **'{month, select, m1{Muharram} m2{Safar} m3{Rabi al-Awwal} m4{Rabi al-Thani} m5{Jumada al-Ula} m6{Jumada al-Akhirah} m7{Rajab} m8{Shaban} m9{Ramadan} m10{Shawwal} m11{Dhul Qadah} m12{Dhul Hijjah} other{-}}'**
  String todayHijriMonth(String month);

  /// Next prayer chip on Today, e.g. 'Asr in 1 h 12 min'.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {duration}'**
  String todayNextPrayer(String prayer, String duration);

  /// Next prayer chip when the prayer time is now.
  ///
  /// In en, this message translates to:
  /// **'{prayer} now'**
  String todayPrayerNow(String prayer);

  /// Countdown with hours and minutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String todayDurationHoursMinutes(int hours, int minutes);

  /// Countdown with minutes only.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String todayDurationMinutes(int minutes);

  /// Prayer chip on Today when no location is set.
  ///
  /// In en, this message translates to:
  /// **'Set your location to see prayer times'**
  String get todaySetLocation;

  /// Section title of the daily quests on Today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s intentions'**
  String get todayQuestsTitle;

  /// Fallback title of the READ quest when no text is available.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get todayQuestSlotRead;

  /// Fallback title of the LEARN quest when no text is available.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get todayQuestSlotLearn;

  /// Fallback title of the ACT quest when no text is available.
  ///
  /// In en, this message translates to:
  /// **'Today\'s deed'**
  String get todayQuestSlotAct;

  /// Snackbar after the user marks the ACT quest as done.
  ///
  /// In en, this message translates to:
  /// **'Marked as done.'**
  String get todayQuestMarked;

  /// Action in the ACT quest menu that skips it for today.
  ///
  /// In en, this message translates to:
  /// **'Skip for today'**
  String get todayQuestSkip;

  /// Today call to action before the daily set is started.
  ///
  /// In en, this message translates to:
  /// **'Begin today\'s cards'**
  String get todayCtaBegin;

  /// Number of cards under the begin call to action.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 card} other{{count} cards}}'**
  String todayCtaBeginCount(int count);

  /// Today call to action when the daily set is in progress.
  ///
  /// In en, this message translates to:
  /// **'Continue · {done} of {total}'**
  String todayCtaContinue(int done, int total);

  /// Shown on Today after the daily set is finished.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cards are complete'**
  String get todayCtaComplete;

  /// Button on Today after the set is finished; opens free reading.
  ///
  /// In en, this message translates to:
  /// **'Read the Quran'**
  String get todayCtaReadQuran;

  /// Private streak of completed days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1-day streak} other{{count}-day streak}}'**
  String todayStreak(int count);

  /// Remaining grace days next to the streak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no grace days left} one{1 grace day} other{{count} grace days}}'**
  String todayGraceDays(int count);

  /// The user's own intention shown in quotes on Today.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String todayNiyyah(String text);

  /// E-FEED-1 title when the daily set could not be prepared.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cards didn\'t load'**
  String get feedErrorTitle;

  /// E-FEED-1 body.
  ///
  /// In en, this message translates to:
  /// **'Please try again. Your progress is safe.'**
  String get feedErrorBody;

  /// Tooltip of the close button of the feed.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get feedClose;

  /// Returns from the feed to Today.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get feedBackToToday;

  /// Hint when the user swipes on before the card was read.
  ///
  /// In en, this message translates to:
  /// **'Take a moment'**
  String get feedTakeAMoment;

  /// Hint on the first card.
  ///
  /// In en, this message translates to:
  /// **'Swipe up for the next card'**
  String get feedSwipeUp;

  /// Screen reader action that moves to the next card.
  ///
  /// In en, this message translates to:
  /// **'Next card'**
  String get feedNextCard;

  /// Screen reader action that moves to the previous card.
  ///
  /// In en, this message translates to:
  /// **'Previous card'**
  String get feedPreviousCard;

  /// Screen reader position of a card in the daily set.
  ///
  /// In en, this message translates to:
  /// **'Card {n} of {total}'**
  String feedCardPosition(int n, int total);

  /// Error inside a single card.
  ///
  /// In en, this message translates to:
  /// **'This card didn\'t load'**
  String get feedCardErrorTitle;

  /// Skips a card that failed to load.
  ///
  /// In en, this message translates to:
  /// **'Skip this card'**
  String get feedSkipCard;

  /// Dialog when the date changed while the feed was open.
  ///
  /// In en, this message translates to:
  /// **'A new day has started'**
  String get feedNewDayTitle;

  /// Body of the new day dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue yesterday\'s cards or start today\'s?'**
  String get feedNewDayBody;

  /// Keeps the previous day's set.
  ///
  /// In en, this message translates to:
  /// **'Continue yesterday\'s'**
  String get feedNewDayContinue;

  /// Switches the feed to today's set.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s'**
  String get feedNewDayToday;

  /// Type label of a verse card.
  ///
  /// In en, this message translates to:
  /// **'VERSE'**
  String get cardTypeVerse;

  /// Type label of a hadith card.
  ///
  /// In en, this message translates to:
  /// **'HADITH'**
  String get cardTypeHadith;

  /// Type label of a dua (supplication) card.
  ///
  /// In en, this message translates to:
  /// **'DUA'**
  String get cardTypeDua;

  /// Type label of a card with one of the 99 names.
  ///
  /// In en, this message translates to:
  /// **'NAME OF ALLAH'**
  String get cardTypeName;

  /// Type label of a reflection card.
  ///
  /// In en, this message translates to:
  /// **'REFLECTION'**
  String get cardTypeReflection;

  /// Type label of an event card when the event has no title.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL DAY'**
  String get cardTypeEvent;

  /// Type label of a verse outside the daily set.
  ///
  /// In en, this message translates to:
  /// **'FREE READING'**
  String get cardTypeFreeReading;

  /// Card header: type label and reference, e.g. 'VERSE · Al-Baqarah 2:255'.
  ///
  /// In en, this message translates to:
  /// **'{type} · {context}'**
  String cardEyebrow(String type, String context);

  /// Verse reference, e.g. 'Al-Baqarah 2:255'. The surah name comes from the content database.
  ///
  /// In en, this message translates to:
  /// **'{surah} {ref}'**
  String cardAyahReference(String surah, String ref);

  /// Screen reader label of a verse card, e.g. 'Al-Baqarah, verse 255'.
  ///
  /// In en, this message translates to:
  /// **'{surah}, verse {ayah}'**
  String cardAyahA11y(String surah, String ayah);

  /// Saves a card (bookmark).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cardSave;

  /// Removes a saved card.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get cardUnsave;

  /// Snackbar after a card was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get cardSaved;

  /// Snackbar after a card was removed from saved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get cardRemoved;

  /// Shares a card.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get cardShare;

  /// Opens the card options sheet.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get cardMore;

  /// Attribution of the translation of meaning.
  ///
  /// In en, this message translates to:
  /// **'Translation: {translator}'**
  String cardTranslationLabel(String translator);

  /// Tag on a translation shown in English because it is missing in the user's language.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get cardFallbackTag;

  /// Screen reader text of the EN tag.
  ///
  /// In en, this message translates to:
  /// **'English translation'**
  String get cardFallbackA11y;

  /// Shown when a card has no translation in the user's language or English.
  ///
  /// In en, this message translates to:
  /// **'Translation not available in your language'**
  String get cardNoTranslation;

  /// Opens the verse in the Quran reader.
  ///
  /// In en, this message translates to:
  /// **'Read in context'**
  String get cardReadInContext;

  /// Source reference of a dua or hadith.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String cardSourceRef(String source);

  /// Hadith reference, e.g. 'Sahih al-Bukhari 1'. Values come from the content database.
  ///
  /// In en, this message translates to:
  /// **'{collection} {number}'**
  String cardHadithReference(String collection, String number);

  /// Authenticity grade of a hadith.
  ///
  /// In en, this message translates to:
  /// **'Grade: {grade}'**
  String cardHadithGrade(String grade);

  /// Localized hadith grade label (technical term).
  ///
  /// In en, this message translates to:
  /// **'{grade, select, sahih{Sahih} hasan{Hasan} other{Other}}'**
  String cardHadithGradeName(String grade);

  /// Opens the explanation of a hadith (only when available).
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get cardHadithExplanation;

  /// How many times a dua is usually repeated.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String cardDuaRepeat(int count);

  /// Local repetition counter of a dua.
  ///
  /// In en, this message translates to:
  /// **'{n} / {total}'**
  String cardDuaCounter(int n, int total);

  /// Screen reader hint of the repetition counter.
  ///
  /// In en, this message translates to:
  /// **'Count a repetition'**
  String get cardDuaCounterHint;

  /// Position of the name among the 99 names.
  ///
  /// In en, this message translates to:
  /// **'{n} of 99'**
  String cardNameIndex(String n);

  /// Verse where the name is mentioned, e.g. 'Mentioned in 59:23'.
  ///
  /// In en, this message translates to:
  /// **'Mentioned in {ref}'**
  String cardNameMentionedIn(String ref);

  /// Opens the referenced verse.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get cardOpen;

  /// Attribution of a reflection card (reviewed by a content reviewer).
  ///
  /// In en, this message translates to:
  /// **'Prosoche reflection · reviewed'**
  String get cardReflectionAttribution;

  /// Surah info on an event card. The surah name comes from the content database.
  ///
  /// In en, this message translates to:
  /// **'{surah} · {count, plural, one{1 verse} other{{count} verses}}'**
  String cardEventSurah(String surah, int count);

  /// Opens the surah of the event in the reader. The surah name comes from the content database.
  ///
  /// In en, this message translates to:
  /// **'Read {surah}'**
  String cardEventReadSurah(String surah);

  /// Size of the daily set on the intro card.
  ///
  /// In en, this message translates to:
  /// **'Today: {count} cards · ~{minutes} min'**
  String cardIntroEstimate(int count, int minutes);

  /// Quest slots on the intro card, e.g. 'read · learn · act'.
  ///
  /// In en, this message translates to:
  /// **'Your intentions: {slots}'**
  String cardIntroQuests(String slots);

  /// More special days today.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String cardIntroMoreEvents(int count);

  /// Card options: copy the text.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get cardSheetCopy;

  /// Card options: share the card as an image.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get cardSheetShareImage;

  /// Card options: share the card as text.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get cardSheetShareText;

  /// Card options: show the source of the content.
  ///
  /// In en, this message translates to:
  /// **'Show source'**
  String get cardSheetSource;

  /// Card options: report a problem with the card.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get cardSheetReport;

  /// Snackbar after copying card text.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get cardCopied;

  /// Shown when a card is too long to be shared as an image.
  ///
  /// In en, this message translates to:
  /// **'Too long for an image. Share as text instead.'**
  String get cardTooLongForImage;

  /// Title of the source sheet.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get cardSourceTitle;

  /// License of the content source.
  ///
  /// In en, this message translates to:
  /// **'License: {license}'**
  String cardSourceLicense(String license);

  /// Last line of shared text and images.
  ///
  /// In en, this message translates to:
  /// **'via {appName}'**
  String cardShareVia(String appName);

  /// Title of the final card of the daily set.
  ///
  /// In en, this message translates to:
  /// **'You\'re done for today'**
  String get doneTitle;

  /// Summary on the done card (word cards are off).
  ///
  /// In en, this message translates to:
  /// **'{cards, plural, one{1 card} other{{cards} cards}} · {verses, plural, one{1 verse} other{{verses} verses}}'**
  String doneSummary(int cards, int verses);

  /// Quest summary on the done card.
  ///
  /// In en, this message translates to:
  /// **'Intentions: {done} of {total}'**
  String doneQuests(int done, int total);

  /// Next prayer on the done card.
  ///
  /// In en, this message translates to:
  /// **'Next: {prayer} at {time}'**
  String doneNextPrayer(String prayer, String time);

  /// The feed ends; nothing more to load today.
  ///
  /// In en, this message translates to:
  /// **'The cards are closed until tomorrow.'**
  String get doneClosed;

  /// Opens free reading from the reading position.
  ///
  /// In en, this message translates to:
  /// **'Keep reading the Quran'**
  String get doneKeepReading;

  /// Shown when the set was finished after midnight and counts for the previous day.
  ///
  /// In en, this message translates to:
  /// **'Counted for {weekday}'**
  String doneCountedFor(String weekday);

  /// The open ACT quest on the done card. The title comes from the content database.
  ///
  /// In en, this message translates to:
  /// **'Still open: {title}'**
  String doneOpenDeed(String title);

  /// Title of the card after reading the last verse of the Quran in order.
  ///
  /// In en, this message translates to:
  /// **'You completed the Quran.'**
  String get khatmTitle;

  /// Which completion this is.
  ///
  /// In en, this message translates to:
  /// **'Completion #{n}'**
  String khatmNumber(int n);

  /// Opens the reader at the first verse.
  ///
  /// In en, this message translates to:
  /// **'Start again from the beginning'**
  String get khatmStartAgain;

  /// Tooltip and label of the search button on the surah list.
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get quranSearchTooltip;

  /// Continue reading banner on the surah list (khatm order). reference = surah name and verse, e.g. 'Al-Baqarah 2:144'.
  ///
  /// In en, this message translates to:
  /// **'Continue: {reference}'**
  String quranContinue(String reference);

  /// Continue banner when nothing has been read yet (starts at 1:1).
  ///
  /// In en, this message translates to:
  /// **'Start reading: {reference}'**
  String quranStartReading(String reference);

  /// Second line of the continue banner: last verse opened while browsing.
  ///
  /// In en, this message translates to:
  /// **'Last opened: {reference}'**
  String quranLastOpened(String reference);

  /// Segment on the Quran list: list of the 114 surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get quranTabSurahs;

  /// Segment on the Quran list: list of the 30 juz (parts).
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get quranTabJuz;

  /// Title of a juz row. number is already formatted in the digits of the language.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String quranJuzTitle(String number);

  /// Place of revelation of a surah (Mecca).
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get quranRevelationMeccan;

  /// Place of revelation of a surah (Medina).
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get quranRevelationMedinan;

  /// Number of verses of a surah.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verse} other{{count} verses}}'**
  String quranAyahCount(int count);

  /// Reading progress of a surah. percent is formatted, e.g. '43 %'.
  ///
  /// In en, this message translates to:
  /// **'{percent} read'**
  String quranProgressRead(String percent);

  /// Screen reader prefix of a surah row. number is formatted.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String quranSurahNumber(String number);

  /// Reader header subtitle: juz and mushaf page of the verse at the top. Values are formatted.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} · Page {page}'**
  String quranJuzPage(String juz, String page);

  /// Tooltip of the Aa button in the reader and title of its sheet.
  ///
  /// In en, this message translates to:
  /// **'Text settings'**
  String get quranTextSettings;

  /// Label of the Arabic font size selector in the reader sheet.
  ///
  /// In en, this message translates to:
  /// **'Arabic text size'**
  String get quranArabicSize;

  /// Arabic text size: small (short label in a segmented control).
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get quranArabicSizeS;

  /// Arabic text size: medium.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get quranArabicSizeM;

  /// Arabic text size: large.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get quranArabicSizeL;

  /// Arabic text size: extra large.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get quranArabicSizeXL;

  /// Switch in the reader sheet that shows or hides the translation of meaning.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get quranShowTranslation;

  /// Header of the list of available translations in the reader sheet.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get quranTranslationSource;

  /// Attribution of the translation under the text. name = translator or publisher from the content database. Never call it 'the Quran in English'.
  ///
  /// In en, this message translates to:
  /// **'Translation of meaning: {name}'**
  String quranTranslationOfMeaning(String name);

  /// Version and source of the translation (required by the source licence). Values come from the content database.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {attribution}'**
  String quranTranslationVersion(String version, String attribution);

  /// Shown under the Arabic text when no translation exists in the user's language or in English.
  ///
  /// In en, this message translates to:
  /// **'Translation not available in your language'**
  String get quranTranslationMissing;

  /// Small tag on a translation shown in English because the user's language has none.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get quranTranslationFallbackTag;

  /// Screen reader label of the EN tag.
  ///
  /// In en, this message translates to:
  /// **'English translation'**
  String get quranTranslationFallbackLabel;

  /// Button that shows the footnotes of the translator under a verse.
  ///
  /// In en, this message translates to:
  /// **'Translator\'s notes'**
  String get quranFootnotesShow;

  /// Button that hides the footnotes of the translator.
  ///
  /// In en, this message translates to:
  /// **'Hide notes'**
  String get quranFootnotesHide;

  /// Tooltip of the icon on a verse of prostration (sajda).
  ///
  /// In en, this message translates to:
  /// **'Prostration verse'**
  String get quranSajda;

  /// Tooltip of the more button of a verse and title of its sheet.
  ///
  /// In en, this message translates to:
  /// **'Verse actions'**
  String get quranVerseActions;

  /// Action: copy the verse with translation, reference and attribution.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get quranCopy;

  /// Snackbar after copying a verse.
  ///
  /// In en, this message translates to:
  /// **'Verse copied'**
  String get quranCopied;

  /// Action: save the verse (bookmark).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quranSave;

  /// Action: remove the verse from saved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get quranRemoveSaved;

  /// Last line of copied text.
  ///
  /// In en, this message translates to:
  /// **'via {appName}'**
  String quranShareVia(String appName);

  /// Card at the end of a surah that opens the next surah.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String quranNextSurah(String name);

  /// Button at the end of the last surah.
  ///
  /// In en, this message translates to:
  /// **'Back to surahs'**
  String get quranBackToSurahs;

  /// Snackbar when a link points to a verse that does not exist (E-LINK-1).
  ///
  /// In en, this message translates to:
  /// **'That verse could not be found.'**
  String get quranVerseNotFound;

  /// Shown after reading the last verse in continuous reading.
  ///
  /// In en, this message translates to:
  /// **'You completed the Quran'**
  String get quranKhatmTitle;

  /// Button after completing the Quran. name = name of surah 1 from the content database.
  ///
  /// In en, this message translates to:
  /// **'Start again from {name}'**
  String quranKhatmStartAgain(String name);

  /// Screen reader reference of a verse, read in words (not '2 colon 255').
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, verse {ayah}'**
  String quranAyahSemantics(String surah, String ayah);

  /// Hint in the Quran search field.
  ///
  /// In en, this message translates to:
  /// **'Word, surah or 2:255'**
  String get quranSearchHint;

  /// Shown before searching. Nothing is stored about past searches.
  ///
  /// In en, this message translates to:
  /// **'Try a word like \'mercy\' or a surah name.'**
  String get quranSearchTips;

  /// EMPTY-SEARCH title.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String quranSearchEmptyTitle(String query);

  /// EMPTY-SEARCH body.
  ///
  /// In en, this message translates to:
  /// **'Try another word, a surah name or a number like 2:255.'**
  String get quranSearchEmptyBody;

  /// E-SEARCH-1 title.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t working right now'**
  String get quranSearchErrorTitle;

  /// E-SEARCH-1 body.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get quranSearchErrorBody;

  /// First search result when the query is a verse reference.
  ///
  /// In en, this message translates to:
  /// **'Go to {reference}'**
  String quranGoTo(String reference);

  /// Header of full text search results.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get quranSearchVerses;

  /// Tooltip of the button that clears the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get quranClearSearch;

  /// Tooltip of the back button in the reader.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get quranBack;

  /// Tooltip of the close button of sheets in the Quran screens.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get quranClose;

  /// Name of a prayer time row on the prayer screen (transliteration as in docs/01 T8). Sunrise is not a prayer, it ends Fajr.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{Fajr} sunrise{Sunrise} dhuhr{Dhuhr} asr{Asr} maghrib{Maghrib} isha{Isha} other{Prayer}}'**
  String prayerTimeName(String prayer);

  /// Icon button in the prayer screen app bar that opens the qibla compass.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get prayerQiblaTooltip;

  /// Icon button in the prayer screen app bar that opens the hijri calendar.
  ///
  /// In en, this message translates to:
  /// **'Islamic calendar'**
  String get prayerCalendarTooltip;

  /// Icon button that opens prayer time settings.
  ///
  /// In en, this message translates to:
  /// **'Prayer settings'**
  String get prayerSettingsTooltip;

  /// Tooltip of the arrow that shows the previous day on the prayer screen.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get prayerPreviousDay;

  /// Tooltip of the arrow that shows the next day on the prayer screen.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get prayerNextDay;

  /// Time until the next prayer, e.g. 'in 1 h 12 min'.
  ///
  /// In en, this message translates to:
  /// **'in {hours} h {minutes} min'**
  String prayerInHoursMinutes(int hours, int minutes);

  /// Time until the next prayer under one hour, e.g. 'in 12 min'.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String prayerInMinutes(int minutes);

  /// Manual adjustment of a prayer time shown in its row, e.g. '+2 min'. value includes the sign.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String prayerAdjustedLabel(String value);

  /// Summary of calculation settings under the prayer times, e.g. 'Muslim World League · Asr Shafi'i · no adjustments'. Tapping it opens prayer settings.
  ///
  /// In en, this message translates to:
  /// **'{method} · Asr {asr} · {adjust}'**
  String prayerInfoLine(String method, String asr, String adjust);

  /// Part of the settings summary when no prayer time is manually adjusted.
  ///
  /// In en, this message translates to:
  /// **'no adjustments'**
  String get prayerInfoNoAdjust;

  /// Part of the settings summary when some prayer times are manually adjusted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time adjusted} other{{count} times adjusted}}'**
  String prayerInfoAdjusted(int count);

  /// Tooltip/semantics of the city name in the prayer screen header that opens the city search.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get prayerLocationChange;

  /// Empty state title on the prayer screen without a location (EMPTY-PRAYER-LOC).
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get prayerLocationTitle;

  /// Empty state body without a location (EMPTY-PRAYER-LOC).
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated on your phone for where you are.'**
  String get prayerLocationBody;

  /// Button that uses the phone location once to find the nearest city.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get prayerUseMyLocation;

  /// Button that opens the offline city search.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get prayerChooseCity;

  /// Hint above the tracker when no location is set.
  ///
  /// In en, this message translates to:
  /// **'You can still log your prayers without times.'**
  String get prayerNoTimesHint;

  /// Error state title (E-PRAYER-1).
  ///
  /// In en, this message translates to:
  /// **'Prayer times couldn\'t be calculated'**
  String get prayerErrorTitle;

  /// Error state body (E-PRAYER-1).
  ///
  /// In en, this message translates to:
  /// **'Check your location and calculation method.'**
  String get prayerErrorBody;

  /// Banner after midnight before Fajr: the screen shows yesterday so Isha can still be logged.
  ///
  /// In en, this message translates to:
  /// **'Isha time continues until Fajr'**
  String get prayerIshaContinues;

  /// Banner when the phone time zone differs from the saved prayer location (TZ-CHANGE).
  ///
  /// In en, this message translates to:
  /// **'New time zone detected'**
  String get prayerTimeZoneTitle;

  /// Banner body when the phone time zone differs from the saved location.
  ///
  /// In en, this message translates to:
  /// **'Update prayer times for where you are now?'**
  String get prayerTimeZoneBody;

  /// Banner when notifications are blocked (P-NOTIF-BANNER).
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders are off'**
  String get prayerRemindersOffTitle;

  /// Banner body when notifications are blocked.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to be reminded at each prayer time.'**
  String get prayerRemindersOffBody;

  /// Action of the reminders-off banner.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get prayerRemindersTurnOn;

  /// Info line when exact alarms are not allowed (P-EXACT-INFO).
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive up to 10 minutes late or more.'**
  String get prayerExactInfo;

  /// Action of the exact alarm info line.
  ///
  /// In en, this message translates to:
  /// **'Allow exact times'**
  String get prayerExactAllow;

  /// Title of the sheet explaining a high latitude estimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated time'**
  String get prayerEstimatedTitle;

  /// Body of the high latitude sheet.
  ///
  /// In en, this message translates to:
  /// **'On some nights the sun doesn\'t go low enough here to calculate {prayer}. The time is estimated using: {rule}.'**
  String prayerEstimatedBody(String prayer, String rule);

  /// Tooltip of the info button next to estimated prayer times.
  ///
  /// In en, this message translates to:
  /// **'Why is this estimated?'**
  String get prayerEstimatedInfo;

  /// Button that opens prayer settings to change the high latitude rule.
  ///
  /// In en, this message translates to:
  /// **'Change rule'**
  String get prayerChangeRule;

  /// Screen reader action and sheet option: log the prayer as prayed on time.
  ///
  /// In en, this message translates to:
  /// **'Mark on time'**
  String get prayerMarkOnTime;

  /// Screen reader action and sheet option: log the prayer as prayed late.
  ///
  /// In en, this message translates to:
  /// **'Mark late'**
  String get prayerMarkLate;

  /// Screen reader action and sheet option: log the prayer as missed.
  ///
  /// In en, this message translates to:
  /// **'Mark missed'**
  String get prayerMarkMissed;

  /// Sheet option: log a missed prayer as made up later.
  ///
  /// In en, this message translates to:
  /// **'Made up (qada)'**
  String get prayerMarkQada;

  /// Screen reader action: log the prayer as made up later.
  ///
  /// In en, this message translates to:
  /// **'Mark made up'**
  String get prayerMarkQadaAction;

  /// Sheet option and screen reader action: remove the log for this prayer.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get prayerClearLog;

  /// Snackbar after clearing a prayer log, shown with Undo.
  ///
  /// In en, this message translates to:
  /// **'{prayer} log cleared.'**
  String prayerLogCleared(String prayer);

  /// Shown in the status sheet of a prayer that has not started yet.
  ///
  /// In en, this message translates to:
  /// **'You can log it after it begins.'**
  String get prayerFutureHint;

  /// Snackbar after choosing a new city (UPDATED-PRAYER).
  ///
  /// In en, this message translates to:
  /// **'Prayer times updated for {city}.'**
  String prayerUpdatedFor(String city);

  /// Name of a prayer time calculation method.
  ///
  /// In en, this message translates to:
  /// **'{method, select, muslimWorldLeague{Muslim World League} northAmerica{ISNA (North America)} egyptian{Egyptian General Authority of Survey} ummAlQura{Umm al-Qura, Makkah} karachi{University of Islamic Sciences, Karachi} turkiye{Diyanet (Türkiye)} indonesian{Kemenag (Indonesia)} singapore{MUIS (Singapore)} dubai{Dubai} qatar{Qatar} kuwait{Kuwait} gulfRegion{Gulf region} algerian{Algeria} morocco{Morocco} tunisia{Tunisia} jordan{Jordan} france{France (UOIF)} portugal{Portugal} russia{Russia} tehran{Institute of Geophysics, Tehran} jafari{Shia Ithna Ashari (Jafari)} moonsightingCommittee{Moonsighting Committee} jakim{JAKIM (Malaysia)} other{Other}}'**
  String prayerMethodName(String method);

  /// Description of a calculation method by its sun angles.
  ///
  /// In en, this message translates to:
  /// **'Fajr {fajr}°, Isha {isha}°'**
  String prayerMethodAngles(String fajr, String isha);

  /// Description of a method where Isha is a fixed time after Maghrib.
  ///
  /// In en, this message translates to:
  /// **'Fajr {fajr}°, Isha {minutes} min after Maghrib'**
  String prayerMethodInterval(String fajr, String minutes);

  /// Method option: use the usual method of the country of the location.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get prayerMethodAutomatic;

  /// Subtitle of the automatic method option.
  ///
  /// In en, this message translates to:
  /// **'Usual method for your location: {method}'**
  String prayerMethodAutomaticFor(String method);

  /// Asr calculation option: shadow length equals object length.
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi\'i, Maliki, Hanbali)'**
  String get prayerAsrShafi;

  /// Asr calculation option: shadow length is twice the object length.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get prayerAsrHanafi;

  /// Short Asr method name in the settings summary.
  ///
  /// In en, this message translates to:
  /// **'Shafi\'i'**
  String get prayerAsrShortShafi;

  /// Short Asr method name in the settings summary.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get prayerAsrShortHanafi;

  /// Name of a high latitude rule.
  ///
  /// In en, this message translates to:
  /// **'{rule, select, middle_of_night{Middle of the night} seventh_of_night{One seventh of the night} twilight_angle{Twilight angle} other{Automatic}}'**
  String prayerHighLatName(String rule);

  /// Short explanation of a high latitude rule.
  ///
  /// In en, this message translates to:
  /// **'{rule, select, middle_of_night{Fajr and Isha stay within the halves of the night.} seventh_of_night{Isha at most one seventh of the night after Maghrib, Fajr at most one seventh before sunrise.} twilight_angle{The night portion follows the angle of the method.} other{}}'**
  String prayerHighLatDescription(String rule);

  /// Title of the prayer settings screen.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerSettingsTitle;

  /// Section title: location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get prayerSettingsLocation;

  /// Section title: calculation method.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get prayerSettingsMethod;

  /// Section title: Asr calculation.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerSettingsAsr;

  /// Section title: rule for places where Fajr or Isha can't always be calculated.
  ///
  /// In en, this message translates to:
  /// **'High latitude rule'**
  String get prayerSettingsHighLat;

  /// Help text of the high latitude section.
  ///
  /// In en, this message translates to:
  /// **'Used when the sun doesn\'t go low enough for Fajr or Isha.'**
  String get prayerSettingsHighLatHelp;

  /// Section title: manual minute adjustments per prayer.
  ///
  /// In en, this message translates to:
  /// **'Manual adjustments'**
  String get prayerSettingsAdjust;

  /// Help text of the manual adjustments section.
  ///
  /// In en, this message translates to:
  /// **'Move a time if your local mosque uses a different one.'**
  String get prayerSettingsAdjustHelp;

  /// Section title: preview of today's prayer times.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get prayerSettingsPreview;

  /// Value of a manual adjustment stepper, e.g. '+2 min' or '0 min'.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String prayerAdjustMinutes(String value);

  /// Tooltip of the minus button of an adjustment stepper.
  ///
  /// In en, this message translates to:
  /// **'Earlier by 1 minute'**
  String get prayerAdjustEarlier;

  /// Tooltip of the plus button of an adjustment stepper.
  ///
  /// In en, this message translates to:
  /// **'Later by 1 minute'**
  String get prayerAdjustLater;

  /// Screen reader label of an adjustment stepper.
  ///
  /// In en, this message translates to:
  /// **'{prayer} adjustment, {value} minutes'**
  String prayerAdjustSemantics(String prayer, String value);

  /// Sheet after moving to another country when the method was chosen manually (METHOD-SUGGEST).
  ///
  /// In en, this message translates to:
  /// **'{method} is common in {country}'**
  String prayerMethodSuggestTitle(String method, String country);

  /// Body of the method suggestion sheet.
  ///
  /// In en, this message translates to:
  /// **'Switch the calculation method?'**
  String get prayerMethodSuggestBody;

  /// Accept the suggested method.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get prayerMethodSuggestSwitch;

  /// Keep the current method.
  ///
  /// In en, this message translates to:
  /// **'Keep {method}'**
  String prayerMethodSuggestKeep(String method);

  /// Title of the offline city search screen.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get citySearchTitle;

  /// Placeholder of the city search field.
  ///
  /// In en, this message translates to:
  /// **'Search for a city'**
  String get citySearchHint;

  /// Shown before typing in the city search.
  ///
  /// In en, this message translates to:
  /// **'Type the first letters of your city. The list works offline.'**
  String get citySearchTips;

  /// Empty result of the city search.
  ///
  /// In en, this message translates to:
  /// **'No cities found for \"{query}\"'**
  String citySearchEmptyTitle(String query);

  /// Body of the empty city search result.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling or try a bigger city nearby.'**
  String get citySearchEmptyBody;

  /// Tooltip of the button that clears the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get citySearchClear;

  /// Currently saved city shown above the search results.
  ///
  /// In en, this message translates to:
  /// **'Current: {city}'**
  String citySearchCurrent(String city);

  /// Shown while the phone location is being read.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get cityLocating;

  /// Error after the phone location failed (E-LOC-1).
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your location'**
  String get cityLocationErrorTitle;

  /// Body of the location error (E-LOC-1).
  ///
  /// In en, this message translates to:
  /// **'Choose your city instead. It works just as well.'**
  String get cityLocationErrorBody;

  /// Title of the qibla compass screen.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// Instruction to rotate the phone towards the qibla.
  ///
  /// In en, this message translates to:
  /// **'Turn right {degrees}°'**
  String qiblaTurnRight(String degrees);

  /// Instruction to rotate the phone towards the qibla.
  ///
  /// In en, this message translates to:
  /// **'Turn left {degrees}°'**
  String qiblaTurnLeft(String degrees);

  /// Shown when the phone points to the qibla (within 5 degrees).
  ///
  /// In en, this message translates to:
  /// **'Facing the Qibla'**
  String get qiblaFacing;

  /// Qibla direction in degrees clockwise from north.
  ///
  /// In en, this message translates to:
  /// **'Qibla {degrees}° from north'**
  String qiblaBearing(String degrees);

  /// Compass accuracy is low (Q-CALIBRATE).
  ///
  /// In en, this message translates to:
  /// **'Calibrating…'**
  String get qiblaCalibrateTitle;

  /// Calibration instruction (Q-CALIBRATE).
  ///
  /// In en, this message translates to:
  /// **'Move your phone in a figure 8.'**
  String get qiblaCalibrateBody;

  /// The phone has no compass sensor (Q-NOSENSOR).
  ///
  /// In en, this message translates to:
  /// **'Compass not available'**
  String get qiblaNoSensorTitle;

  /// Fallback without a compass (Q-NOSENSOR).
  ///
  /// In en, this message translates to:
  /// **'The Qibla is {degrees}° from north.'**
  String qiblaNoSensorBody(String degrees);

  /// Hint under the compass.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat, away from metal and magnets.'**
  String get qiblaHint;

  /// Screen reader label of the compass dial.
  ///
  /// In en, this message translates to:
  /// **'Compass. Qibla is {degrees}° from north.'**
  String qiblaDialSemantics(String degrees);

  /// Location the qibla direction is calculated for.
  ///
  /// In en, this message translates to:
  /// **'From {city}'**
  String qiblaFrom(String city);

  /// Letter for north on the compass dial.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get qiblaNorth;

  /// Title of the hijri calendar screen.
  ///
  /// In en, this message translates to:
  /// **'Islamic calendar'**
  String get calendarTitle;

  /// Tooltip of the previous month button.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// Tooltip of the next month button.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// Hijri month header, e.g. 'Jumada al-Ula 1448'.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String calendarMonthTitle(String month, String year);

  /// Section title above the list of events in the shown month.
  ///
  /// In en, this message translates to:
  /// **'Events this month'**
  String get calendarEventsTitle;

  /// Shown when the month has no events (EMPTY-CAL-MONTH).
  ///
  /// In en, this message translates to:
  /// **'No special days this month'**
  String get calendarEmptyTitle;

  /// Next event after an empty month (EMPTY-CAL-MONTH).
  ///
  /// In en, this message translates to:
  /// **'Next: {event} on {date}.'**
  String calendarEmptyNext(String event, String date);

  /// Error state of the calendar (E-CAL-1).
  ///
  /// In en, this message translates to:
  /// **'The calendar couldn\'t load'**
  String get calendarErrorTitle;

  /// Error state body of the calendar (E-CAL-1).
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get calendarErrorBody;

  /// Line under the calendar with the current hijri offset, e.g. '+1 day'.
  ///
  /// In en, this message translates to:
  /// **'Hijri date offset: {offset}'**
  String calendarOffsetLine(String offset);

  /// Button that changes the hijri offset.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get calendarOffsetChange;

  /// Title of the hijri offset setting.
  ///
  /// In en, this message translates to:
  /// **'Hijri date'**
  String get calendarOffsetTitle;

  /// Help text of the hijri offset setting.
  ///
  /// In en, this message translates to:
  /// **'If your community began the month a day earlier or later, adjust the date here. Events move with it.'**
  String get calendarOffsetHelp;

  /// Preview of today's hijri date in the offset setting.
  ///
  /// In en, this message translates to:
  /// **'Today is {date}'**
  String calendarOffsetPreview(String date);

  /// Hijri offset value. Keys: p0, p1, p2 (plus), m1, m2 (minus).
  ///
  /// In en, this message translates to:
  /// **'{value, select, p0{0 days} p1{+1 day} p2{+2 days} m1{−1 day} m2{−2 days} other{}}'**
  String calendarOffsetDays(String value);

  /// Tooltip of the minus button of the hijri offset stepper.
  ///
  /// In en, this message translates to:
  /// **'One day earlier'**
  String get calendarOffsetEarlier;

  /// Tooltip of the plus button of the hijri offset stepper.
  ///
  /// In en, this message translates to:
  /// **'One day later'**
  String get calendarOffsetLater;

  /// Marks today in the calendar (screen reader) and the button that returns to the current month.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Screen reader suffix of a calendar day with an event.
  ///
  /// In en, this message translates to:
  /// **'has events'**
  String get calendarHasEvents;

  /// Day sheet without events.
  ///
  /// In en, this message translates to:
  /// **'No special events on this day.'**
  String get calendarDayEmpty;

  /// Tag next to an event text shown in English because the user's language is missing.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get calendarEnglishTag;

  /// Hijri date, e.g. '17 Jumada al-Ula 1448'.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}'**
  String hijriDate(String day, String month, String year);

  /// Hijri month name (transliteration). Key m1..m12 is the month number.
  ///
  /// In en, this message translates to:
  /// **'{month, select, m1{Muharram} m2{Safar} m3{Rabi al-Awwal} m4{Rabi al-Thani} m5{Jumada al-Ula} m6{Jumada al-Akhirah} m7{Rajab} m8{Sha\'ban} m9{Ramadan} m10{Shawwal} m11{Dhu al-Qa\'dah} m12{Dhu al-Hijjah} other{}}'**
  String hijriMonthName(String month);

  /// Title of the private progress tab (Journey, docs/02 A8.1).
  ///
  /// In en, this message translates to:
  /// **'My journey'**
  String get journeyTitle;

  /// Shown on Journey instead of the intention when the user has not written one. Tapping opens the intention editor.
  ///
  /// In en, this message translates to:
  /// **'Add your intention'**
  String get journeyNiyyahEmpty;

  /// Tooltip of the pencil button next to the intention on Journey.
  ///
  /// In en, this message translates to:
  /// **'Edit intention'**
  String get journeyNiyyahEdit;

  /// Title of the dialog that edits the intention (same choices as in onboarding). It stays on the phone.
  ///
  /// In en, this message translates to:
  /// **'Your intention'**
  String get journeyNiyyahDialogTitle;

  /// Saves the edited intention.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get journeyNiyyahSave;

  /// Closes the intention dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get journeyNiyyahCancel;

  /// Tooltip of the arrow that shows the previous month of the personal calendar.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get journeyPreviousMonth;

  /// Tooltip of the arrow that shows the next month of the personal calendar.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get journeyNextMonth;

  /// State of a day in the personal calendar, read by the screen reader after the date and shown in the day detail. 'missed' must stay neutral, never blaming.
  ///
  /// In en, this message translates to:
  /// **'{state, select, done{Completed} grace{Covered by a grace day} missed{Not completed} excused{Excused} today{Today} future{Upcoming} other{No record}}'**
  String journeyDayState(String state);

  /// Calendar legend: a filled circle means the day was completed (daily cards or an intention).
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get journeyLegendDone;

  /// Calendar legend: a half filled circle means a grace day covered the day.
  ///
  /// In en, this message translates to:
  /// **'Grace day'**
  String get journeyLegendGrace;

  /// Calendar legend: a small dot means the day was not completed. Neutral wording.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get journeyLegendMissed;

  /// Private streak of completed days on Journey. Hidden in Simple mode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1-day streak} other{{count}-day streak}}'**
  String journeyStreak(int count);

  /// Longest streak, shown after the current streak, e.g. '6-day streak · Longest 14'. count is already formatted.
  ///
  /// In en, this message translates to:
  /// **'Longest {count}'**
  String journeyLongest(String count);

  /// Remaining grace days on Journey.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no grace days left} one{1 grace day} other{{count} grace days}}'**
  String journeyGraceLeft(int count);

  /// When the used grace days come back, e.g. 'Grace days refill on Monday, November 2'.
  ///
  /// In en, this message translates to:
  /// **'Grace days refill on {date}'**
  String journeyGraceRefill(String date);

  /// EMPTY-JOURNEY title for a new user (docs/01 7.7).
  ///
  /// In en, this message translates to:
  /// **'Your journey starts today'**
  String get journeyEmptyTitle;

  /// EMPTY-JOURNEY body (docs/01 7.7).
  ///
  /// In en, this message translates to:
  /// **'Each day you complete your cards or an intention will appear here.'**
  String get journeyEmptyBody;

  /// E-DB-1 title on Journey, Saved and the day detail.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get journeyErrorTitle;

  /// E-DB-1 body.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe. Please try again.'**
  String get journeyErrorBody;

  /// Section title of the surah map on Journey.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get journeyQuranTitle;

  /// Share of all verses the user has read, e.g. '12% read'. percent is already formatted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% read'**
  String journeyQuranPercent(String percent);

  /// Shown above the empty surah map before the user reads any verse.
  ///
  /// In en, this message translates to:
  /// **'Verses you read will fill this map.'**
  String get journeyQuranMapEmpty;

  /// Text legend of the surah map (not only color).
  ///
  /// In en, this message translates to:
  /// **'Each square is a surah. The fuller it is, the more of it you have read.'**
  String get journeyQuranMapLegend;

  /// Screen reader label of one surah square, e.g. 'Al-Baqarah, 43% read'.
  ///
  /// In en, this message translates to:
  /// **'{surah}, {percent}% read'**
  String journeySurahProgress(String surah, String percent);

  /// Surah label when its name is not available.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}'**
  String journeySurahFallback(String number);

  /// Number of completed readings of the whole Quran. count is already formatted.
  ///
  /// In en, this message translates to:
  /// **'Khatm: {count}'**
  String journeyKhatm(String count);

  /// Button with the next verse in the user's reading of the whole Quran, e.g. 'Next verse 2:144'.
  ///
  /// In en, this message translates to:
  /// **'Next verse {ref}'**
  String journeyNextVerse(String ref);

  /// Row that opens the word review (only when words are enabled).
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get journeyWords;

  /// Button on Journey that opens the saved cards.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Saved cards} other{Saved cards ({count})}}'**
  String journeySavedButton(int count);

  /// Title of the saved cards screen.
  ///
  /// In en, this message translates to:
  /// **'Saved cards'**
  String get journeySavedTitle;

  /// Filter chips on the saved cards screen.
  ///
  /// In en, this message translates to:
  /// **'{type, select, all{All} ayah{Verses} hadith{Hadith} dua{Dua} name{Names} reflection{Reflections} other{All}}'**
  String journeySavedFilter(String type);

  /// Type of a saved card shown in its row.
  ///
  /// In en, this message translates to:
  /// **'{type, select, ayah{Verse} hadith{Hadith} dua{Dua} name{Name of Allah} reflection{Reflection} other{Card}}'**
  String journeyCardType(String type);

  /// EMPTY-SAVED title (docs/01 7.7).
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get journeySavedEmptyTitle;

  /// EMPTY-SAVED body (docs/01 7.7).
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any card to keep it here.'**
  String get journeySavedEmptyBody;

  /// Screen reader action and swipe action that removes a card from saved.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get journeySavedRemove;

  /// Snackbar after a card was removed from saved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get journeySavedRemoved;

  /// Snackbar action that brings back the removed card.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get journeyUndo;

  /// Tooltip of the button that closes the fullscreen card view.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get journeyClose;

  /// Position in the fullscreen card view, e.g. '3 of 18'. Numbers are already formatted.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String journeyCardPosition(String n, String total);

  /// Progress of the daily cards on that day, e.g. 'Daily cards: 10/10'. Numbers are already formatted.
  ///
  /// In en, this message translates to:
  /// **'Daily cards: {done}/{total}'**
  String journeyDaySet(String done, String total);

  /// Local time when the daily cards were completed.
  ///
  /// In en, this message translates to:
  /// **'Completed at {time}'**
  String journeyDayCompletedAt(String time);

  /// Day detail when no daily set exists for that day.
  ///
  /// In en, this message translates to:
  /// **'No daily cards on this day.'**
  String get journeyDayNoSet;

  /// Opens a read-only view of the cards of that day.
  ///
  /// In en, this message translates to:
  /// **'View cards'**
  String get journeyDayViewCards;

  /// What completed the day in the day detail.
  ///
  /// In en, this message translates to:
  /// **'{source, select, set{Daily cards completed} quest{An intention completed} other{-}}'**
  String journeyDaySources(String source);

  /// Section title of the logged prayers in the day detail.
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get journeyDayPrayers;

  /// Logged state of a prayer in the day detail (neutral wording).
  ///
  /// In en, this message translates to:
  /// **'{status, select, on_time{On time} late{Late} missed{Missed} qada{Made up} other{Not logged}}'**
  String journeyPrayerStatus(String status);

  /// Title of the settings screen (docs/02 A10.0).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get setTitle;

  /// Settings row that opens app blocking settings (only in the full edition).
  ///
  /// In en, this message translates to:
  /// **'The gate'**
  String get setGate;

  /// Current state shown in a settings row.
  ///
  /// In en, this message translates to:
  /// **'{value, select, true{On} other{Off}}'**
  String setOnOff(String value);

  /// Settings row that opens prayer time settings.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get setPrayerTimes;

  /// Settings row and screen title for notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get setNotifications;

  /// Settings row and screen title for app language and Quran translation.
  ///
  /// In en, this message translates to:
  /// **'Language & translation'**
  String get setLanguage;

  /// Settings row and screen title for theme, Arabic text size and daily set options.
  ///
  /// In en, this message translates to:
  /// **'Daily set & display'**
  String get setDisplay;

  /// Settings row for recitation audio settings.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get setAudio;

  /// Settings row that opens the hijri date adjustment.
  ///
  /// In en, this message translates to:
  /// **'Hijri calendar'**
  String get setHijriCalendar;

  /// Settings row and screen title for privacy settings.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get setPrivacy;

  /// Settings row and screen title listing content sources, their versions and licenses.
  ///
  /// In en, this message translates to:
  /// **'Sources & licenses'**
  String get setSources;

  /// Settings row and screen title with app version and disclaimers.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get setAbout;

  /// Section header for choosing the language of the app.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get setAppLanguage;

  /// Option to follow the language of the phone.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get setDeviceLanguage;

  /// Section header for choosing the Quran translation in the current language.
  ///
  /// In en, this message translates to:
  /// **'Quran translation'**
  String get setTranslation;

  /// Section header for text display options.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get setDisplayOptions;

  /// Switch that shows Latin transliteration of Arabic text.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get setTranslit;

  /// Explanation under the transliteration switch.
  ///
  /// In en, this message translates to:
  /// **'Show Arabic in Latin letters where available.'**
  String get setTranslitHelp;

  /// Shown instead of the translation choice when the app language is Arabic.
  ///
  /// In en, this message translates to:
  /// **'In Arabic, the Quran is shown without a translation.'**
  String get setTranslationArabic;

  /// Shown when the content has no Quran translation in the current language.
  ///
  /// In en, this message translates to:
  /// **'No translation is available in this language yet. English is shown instead.'**
  String get setTranslationNone;

  /// Version and license of a content source, e.g. 'Version 1.1 · License: CC BY 3.0'.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · License: {license}'**
  String setSourceVersionLicense(String version, String license);

  /// Required note under Quran translations (docs/11 12.2). Legal text, translate faithfully.
  ///
  /// In en, this message translates to:
  /// **'Translations convey the meanings of the Qur\'an; they are not the Qur\'an itself.'**
  String get setTranslationDisclaimer;

  /// Error state title on settings screens that read content.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this'**
  String get setLoadErrorTitle;

  /// Error state body on settings screens that read content.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get setLoadErrorBody;

  /// Section header for light/dark theme choice.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get setTheme;

  /// Note under the theme header: high contrast is taken from Android accessibility settings.
  ///
  /// In en, this message translates to:
  /// **'High contrast follows your phone settings.'**
  String get setHighContrastNote;

  /// Theme option name.
  ///
  /// In en, this message translates to:
  /// **'{value, select, light{Light} dark{Dark} other{Same as phone}}'**
  String setThemeName(String value);

  /// Section header for the size of Arabic text, with a preview.
  ///
  /// In en, this message translates to:
  /// **'Arabic text size'**
  String get setArabicSize;

  /// Section header for daily set options.
  ///
  /// In en, this message translates to:
  /// **'Daily set'**
  String get setDailySet;

  /// Switch that hides streaks and grace days.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get setSimpleMode;

  /// Explanation under the simple mode switch.
  ///
  /// In en, this message translates to:
  /// **'Hide streaks and counters.'**
  String get setSimpleModeHelp;

  /// Section header for the number of cards in the daily set.
  ///
  /// In en, this message translates to:
  /// **'Cards per day'**
  String get setCardsCount;

  /// Explanation that the number of cards changes from the next day.
  ///
  /// In en, this message translates to:
  /// **'Changes apply from tomorrow. Today\'s set stays the same.'**
  String get setCardsCountHelp;

  /// Option for the number of daily cards.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String setCardsCountValue(int count);

  /// Banner when the system blocks notifications of the app.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked by Android.'**
  String get setNotifBlocked;

  /// Button that opens the Android settings of the app.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get setOpenSettings;

  /// Section header with a switch for each of the five prayers.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders'**
  String get setPrayerReminders;

  /// Section header for the morning notification.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get setMorning;

  /// Switch for the daily morning notification.
  ///
  /// In en, this message translates to:
  /// **'Morning reminder'**
  String get setMorningToggle;

  /// Explanation under the morning reminder switch.
  ///
  /// In en, this message translates to:
  /// **'A reminder that your daily cards are ready.'**
  String get setMorningHelp;

  /// Row that opens a time picker for the morning reminder.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get setMorningTime;

  /// Section header for how notifications look on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'Lock screen'**
  String get setLockScreen;

  /// Switch: notifications show only 'it's time' without the prayer name.
  ///
  /// In en, this message translates to:
  /// **'Private text'**
  String get setPrivateText;

  /// Explanation under the private text switch.
  ///
  /// In en, this message translates to:
  /// **'Show only the app name and time on the lock screen, without what the reminder is about.'**
  String get setPrivateTextHelp;

  /// Section header for the Android exact alarm permission.
  ///
  /// In en, this message translates to:
  /// **'Exact reminders'**
  String get setExactAlarms;

  /// Shown while the permission state is being read.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get setStatusUnknown;

  /// Exact alarms are allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get setExactOn;

  /// Exact alarms are not allowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get setExactOff;

  /// Explanation of the exact alarm permission.
  ///
  /// In en, this message translates to:
  /// **'Without exact reminders, prayer reminders may arrive up to 10 minutes late or more.'**
  String get setExactHelp;

  /// Button that opens the Android screen to allow exact alarms.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get setAllow;

  /// Note at the end of notification settings (docs/11 12.1).
  ///
  /// In en, this message translates to:
  /// **'Reminders may be delayed by Android or battery settings.'**
  String get setOsDelayNote;

  /// Intro on the privacy screen (docs/11 12.4).
  ///
  /// In en, this message translates to:
  /// **'Your prayers, reading and other logs stay on this phone. We do not receive them.'**
  String get setPrivacyIntro;

  /// Section header for analytics and crash report consent.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get setSharing;

  /// Explanation under the sharing header.
  ///
  /// In en, this message translates to:
  /// **'Both are off unless you turn them on. You can turn them off at any time.'**
  String get setSharingHelp;

  /// Switch for anonymous analytics (opt-in).
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage'**
  String get setAnalytics;

  /// Switch for sending crash reports (opt-in).
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get setCrashReports;

  /// Row that opens the privacy policy in the browser.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get setPrivacyPolicy;

  /// Section header for deleting all data.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get setYourData;

  /// Explanation above the delete all data button.
  ///
  /// In en, this message translates to:
  /// **'Deleting removes everything you saved in the app and starts again from the beginning.'**
  String get setYourDataHelp;

  /// Destructive button that deletes all user data.
  ///
  /// In en, this message translates to:
  /// **'Delete all my data'**
  String get setDeleteAll;

  /// Title of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get setDeleteTitle;

  /// Body of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Your logs, saved cards, settings and progress will be deleted from this phone. This can\'t be undone.'**
  String get setDeleteBody;

  /// Label of the text field in the delete dialog. word is always DELETE (not translated).
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String setDeleteTypeLabel(String word);

  /// Confirm button of the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get setDeleteConfirm;

  /// Intro of the sources and licenses screen (docs/09 4).
  ///
  /// In en, this message translates to:
  /// **'Prosoche shows these texts without any changes, as published by their sources.'**
  String get setSourcesIntro;

  /// Empty state when content has no source records.
  ///
  /// In en, this message translates to:
  /// **'No sources found'**
  String get setSourcesEmpty;

  /// Group header on the sources screen by type of content.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, quran_text{Quran text} quran_text_search{Quran text for search} quran_metadata{Quran metadata} translation{Translations of the meanings} word{Word by word} hadith{Hadith} dua{Dua} name{Names of Allah} reflection{Reflections} curated{Prosoche content} audio{Recitations} city{Places} font{Fonts} other{Other}}'**
  String setSourceKind(String kind);

  /// Version of the bundled content, e.g. 'Content version 2026.11.1'.
  ///
  /// In en, this message translates to:
  /// **'Content version {version}'**
  String setContentVersion(String version);

  /// Note at the end of the sources screen.
  ///
  /// In en, this message translates to:
  /// **'If you notice an error in a text, please report it. We will review it and pass it on to the source.'**
  String get setSourcesReport;

  /// Link to the full license text in the source detail.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get setLicenseLink;

  /// Snackbar when the browser can't be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {url}'**
  String setLinkFailed(String url);

  /// Button that opens the list of open-source licenses (packages and fonts).
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get setOpenSourceLicenses;

  /// Row title with the app version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get setAppVersion;

  /// Row title with the version of the bundled content.
  ///
  /// In en, this message translates to:
  /// **'Content version'**
  String get setContentVersionTitle;

  /// Shown when a value can't be read.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get setUnavailable;

  /// Section header for disclaimers on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Please note'**
  String get setDisclaimers;

  /// Prayer times disclaimer (docs/11 12.1). Legal text, translate faithfully.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated on your device using the method you selected. Results can differ from your local mosque by several minutes, especially at high latitudes and around daylight saving changes. Please confirm times with your local mosque or Islamic authority and adjust them in Settings if needed. Reminders may be delayed by the operating system or battery settings.'**
  String get setDisclaimerPrayer;

  /// Quran text and translation disclaimer (docs/11 12.2). Legal text, translate faithfully.
  ///
  /// In en, this message translates to:
  /// **'The Arabic text of the Qur\'an is the Tanzil Uthmani text (Tanzil Project, tanzil.net), shown without any modification. Translations convey the meanings of the Qur\'an; they are not the Qur\'an itself.'**
  String get setDisclaimerQuran;

  /// Religious content disclaimer (docs/11 12.3). Legal text, translate faithfully.
  ///
  /// In en, this message translates to:
  /// **'Prosoche is a reminder and habit tool. It does not issue religious rulings (fatwas). For questions of religious practice, please consult a qualified scholar.'**
  String get setDisclaimerRulings;

  /// Section header with links on the About screen.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get setMore;

  /// Row that opens the feedback form in the browser.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get setFeedback;

  /// Row on the About screen for the downloaded hadith explanations pack.
  ///
  /// In en, this message translates to:
  /// **'Hadith explanations'**
  String get setHadithExtra;

  /// Size of downloaded content, e.g. '12.4 MB on this phone'.
  ///
  /// In en, this message translates to:
  /// **'{size} MB on this phone'**
  String setSizeMb(String size);

  /// Confirm dialog title for deleting the downloaded explanations pack.
  ///
  /// In en, this message translates to:
  /// **'Delete hadith explanations?'**
  String get setHadithExtraDeleteTitle;

  /// Confirm dialog body for deleting the downloaded explanations pack.
  ///
  /// In en, this message translates to:
  /// **'You can download them again from a hadith card.'**
  String get setHadithExtraDeleteBody;

  /// Header of the Ramadan card on Today during the fasting day (fajr to maghrib), e.g. 'Ramadan · day 12'.
  ///
  /// In en, this message translates to:
  /// **'Ramadan · day {day}'**
  String ramadanDayLabel(int day);

  /// Header of the Ramadan card on Today between maghrib and fajr. The Islamic day starts at maghrib, so the evening of day 26 is night 27.
  ///
  /// In en, this message translates to:
  /// **'Ramadan · night {night}'**
  String ramadanNightLabel(int night);

  /// Main line of the Ramadan card before fajr: time when suhur (pre-dawn meal) ends, e.g. 'Suhur ends at 05:12'.
  ///
  /// In en, this message translates to:
  /// **'Suhur ends at {time}'**
  String ramadanSuhurEndsAt(String time);

  /// Main line of the Ramadan card during the day: time of iftar (maghrib), e.g. 'Iftar at 17:02'.
  ///
  /// In en, this message translates to:
  /// **'Iftar at {time}'**
  String ramadanIftarAt(String time);

  /// Countdown under the suhur/iftar time, e.g. 'in 2 h 14 min'.
  ///
  /// In en, this message translates to:
  /// **'in {hours} h {minutes} min'**
  String ramadanInHoursMinutes(int hours, int minutes);

  /// Countdown under one hour, e.g. 'in 12 min'.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String ramadanInMinutes(int minutes);

  /// Shown in the Ramadan card when no location is set (no prayer times).
  ///
  /// In en, this message translates to:
  /// **'Set your location to see suhur and iftar times.'**
  String get ramadanSetLocation;

  /// Button in the Ramadan card that opens location settings.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get ramadanSetLocationAction;

  /// Info line a few days before Ramadan (calculated start date).
  ///
  /// In en, this message translates to:
  /// **'Ramadan is expected to start on {date}.'**
  String ramadanExpectedStart(String date);

  /// Info line after the start date was confirmed.
  ///
  /// In en, this message translates to:
  /// **'Ramadan starts on {date}.'**
  String ramadanStartsOn(String date);

  /// Question card on 29 Shaban afternoon. The user answers according to the local moon sighting.
  ///
  /// In en, this message translates to:
  /// **'When does Ramadan start in your community?'**
  String get ramadanStartQuestion;

  /// Answer: Ramadan (first fast) starts tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get ramadanStartTomorrow;

  /// Answer: Ramadan (first fast) starts the day after tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Day after tomorrow'**
  String get ramadanStartDayAfter;

  /// Answer: keep the calculated date (Umm al-Qura calendar with the user's offset).
  ///
  /// In en, this message translates to:
  /// **'I don\'t know, use the calculation'**
  String get ramadanUseCalculation;

  /// Question card on the afternoon of day 29 of Ramadan. Eid = Eid al-Fitr.
  ///
  /// In en, this message translates to:
  /// **'Is Eid tomorrow in your community?'**
  String get ramadanEndQuestion;

  /// Answer yes to the Eid question.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ramadanAnswerYes;

  /// Answer no to the Eid question (Ramadan has 30 days).
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get ramadanAnswerNo;

  /// Title of the optional fast log after iftar. Neutral, no judgement.
  ///
  /// In en, this message translates to:
  /// **'Your fast on day {day}'**
  String ramadanFastTitle(int day);

  /// Fast log option: I fasted.
  ///
  /// In en, this message translates to:
  /// **'Fasted'**
  String get ramadanFastFasted;

  /// Fast log option: I did not fast today. Neutral wording, no judgement.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get ramadanFastNotFasted;

  /// Fast log option: excused from fasting (no reason is asked or stored).
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get ramadanFastExcused;

  /// Title of the suhur reminder notification (replaces the morning reminder during Ramadan), e.g. 'Suhur · 04:27'. No verses or names of Allah.
  ///
  /// In en, this message translates to:
  /// **'Suhur · {time}'**
  String ramadanNotifSuhurTitle(String time);

  /// Body of the suhur reminder notification.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Suhur ends in 1 minute.} other{Suhur ends in {minutes} minutes.}}'**
  String ramadanNotifSuhurBody(int minutes);

  /// Title of the maghrib notification on a fasting day (merged with iftar), e.g. 'Iftar · 17:02'. No verses or names of Allah.
  ///
  /// In en, this message translates to:
  /// **'Iftar · {time}'**
  String ramadanNotifIftarTitle(String time);

  /// Small line under a hadith with the source of the text and its version, e.g. 'Source: HadeethEnc.com - Encyclopedia of Translated Prophetic Hadiths, version snapshot-2026-10-29'. The attribution comes from the content database and is not translated.
  ///
  /// In en, this message translates to:
  /// **'Source: {attribution}'**
  String cardSourceLine(String attribution);

  /// Like cardSourceLine, used when the attribution text from the database does not contain the version number.
  ///
  /// In en, this message translates to:
  /// **'Source: {attribution}, version {version}'**
  String cardSourceLineVersion(String attribution, String version);

  /// Report a problem sheet: explains what the report contains and that the user sends it.
  ///
  /// In en, this message translates to:
  /// **'The report is a text file that you send yourself, for example by e-mail. It contains the card reference and technical details from the app. Your prayers, reading and location are not included.'**
  String get reportBody;

  /// Report a problem sheet: label of the free text field.
  ///
  /// In en, this message translates to:
  /// **'What is wrong? (optional)'**
  String get reportDescriptionLabel;

  /// Report a problem sheet: checkbox to include the app's technical log.
  ///
  /// In en, this message translates to:
  /// **'Attach technical log'**
  String get reportIncludeLog;

  /// Report a problem sheet: help text under the technical log checkbox.
  ///
  /// In en, this message translates to:
  /// **'Errors and app events, without your data.'**
  String get reportIncludeLogHelp;

  /// Report a problem sheet: expandable preview of the exact report text.
  ///
  /// In en, this message translates to:
  /// **'Show the exact text'**
  String get reportPreview;

  /// Report a problem sheet: opens the system share sheet with the report file.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get reportShare;

  /// Report a problem sheet: error when the share sheet could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Sharing did not open. Try again.'**
  String get reportShareFailed;

  /// Subject of the shared report (e.g. e-mail subject).
  ///
  /// In en, this message translates to:
  /// **'{app} problem report'**
  String reportShareSubject(String app);

  /// Settings > About: opens the report a problem sheet.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get setReportProblem;

  /// Banner on Today when the app gate is on but a needed permission is missing.
  ///
  /// In en, this message translates to:
  /// **'The gate is paused'**
  String get todayGatePaused;

  /// Banner on Today: body under 'The gate is paused'.
  ///
  /// In en, this message translates to:
  /// **'A permission it needs is off.'**
  String get todayGatePausedBody;

  /// Banner on Today: opens the gate permissions screen.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get todayGateFix;

  /// Settings: tooltip/label of the warning icon next to 'The gate' when a permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get setGateNeedsAttention;

  /// Android notification channel name for prayer time reminders (system settings).
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get notifChannelPrayer;

  /// Android notification channel description for prayer time reminders.
  ///
  /// In en, this message translates to:
  /// **'A quiet notice at each prayer time.'**
  String get notifChannelPrayerDescription;

  /// Android notification channel name for the morning reminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get notifChannelDaily;

  /// Android notification channel description for the morning reminder.
  ///
  /// In en, this message translates to:
  /// **'One reminder in the morning when your cards are ready.'**
  String get notifChannelDailyDescription;

  /// Android notification channel name for app messages (reminders paused soon, missing permissions).
  ///
  /// In en, this message translates to:
  /// **'App messages'**
  String get notifChannelSystem;

  /// Android notification channel description for app messages.
  ///
  /// In en, this message translates to:
  /// **'Rare messages about reminders and permissions.'**
  String get notifChannelSystemDescription;

  /// Prayer name used in prayer notifications. Transliteration as in the prayer screen.
  ///
  /// In en, this message translates to:
  /// **'{prayer, select, fajr{Fajr} dhuhr{Dhuhr} asr{Asr} maghrib{Maghrib} isha{Isha} jumuah{Jumu\'ah} other{Prayer}}'**
  String notifPrayerName(String prayer);

  /// Title of a prayer notification, e.g. 'Asr · 15:12'. No verses or names of Allah.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · {time}'**
  String notifPrayerTitle(String prayer, String time);

  /// Body of a prayer notification. No verses or names of Allah.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer}.'**
  String notifPrayerBody(String prayer);

  /// Neutral title of a prayer notification in private mode (lock screen), e.g. 'Prosoche · 15:12'.
  ///
  /// In en, this message translates to:
  /// **'{appName} · {time}'**
  String notifPrivateTitle(String appName, String time);

  /// Neutral body of a prayer notification in private mode.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get notifPrivateBody;

  /// Title of the morning reminder.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get notifMorningTitle;

  /// Body of the morning reminder.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cards are ready. {minutes, plural, =1{About 1 minute.} other{About {minutes} minutes.}}'**
  String notifMorningBody(int minutes);

  /// Body of the morning reminder on an event day. Title is the event name.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cards are ready, with something special for {eventName}.'**
  String notifMorningEventBody(String eventName);

  /// Neutral body of the morning reminder in private mode. Title is the app name.
  ///
  /// In en, this message translates to:
  /// **'Your daily reminder'**
  String get notifMorningPrivateBody;

  /// Last planned notification when the app was not opened for 10 days.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminders paused soon'**
  String get notifOpenAppTitle;

  /// Body of the last planned notification.
  ///
  /// In en, this message translates to:
  /// **'Open {appName} to keep your prayer reminders coming.'**
  String notifOpenAppBody(String appName);

  /// Neutral body of the last planned notification in private mode. Title is the app name.
  ///
  /// In en, this message translates to:
  /// **'Open the app to keep reminders on'**
  String get notifOpenAppPrivateBody;

  /// Info line in Settings and Prayer screen when exact alarms are not allowed (not a notification).
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive up to 10 minutes late or more. Allow \"Alarms & reminders\" for exact times.'**
  String get notifInexactNote;

  /// Application name.
  ///
  /// In en, this message translates to:
  /// **'Prosoche'**
  String get appTitle;

  /// Bottom navigation label for the Today tab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// Bottom navigation label for the Quran tab.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get tabQuran;

  /// Bottom navigation label for the Prayer tab.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get tabPrayer;

  /// Bottom navigation label for the Journey tab.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get tabJourney;

  /// Title of the fullscreen daily card feed.
  ///
  /// In en, this message translates to:
  /// **'Daily cards'**
  String get feedTitle;

  /// Title of the gate screen shown before a blocked app.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gateTitle;

  /// Call to action on Today that opens the feed.
  ///
  /// In en, this message translates to:
  /// **'Begin today\'s cards'**
  String get beginTodaysCards;

  /// Neutral fallback shown instead of a broken widget.
  ///
  /// In en, this message translates to:
  /// **'This part could not be loaded.'**
  String get errorGeneric;

  /// Screen reader label of a loading indicator (SkLoadingState).
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get skLoading;

  /// Shown when loading takes longer than expected.
  ///
  /// In en, this message translates to:
  /// **'Still loading…'**
  String get skStillLoading;

  /// Retry button in error states.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get skTryAgain;

  /// Closes a banner or hint.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get skDismiss;

  /// Snackbar action that reverts the last action.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get skUndo;

  /// Cancels a dialog or sheet.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get skCancel;

  /// Status of a completed quest or item.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get skDone;

  /// Status of a quest the user skipped today.
  ///
  /// In en, this message translates to:
  /// **'Skipped for today'**
  String get skSkippedForToday;

  /// Button that marks a quest as completed.
  ///
  /// In en, this message translates to:
  /// **'I did it'**
  String get skIDidIt;

  /// Label of the current prayer time row.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get skNow;

  /// Label of reading outside the daily plan.
  ///
  /// In en, this message translates to:
  /// **'Free reading'**
  String get skFreeReading;

  /// Name of the daily card set in progress components.
  ///
  /// In en, this message translates to:
  /// **'Daily cards'**
  String get skDailyCards;

  /// Hint that more content is below.
  ///
  /// In en, this message translates to:
  /// **'Scroll for more'**
  String get skScrollForMore;

  /// Indicator that notifications for a prayer are turned off.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get skNotificationsOff;

  /// Marks a time that is calculated, not confirmed.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get skEstimated;

  /// Hint of a press-and-hold confirmation button.
  ///
  /// In en, this message translates to:
  /// **'Press and hold to confirm'**
  String get skHoldToConfirm;

  /// Title shown when content failed its integrity check.
  ///
  /// In en, this message translates to:
  /// **'This text can’t be shown'**
  String get skContentUnavailableTitle;

  /// Body shown when content failed its integrity check.
  ///
  /// In en, this message translates to:
  /// **'Prosoche couldn’t verify this content. Please try again later.'**
  String get skContentUnavailableBody;

  /// Progress such as '5 of 12'.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String skProgressOf(int n, int total);

  /// Prayer log status: nothing recorded yet.
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get skPrayerStatusUnlogged;

  /// Prayer log status: on time.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get skPrayerStatusOnTime;

  /// Prayer log status: late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get skPrayerStatusLate;

  /// Prayer log status: missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get skPrayerStatusMissed;

  /// Prayer log status: made up later.
  ///
  /// In en, this message translates to:
  /// **'Made up'**
  String get skPrayerStatusQada;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'en',
    'id',
    'tr',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
