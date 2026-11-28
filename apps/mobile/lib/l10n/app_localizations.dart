import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('bn'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @apps.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get apps;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start microphone'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop microphone'**
  String get stop;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Microphone on · no audio saved or sent'**
  String get local;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'AI conversation coming later'**
  String get soon;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Review apps'**
  String get scan;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get search;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @notGranted.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get notGranted;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on iOS'**
  String get unavailable;

  /// No description provided for @micDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission not granted.'**
  String get micDenied;

  /// No description provided for @micUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone unavailable.'**
  String get micUnavailable;

  /// No description provided for @iosGuide.
  ///
  /// In en, this message translates to:
  /// **'Review permissions in iOS Settings.'**
  String get iosGuide;

  /// No description provided for @visibilityNote.
  ///
  /// In en, this message translates to:
  /// **'Visible launcher apps only · Permission grants do not prove use.'**
  String get visibilityNote;

  /// Example greeting with a dynamic name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String welcomeName(String name);

  /// Example localized report count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reports} one{1 report} other{{count} reports}}'**
  String reportCount(int count);

  /// No description provided for @accessUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load apps.'**
  String get accessUnavailable;

  /// No description provided for @settingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open settings.'**
  String get settingsUnavailable;

  /// No description provided for @consentEyebrow.
  ///
  /// In en, this message translates to:
  /// **'EMPLOYEE INCIDENT REPORTING'**
  String get consentEyebrow;

  /// No description provided for @consentHeadline.
  ///
  /// In en, this message translates to:
  /// **'A clear account.\nA safer next step.'**
  String get consentHeadline;

  /// No description provided for @consentIntro.
  ///
  /// In en, this message translates to:
  /// **'Something felt wrong? Start here.\nDescribe it in your words, then review before sharing.'**
  String get consentIntro;

  /// No description provided for @consentWordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your words, your report'**
  String get consentWordsTitle;

  /// No description provided for @consentWordsText.
  ///
  /// In en, this message translates to:
  /// **'Description, language, incident type, and optional app and evidence notes.'**
  String get consentWordsText;

  /// No description provided for @consentChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'You choose what to share'**
  String get consentChoiceTitle;

  /// No description provided for @consentChoiceText.
  ///
  /// In en, this message translates to:
  /// **'Device checks are optional. Nothing is submitted until you review and confirm.'**
  String get consentChoiceText;

  /// No description provided for @consentStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Stored locally for this demo'**
  String get consentStorageTitle;

  /// No description provided for @consentStorageText.
  ///
  /// In en, this message translates to:
  /// **'Drafts stay on this device. Submitted reports go to the local API for administrator review.'**
  String get consentStorageText;

  /// No description provided for @consentNotice.
  ///
  /// In en, this message translates to:
  /// **'Synthetic demonstration only. Do not enter real employee information. No sign-in or production access controls. Microphone audio is not saved, sent or analysed.'**
  String get consentNotice;

  /// No description provided for @consentContinue.
  ///
  /// In en, this message translates to:
  /// **'I understand · Continue'**
  String get consentContinue;

  /// No description provided for @describeIncident.
  ///
  /// In en, this message translates to:
  /// **'Describe the incident'**
  String get describeIncident;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

  /// No description provided for @reviewReport.
  ///
  /// In en, this message translates to:
  /// **'Review report'**
  String get reviewReport;

  /// No description provided for @reviewBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Review before sending'**
  String get reviewBeforeSending;

  /// No description provided for @reviewFactsDescription.
  ///
  /// In en, this message translates to:
  /// **'These are the exact report facts to be sent. The API adds a ticket ID, timestamps and initial status.'**
  String get reviewFactsDescription;

  /// No description provided for @reviewConfirmationIncluded.
  ///
  /// In en, this message translates to:
  /// **'Submission includes your explicit confirmation: true.'**
  String get reviewConfirmationIncluded;

  /// No description provided for @reviewConfirmFacts.
  ///
  /// In en, this message translates to:
  /// **'I confirm these facts and want to create this ticket.'**
  String get reviewConfirmFacts;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @confirmAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm and submit'**
  String get confirmAndSubmit;

  /// No description provided for @backDraftPreserved.
  ///
  /// In en, this message translates to:
  /// **'Back · draft preserved'**
  String get backDraftPreserved;

  /// No description provided for @backToEdit.
  ///
  /// In en, this message translates to:
  /// **'Back to edit'**
  String get backToEdit;

  /// No description provided for @syntheticExample.
  ///
  /// In en, this message translates to:
  /// **'Use synthetic details only. Example: an unexpected IT-support caller asked you to install a remote-access app or share a code.'**
  String get syntheticExample;

  /// No description provided for @pendingSubmission.
  ///
  /// In en, this message translates to:
  /// **'A submission may already have reached the API. Retry the preserved reviewed report to retrieve its ticket safely. Editing is paused until this is resolved.'**
  String get pendingSubmission;

  /// No description provided for @appNameOptional.
  ///
  /// In en, this message translates to:
  /// **'App name (optional)'**
  String get appNameOptional;

  /// No description provided for @evidenceNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Evidence notes (optional)'**
  String get evidenceNotesOptional;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Describe the incident in at least 10 characters.'**
  String get descriptionTooShort;

  /// No description provided for @reportLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Report language'**
  String get reportLanguageLabel;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @hindiLanguage.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindiLanguage;

  /// No description provided for @mixedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Mixed English / Hindi'**
  String get mixedLanguage;

  /// No description provided for @incidentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Incident type'**
  String get incidentTypeLabel;

  /// No description provided for @supportCall.
  ///
  /// In en, this message translates to:
  /// **'Support call'**
  String get supportCall;

  /// No description provided for @suspiciousMessage.
  ///
  /// In en, this message translates to:
  /// **'Suspicious message'**
  String get suspiciousMessage;

  /// No description provided for @mistakenReport.
  ///
  /// In en, this message translates to:
  /// **'Mistaken report'**
  String get mistakenReport;

  /// No description provided for @otherIncident.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherIncident;

  /// No description provided for @optionalDeviceReview.
  ///
  /// In en, this message translates to:
  /// **'Optional device review'**
  String get optionalDeviceReview;

  /// No description provided for @androidDeviceReview.
  ///
  /// In en, this message translates to:
  /// **'With your consent, check whether Android reports a secure screen lock. This does not check installed remote-access apps or permission use.'**
  String get androidDeviceReview;

  /// No description provided for @iosDeviceReview.
  ///
  /// In en, this message translates to:
  /// **'Automatic device checks are unavailable on iOS in this stage. Review installed apps and permissions manually in Settings, or contact your known helpdesk.'**
  String get iosDeviceReview;

  /// No description provided for @allowOneCheck.
  ///
  /// In en, this message translates to:
  /// **'Allow this one check?'**
  String get allowOneCheck;

  /// No description provided for @checkExplanation.
  ///
  /// In en, this message translates to:
  /// **'Read secure screen-lock configuration now and include its result and timestamp in your report. No runtime permission is needed.'**
  String get checkExplanation;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @checkAndInclude.
  ///
  /// In en, this message translates to:
  /// **'Check and include'**
  String get checkAndInclude;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @reviewDeviceCheck.
  ///
  /// In en, this message translates to:
  /// **'Review and consent to device check'**
  String get reviewDeviceCheck;

  /// No description provided for @removeObservation.
  ///
  /// In en, this message translates to:
  /// **'Remove device observation'**
  String get removeObservation;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Report detail'**
  String get detailTitle;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'TICKET DETAILS'**
  String get ticketDetails;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @latestUpdate.
  ///
  /// In en, this message translates to:
  /// **'LATEST UPDATE'**
  String get latestUpdate;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get statusInReview;

  /// No description provided for @statusAwaitingEmployee.
  ///
  /// In en, this message translates to:
  /// **'Awaiting employee'**
  String get statusAwaitingEmployee;

  /// No description provided for @statusEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get statusEscalated;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @submittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedAt;

  /// No description provided for @timesInUtc.
  ///
  /// In en, this message translates to:
  /// **'Times shown in UTC.'**
  String get timesInUtc;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help, privacy and settings'**
  String get helpTitle;

  /// No description provided for @stayInControl.
  ///
  /// In en, this message translates to:
  /// **'You stay in control.'**
  String get stayInControl;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Know what is shared, what is stored, and what this stage can check.'**
  String get helpIntro;

  /// No description provided for @reportExplained.
  ///
  /// In en, this message translates to:
  /// **'Your report, explained'**
  String get reportExplained;

  /// No description provided for @demoConnection.
  ///
  /// In en, this message translates to:
  /// **'Demo connection'**
  String get demoConnection;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open this app’s settings'**
  String get openAppSettings;

  /// No description provided for @stepDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe'**
  String get stepDescribe;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get stepReview;

  /// No description provided for @stepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get stepSubmit;

  /// No description provided for @submittedStatements.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED STATEMENTS'**
  String get submittedStatements;

  /// No description provided for @employeeReported.
  ///
  /// In en, this message translates to:
  /// **'Employee reported'**
  String get employeeReported;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @appNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get appNameLabel;

  /// No description provided for @evidenceNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence notes'**
  String get evidenceNotesLabel;

  /// No description provided for @notSupplied.
  ///
  /// In en, this message translates to:
  /// **'Not supplied'**
  String get notSupplied;

  /// No description provided for @demoEmployeeIdentity.
  ///
  /// In en, this message translates to:
  /// **'Employee identity: demo-employee'**
  String get demoEmployeeIdentity;

  /// No description provided for @optionalChecks.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL CHECKS'**
  String get optionalChecks;

  /// No description provided for @deviceObserved.
  ///
  /// In en, this message translates to:
  /// **'Device observed'**
  String get deviceObserved;

  /// No description provided for @noDeviceFacts.
  ///
  /// In en, this message translates to:
  /// **'No automatic device facts included.'**
  String get noDeviceFacts;

  /// No description provided for @secureScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Secure screen lock'**
  String get secureScreenLock;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'configured'**
  String get configured;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'not configured'**
  String get notConfigured;

  /// No description provided for @publicApiClientReported.
  ///
  /// In en, this message translates to:
  /// **'Android public API · client-reported'**
  String get publicApiClientReported;

  /// No description provided for @checkedAt.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get checkedAt;

  /// No description provided for @observationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These observations do not establish remote access, compromise, or whether a permission was used.'**
  String get observationDisclaimer;

  /// No description provided for @helpStorage.
  ///
  /// In en, this message translates to:
  /// **'Use synthetic data only. Drafts are stored locally in app preferences, without encryption. Submitted facts are stored by the local API in SQLite. Administrator notes stay in the administrator view. This demonstration has no authentication.'**
  String get helpStorage;

  /// No description provided for @helpSettings.
  ///
  /// In en, this message translates to:
  /// **'Opening settings does not change any setting. On Android you can inspect this app’s settings; on iOS you can open this app’s Settings page. Review other apps and permissions manually through system Settings. A visible permission does not prove it was used.'**
  String get helpSettings;

  /// No description provided for @helpRoles.
  ///
  /// In en, this message translates to:
  /// **'Security and data protection are separate reviewer roles in the demonstration model. Real employee data requires server-enforced access control and a defined retention policy.'**
  String get helpRoles;

  /// No description provided for @settingsOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open settings. Open system Settings manually.'**
  String get settingsOpenError;

  /// No description provided for @apiAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'API address'**
  String get apiAddressLabel;

  /// No description provided for @apiBuildHint.
  ///
  /// In en, this message translates to:
  /// **'Set API_BASE_URL at build/run time.'**
  String get apiBuildHint;

  /// No description provided for @voiceWelcome.
  ///
  /// In en, this message translates to:
  /// **'Talk it through.'**
  String get voiceWelcome;

  /// No description provided for @voiceWelcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me what happened. You can speak or type.'**
  String get voiceWelcomeHint;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Anuvach assistant'**
  String get voiceAssistant;

  /// No description provided for @voiceYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get voiceYou;

  /// No description provided for @voiceReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to listen'**
  String get voiceReady;

  /// No description provided for @voiceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get voiceConnecting;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get voiceListening;

  /// No description provided for @voiceThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get voiceThinking;

  /// No description provided for @voiceSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get voiceSpeaking;

  /// No description provided for @voiceEnding.
  ///
  /// In en, this message translates to:
  /// **'Wrapping up…'**
  String get voiceEnding;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice unavailable. You can still type.'**
  String get voiceUnavailable;

  /// No description provided for @voicePartial.
  ///
  /// In en, this message translates to:
  /// **'Live transcript'**
  String get voicePartial;

  /// No description provided for @voiceCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct transcript'**
  String get voiceCorrect;

  /// No description provided for @voiceUse.
  ///
  /// In en, this message translates to:
  /// **'Use in report'**
  String get voiceUse;

  /// No description provided for @voiceDraft.
  ///
  /// In en, this message translates to:
  /// **'Review ticket draft'**
  String get voiceDraft;

  /// No description provided for @voiceStart.
  ///
  /// In en, this message translates to:
  /// **'Start voice'**
  String get voiceStart;

  /// No description provided for @voiceEnd.
  ///
  /// In en, this message translates to:
  /// **'End voice'**
  String get voiceEnd;

  /// No description provided for @voiceApply.
  ///
  /// In en, this message translates to:
  /// **'Apply correction'**
  String get voiceApply;

  /// No description provided for @voiceType.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get voiceType;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReports;

  /// No description provided for @reportHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Submitted tickets and their latest status will appear here.'**
  String get reportHistoryHint;

  /// No description provided for @refreshReports.
  ///
  /// In en, this message translates to:
  /// **'Refresh reports'**
  String get refreshReports;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @showReports.
  ///
  /// In en, this message translates to:
  /// **'Show reports'**
  String get showReports;

  /// No description provided for @callPrompt.
  ///
  /// In en, this message translates to:
  /// **'I got a call from someone claiming to be'**
  String get callPrompt;

  /// No description provided for @messagePrompt.
  ///
  /// In en, this message translates to:
  /// **'I received a message asking me to'**
  String get messagePrompt;

  /// No description provided for @voiceLogoStart.
  ///
  /// In en, this message translates to:
  /// **'Start voice with the Anuvach logo'**
  String get voiceLogoStart;

  /// No description provided for @accessOverview.
  ///
  /// In en, this message translates to:
  /// **'Your access overview'**
  String get accessOverview;

  /// No description provided for @accessBriefing.
  ///
  /// In en, this message translates to:
  /// **'Gemini · accessibility briefing'**
  String get accessBriefing;

  /// No description provided for @accessBriefingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Gemini briefing is unavailable here. You can still review apps and settings locally.'**
  String get accessBriefingUnavailable;

  /// No description provided for @voiceStartupNotice.
  ///
  /// In en, this message translates to:
  /// **'Use synthetic details only. On Android, voice starts on opening if microphone access is already granted. Live voice sends microphone audio to the reporting assistant until you stop voice or leave Check.'**
  String get voiceStartupNotice;
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
    'bn',
    'en',
    'hi',
    'kn',
    'ml',
    'pa',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
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
