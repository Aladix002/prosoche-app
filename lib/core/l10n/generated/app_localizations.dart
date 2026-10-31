import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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

  /// Shown above extra cards in the gate after today's set is done.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cards are done. Here are a few more to read.'**
  String get gateFreeReadingNote;

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

  /// Summary of a blocked app: cards to unlock and unlock minutes.
  ///
  /// In en, this message translates to:
  /// **'{cards, plural, one{1 card} other{{cards} cards}} · {minutes} min'**
  String blkAppSummary(int cards, String minutes);

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

  /// Small note on a card when its text is not available in the user's language yet.
  ///
  /// In en, this message translates to:
  /// **'Text not yet available in your language'**
  String get cardTranslationNotYetAvailable;

  /// Under the app name on the welcome screen: the Greek word prosoche and its meaning. Keep the Greek word as is, translate only 'attention'.
  ///
  /// In en, this message translates to:
  /// **'προσοχή · attention'**
  String get onbWelcomeMeaning;

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
  /// **'A few quiet minutes with the Stoics each day. Then you\'re done.'**
  String get onbWelcomeBody;

  /// Short privacy note under the welcome text.
  ///
  /// In en, this message translates to:
  /// **'No account. No ads. Your data stays on this phone.'**
  String get onbWelcomeNote;

  /// Title of the intention step.
  ///
  /// In en, this message translates to:
  /// **'Why are you here?'**
  String get onbIntentionTitle;

  /// Body of the intention step.
  ///
  /// In en, this message translates to:
  /// **'Choose what matters to you. You can pick more than one. It stays on this phone.'**
  String get onbIntentionBody;

  /// Options of the intention step. 'other' opens a text field for the user's own words.
  ///
  /// In en, this message translates to:
  /// **'{option, select, less_scrolling{Spend less time scrolling} calm{Stay calm under pressure} read_daily{Read the Stoics daily} reflect{Reflect each evening} other{Write my own}}'**
  String onbIntentionOption(String option);

  /// Hint of the text field for the user's own intention (max 140 characters).
  ///
  /// In en, this message translates to:
  /// **'In your own words'**
  String get onbIntentionOwnHint;

  /// Title of the notifications step.
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders'**
  String get onbNotifTitle;

  /// Body of the notifications step (shown before the system dialog).
  ///
  /// In en, this message translates to:
  /// **'Get one quiet notice in the morning when your cards are ready. Nothing else.'**
  String get onbNotifBody;

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
  /// **'Your reading, notes and progress never leave this phone.'**
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
  /// **'Share anonymous usage, like which screens are used. Never your reading, your notes, or which apps you use.'**
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
  /// **'Only if you choose to share: anonymous events such as \"onboarding finished\" or \"daily cards completed\", the app version and the language. Never what you read or write, or which apps you use.'**
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

  /// Card eyebrow for a longer passage from a work.
  ///
  /// In en, this message translates to:
  /// **'Passage'**
  String get cardTypePassage;

  /// Card eyebrow for an exercise card.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get cardTypePractice;

  /// Card eyebrow for a question to reflect on.
  ///
  /// In en, this message translates to:
  /// **'Reflect'**
  String get cardTypePrompt;

  /// Card eyebrow for a Stoic concept.
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get cardTypeConcept;

  /// Card eyebrow for an introduction to an author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get cardTypeAuthor;

  /// Translator attribution on cards, reader and shared image.
  ///
  /// In en, this message translates to:
  /// **'Translated by {translator}'**
  String cardTranslatedBy(String translator);

  /// Translator attribution with year of the translation.
  ///
  /// In en, this message translates to:
  /// **'Translated by {translator} ({year})'**
  String cardTranslatedByYear(String translator, int year);

  /// Link from a card to the source section in Library.
  ///
  /// In en, this message translates to:
  /// **'Read in context'**
  String get cardReadInContext;

  /// Link to the related section, e.g. 'Read Meditations 2.1'.
  ///
  /// In en, this message translates to:
  /// **'Read {reference}'**
  String cardReadReference(String reference);

  /// Line under a practice or concept card with the related section.
  ///
  /// In en, this message translates to:
  /// **'Related: {reference}'**
  String cardRelatedReference(String reference);

  /// Link from an author card to the first work in Library.
  ///
  /// In en, this message translates to:
  /// **'Read {title}'**
  String cardReadWork(String title);

  /// Link from a practice card to the exercise screen.
  ///
  /// In en, this message translates to:
  /// **'Open in Practice'**
  String get cardOpenPractice;

  /// Link from a question card to the local journal.
  ///
  /// In en, this message translates to:
  /// **'Write in journal'**
  String get cardWriteInJournal;

  /// Tooltip: search in all works.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get librarySearch;

  /// Hint in the search field.
  ///
  /// In en, this message translates to:
  /// **'Search the works'**
  String get librarySearchHint;

  /// Empty search screen title.
  ///
  /// In en, this message translates to:
  /// **'Search all works'**
  String get librarySearchHintTitle;

  /// Empty search screen body.
  ///
  /// In en, this message translates to:
  /// **'Find a word or phrase in every book and section.'**
  String get librarySearchHintBody;

  /// No search results.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get librarySearchEmpty;

  /// Bookmarked sections (title and tooltip).
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get libraryBookmarks;

  /// Empty bookmarks title.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get libraryBookmarksEmptyTitle;

  /// Empty bookmarks body.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark in the reader to keep a section here.'**
  String get libraryBookmarksEmptyBody;

  /// Library without content.
  ///
  /// In en, this message translates to:
  /// **'No works'**
  String get libraryEmptyTitle;

  /// Library without content, body.
  ///
  /// In en, this message translates to:
  /// **'The texts could not be found.'**
  String get libraryEmptyBody;

  /// Number of books in a work.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 book} other{{count} books}}'**
  String libraryBooks(int count);

  /// Number of sections in a work without books.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 section} other{{count} sections}}'**
  String librarySections(int count);

  /// Reading position of a work, e.g. 'Continue at Meditations 2.1'.
  ///
  /// In en, this message translates to:
  /// **'Continue at {reference}'**
  String libraryContinueAt(String reference);

  /// Reader: list of books and sections.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get readerContents;

  /// Reader: add bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this section'**
  String get readerAddBookmark;

  /// Reader: remove bookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get readerRemoveBookmark;

  /// Snackbar after adding a bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get readerBookmarkAdded;

  /// Snackbar after removing a bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get readerBookmarkRemoved;

  /// Reader: previous section.
  ///
  /// In en, this message translates to:
  /// **'Previous section'**
  String get readerPrevious;

  /// Reader: next section.
  ///
  /// In en, this message translates to:
  /// **'Next section'**
  String get readerNext;

  /// Screen reader label of the reading progress line.
  ///
  /// In en, this message translates to:
  /// **'Reading position'**
  String get readerProgressA11y;

  /// Reader position, e.g. '5 / 52'.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String readerProgressValue(int current, int total);

  /// Reader: work missing in the content.
  ///
  /// In en, this message translates to:
  /// **'This work is not available'**
  String get readerMissingTitle;

  /// Reader: work missing, body.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed in a content update.'**
  String get readerMissingBody;

  /// Eyebrow of the morning preparation.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get practiceMorning;

  /// Eyebrow of the evening reflection.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get practiceEvening;

  /// Fallback title of the morning routine.
  ///
  /// In en, this message translates to:
  /// **'Morning preparation'**
  String get practiceMorningTitle;

  /// Fallback title of the evening routine.
  ///
  /// In en, this message translates to:
  /// **'Evening reflection'**
  String get practiceEveningTitle;

  /// Button: mark the routine of today as done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get practiceMarkDone;

  /// State of a routine done today (tap to undo).
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get practiceDoneToday;

  /// Snackbar after confirming a practice.
  ///
  /// In en, this message translates to:
  /// **'Marked as done.'**
  String get practiceMarkedDone;

  /// Button: the user confirms the exercise.
  ///
  /// In en, this message translates to:
  /// **'I did this'**
  String get practiceIDidThis;

  /// Section header with all practice cards.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get practiceExercises;

  /// Exercise missing in content.
  ///
  /// In en, this message translates to:
  /// **'This exercise is not available'**
  String get exerciseMissing;

  /// Local journal title.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// Journal tile subtitle without entries.
  ///
  /// In en, this message translates to:
  /// **'Notes stay on this device'**
  String get journalSubtitleEmpty;

  /// Journal tile subtitle with the number of entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 entry} other{{count} entries}}'**
  String journalSubtitleCount(int count);

  /// Privacy note under journal fields.
  ///
  /// In en, this message translates to:
  /// **'Your journal stays on this device. It is never sent anywhere.'**
  String get journalPrivacyNote;

  /// Label of the answer field for a question card.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get journalYourAnswer;

  /// Save a journal entry.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get journalSave;

  /// Add a free note to the journal.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get journalNewNote;

  /// Kind of a free journal entry.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get journalNote;

  /// Delete a journal entry.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get journalDelete;

  /// Delete all journal entries (title and tooltip).
  ///
  /// In en, this message translates to:
  /// **'Delete journal'**
  String get journalDeleteAllTitle;

  /// Confirmation before deleting the whole journal.
  ///
  /// In en, this message translates to:
  /// **'All journal entries will be deleted from this device. This cannot be undone.'**
  String get journalDeleteAllBody;

  /// Share the journal as text (tooltip).
  ///
  /// In en, this message translates to:
  /// **'Export journal'**
  String get journalExport;

  /// First line of the exported journal text.
  ///
  /// In en, this message translates to:
  /// **'{app} journal'**
  String journalExportTitle(String app);

  /// Empty journal title.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get journalEmptyTitle;

  /// Empty journal body.
  ///
  /// In en, this message translates to:
  /// **'Answers from the morning and evening practice appear here.'**
  String get journalEmptyBody;

  /// Title of the weeks-of-life screen.
  ///
  /// In en, this message translates to:
  /// **'Memento mori'**
  String get mementoTitle;

  /// Subtitle of the memento mori tile.
  ///
  /// In en, this message translates to:
  /// **'Your life in weeks'**
  String get mementoSubtitle;

  /// Button: enter the year of birth (optional).
  ///
  /// In en, this message translates to:
  /// **'Add birth year'**
  String get mementoAddYear;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Year of birth'**
  String get mementoBirthYear;

  /// Helper under the year field.
  ///
  /// In en, this message translates to:
  /// **'Optional. Used only to draw the weeks.'**
  String get mementoBirthYearHelp;

  /// Change the year of birth.
  ///
  /// In en, this message translates to:
  /// **'Change year'**
  String get mementoChangeYear;

  /// Remove the stored year of birth.
  ///
  /// In en, this message translates to:
  /// **'Remove year'**
  String get mementoClearYear;

  /// Weeks of an 80 year life already lived.
  ///
  /// In en, this message translates to:
  /// **'{lived} of {total} weeks'**
  String mementoWeeks(int lived, int total);

  /// Screen reader label of the weeks grid.
  ///
  /// In en, this message translates to:
  /// **'{lived} weeks lived, {left} weeks left of 80 years'**
  String mementoGridA11y(int lived, int left);

  /// Note under the grid.
  ///
  /// In en, this message translates to:
  /// **'Each square is one week of an 80 year life.'**
  String get mementoNote;

  /// Privacy note on memento mori.
  ///
  /// In en, this message translates to:
  /// **'The year stays on this device.'**
  String get mementoPrivacy;

  /// Evening reminder title.
  ///
  /// In en, this message translates to:
  /// **'Evening reflection'**
  String get notifEveningTitle;

  /// Evening reminder body.
  ///
  /// In en, this message translates to:
  /// **'A few minutes to look back at the day.'**
  String get notifEveningBody;

  /// Evening reminder body when content is hidden on the lock screen.
  ///
  /// In en, this message translates to:
  /// **'A reminder for this evening.'**
  String get notifEveningPrivateBody;

  /// Settings section: evening reminder.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get setEvening;

  /// Switch: evening reminder.
  ///
  /// In en, this message translates to:
  /// **'Evening reflection'**
  String get setEveningToggle;

  /// Help for the evening reminder switch.
  ///
  /// In en, this message translates to:
  /// **'A quiet reminder to review the day. Off by default.'**
  String get setEveningHelp;

  /// Time of the evening reminder.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get setEveningTime;

  /// Tooltip of the gear button on Today that opens Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get todaySettings;

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
  /// **'Today\'s practice'**
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
  String todayIntention(String text);

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

  /// Summary on the done card: number of cards.
  ///
  /// In en, this message translates to:
  /// **'{cards, plural, one{1 card} other{{cards} cards}}'**
  String doneSummary(int cards);

  /// Quest summary on the done card.
  ///
  /// In en, this message translates to:
  /// **'Intentions: {done} of {total}'**
  String doneQuests(int done, int total);

  /// The feed ends; nothing more to load today.
  ///
  /// In en, this message translates to:
  /// **'The cards are closed until tomorrow.'**
  String get doneClosed;

  /// Opens free reading from the reading position.
  ///
  /// In en, this message translates to:
  /// **'Keep reading'**
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

  /// Title of the private progress tab (Journey, docs/02 A8.1).
  ///
  /// In en, this message translates to:
  /// **'My journey'**
  String get journeyTitle;

  /// Shown on Journey instead of the intention when the user has not written one. Tapping opens the intention editor.
  ///
  /// In en, this message translates to:
  /// **'Add your intention'**
  String get journeyIntentionEmpty;

  /// Tooltip of the pencil button next to the intention on Journey.
  ///
  /// In en, this message translates to:
  /// **'Edit intention'**
  String get journeyIntentionEdit;

  /// Title of the dialog that edits the intention (same choices as in onboarding). It stays on the phone.
  ///
  /// In en, this message translates to:
  /// **'Your intention'**
  String get journeyIntentionDialogTitle;

  /// Saves the edited intention.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get journeyIntentionSave;

  /// Closes the intention dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get journeyIntentionCancel;

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
  /// **'{type, select, all{All} quote{Quotes} passage{Passages} practice{Practices} prompt{Questions} concept{Ideas} author{Authors} other{All}}'**
  String journeySavedFilter(String type);

  /// Type of a saved card shown in its row.
  ///
  /// In en, this message translates to:
  /// **'{type, select, quote{Quote} passage{Passage} practice{Practice} prompt{Question} concept{Idea} author{Author} other{Card}}'**
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

  /// Settings row and screen title for notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get setNotifications;

  /// Settings row and screen title for theme and daily set options.
  ///
  /// In en, this message translates to:
  /// **'Daily set & display'**
  String get setDisplay;

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

  /// Version and license of a content source, e.g. 'Version 1.1 · License: CC BY 3.0'.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · License: {license}'**
  String setSourceVersionLicense(String version, String license);

  /// Note under translations on the Sources screen.
  ///
  /// In en, this message translates to:
  /// **'Older translations may use old-fashioned language. The text is kept as published.'**
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

  /// Switch: notifications show only the app name and time.
  ///
  /// In en, this message translates to:
  /// **'Private text'**
  String get setPrivateText;

  /// Explanation under the private text switch.
  ///
  /// In en, this message translates to:
  /// **'Show only the app name and time on the lock screen, without what the reminder is about.'**
  String get setPrivateTextHelp;

  /// Note at the end of notification settings (docs/11 12.1).
  ///
  /// In en, this message translates to:
  /// **'Reminders may be delayed by Android or battery settings.'**
  String get setOsDelayNote;

  /// Intro on the privacy screen (docs/11 12.4).
  ///
  /// In en, this message translates to:
  /// **'Your reading, notes and other logs stay on this phone. We do not receive them.'**
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
  /// **'{kind, select, text{Texts} translation{Translations} curated{Prosoche content} font{Fonts} other{Other}}'**
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

  /// Tooltip of the text size button in the Library reader, title of the size picker, and the section in Settings > Display.
  ///
  /// In en, this message translates to:
  /// **'Reading size'**
  String get readerTextSize;

  /// Name of a reading size option (S, M, L, XL) in the Library reader.
  ///
  /// In en, this message translates to:
  /// **'{value, select, s{Small} m{Medium} l{Large} xl{Extra large} other{Medium}}'**
  String readerTextSizeName(String value);

  /// Help text under the Reading size section in Settings > Display.
  ///
  /// In en, this message translates to:
  /// **'Text size in the Library reader. It adds to your phone\'s text size.'**
  String get setReaderSizeHelp;

  /// Onboarding switch: a reminder in the evening to review the day. Off by default. time = local time, e.g. '21:00'.
  ///
  /// In en, this message translates to:
  /// **'Evening reflection at {time}'**
  String onbNotifEvening(String time);

  /// Subtitle under the evening reflection switch in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Optional. A quiet reminder to review the day.'**
  String get onbNotifEveningHelp;

  /// Section heading on Practice under the morning and evening cards: the remaining exercises.
  ///
  /// In en, this message translates to:
  /// **'Other exercises'**
  String get practiceOtherExercises;

  /// Small line under a card with the source of the text, e.g. 'Source: Project Gutenberg'. The attribution comes from the content database and is not translated.
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
  /// **'The report is a text file that you send yourself, for example by e-mail. It contains the card reference and technical details from the app. Your notes and reading are not included.'**
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

  /// Neutral body of the morning reminder in private mode. Title is the app name.
  ///
  /// In en, this message translates to:
  /// **'Your daily reminder'**
  String get notifMorningPrivateBody;

  /// Last planned notification when the app was not opened for 10 days.
  ///
  /// In en, this message translates to:
  /// **'Reminders pause soon'**
  String get notifOpenAppTitle;

  /// Body of the last planned notification.
  ///
  /// In en, this message translates to:
  /// **'Open {appName} to keep your reminders coming.'**
  String notifOpenAppBody(String appName);

  /// Neutral body of the last planned notification in private mode. Title is the app name.
  ///
  /// In en, this message translates to:
  /// **'Open the app to keep reminders on'**
  String get notifOpenAppPrivateBody;

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

  /// Bottom navigation label for the Journey tab.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get tabJourney;

  /// Neutral fallback shown instead of a broken widget.
  ///
  /// In en, this message translates to:
  /// **'This part could not be loaded.'**
  String get errorGeneric;

  /// Bottom navigation label for the Library tab (reading whole works).
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// Bottom navigation label for the Practice tab (exercises).
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get tabPractice;

  /// Placeholder body of the Library tab until it is built.
  ///
  /// In en, this message translates to:
  /// **'Whole works to read, book by book. Coming soon.'**
  String get libraryPlaceholderBody;

  /// Placeholder body of the Practice tab until it is built.
  ///
  /// In en, this message translates to:
  /// **'Morning preparation and evening review. Coming soon.'**
  String get practicePlaceholderBody;

  /// Eyebrow label of a quote card.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get cardTypeQuote;

  /// Attribution line under a quote, e.g. 'Marcus Aurelius, Meditations 2.1'. Values come from the content database.
  ///
  /// In en, this message translates to:
  /// **'{author}, {reference}'**
  String cardQuoteAttribution(String author, String reference);

  /// Screen reader label of a quote card.
  ///
  /// In en, this message translates to:
  /// **'Quote by {author}'**
  String cardQuoteA11y(String author);

  /// Built-in daily quest (read slot): read quotes or passages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Read 1 card} other{Read {count} cards}}'**
  String questGenericReadCards(int count);

  /// Built-in daily quest (learn slot): see one idea or author card.
  ///
  /// In en, this message translates to:
  /// **'Learn one idea'**
  String get questGenericLearnIdea;

  /// Built-in daily quest (act slot), marked as done by the user.
  ///
  /// In en, this message translates to:
  /// **'Try one practice'**
  String get questGenericActPractice;

  /// Secondary button on Today after the daily cards are complete; opens the Library.
  ///
  /// In en, this message translates to:
  /// **'Keep reading'**
  String get todayCtaKeepReading;

  /// Note on the About screen about where texts come from.
  ///
  /// In en, this message translates to:
  /// **'Texts are public domain translations, shown as published. Short notes and questions are written for this app.'**
  String get setDisclaimerTexts;

  /// Note on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Prosoche is not medical or psychological advice.'**
  String get setDisclaimerAdvice;

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
