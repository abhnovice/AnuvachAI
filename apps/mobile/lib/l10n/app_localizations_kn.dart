// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get unknown => 'ಅಜ್ಞಾತ';

  @override
  String get check => 'ಪರಿಶೀಲನೆ';

  @override
  String get reports => 'ವರದಿಗಳು';

  @override
  String get apps => 'ಪ್ರವೇಶ';

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get theme => 'ಗೋಚರತೆ';

  @override
  String get system => 'ಸಿಸ್ಟಮ್';

  @override
  String get light => 'ಲೈಟ್';

  @override
  String get dark => 'ಡಾರ್ಕ್';

  @override
  String get message => 'ಸಂದೇಶ';

  @override
  String get send => 'ಕಳುಹಿಸಿ';

  @override
  String get start => 'ಮೈಕ್ರೊಫೋನ್ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get stop => 'ಮೈಕ್ರೊಫೋನ್ ನಿಲ್ಲಿಸಿ';

  @override
  String get local =>
      'ಮೈಕ್ರೊಫೋನ್ ಆನ್ · ಧ್ವನಿ ಉಳಿಸಲಾಗುವುದಿಲ್ಲ ಅಥವಾ ಕಳುಹಿಸಲಾಗುವುದಿಲ್ಲ';

  @override
  String get soon => 'AI ಸಂಭಾಷಣೆ ನಂತರ ಬರಲಿದೆ';

  @override
  String get scan => 'ಆ್ಯಪ್ ಪರಿಶೀಲಿಸಿ';

  @override
  String get search => 'ಆ್ಯಪ್ ಹುಡುಕಿ';

  @override
  String get permissions => 'ಅನುಮತಿಗಳು';

  @override
  String get granted => 'ಅನುಮತಿಸಲಾಗಿದೆ';

  @override
  String get notGranted => 'ಅನುಮತಿ ಇಲ್ಲ';

  @override
  String get openSettings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ';

  @override
  String get unavailable => 'iOS ನಲ್ಲಿ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get micDenied => 'ಮೈಕ್ರೊಫೋನ್ ಅನುಮತಿ ನೀಡಿಲ್ಲ.';

  @override
  String get micUnavailable => 'ಮೈಕ್ರೊಫೋನ್ ಲಭ್ಯವಿಲ್ಲ.';

  @override
  String get iosGuide => 'iOS ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಅನುಮತಿಗಳನ್ನು ನೋಡಿ.';

  @override
  String get visibilityNote =>
      'ಗೋಚರ ಲಾಂಚರ್ ಆ್ಯಪ್‌ಗಳು ಮಾತ್ರ · ಅನುಮತಿ ಬಳಕೆಯ ಪುರಾವೆಯಲ್ಲ.';

  @override
  String welcomeName(String name) {
    return 'ನಮಸ್ಕಾರ, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ವರದಿಗಳು',
      one: '1 ವರದಿ',
      zero: 'ವರದಿಗಳಿಲ್ಲ',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'ಆ್ಯಪ್‌ಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.';

  @override
  String get settingsUnavailable => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.';

  @override
  String get consentEyebrow => 'ಗೌಪ್ಯತೆ ಮತ್ತು ಸಮ್ಮತಿ';

  @override
  String get consentHeadline => 'ವರದಿ ಮಾಡುವ ಮೊದಲು ಪರಿಶೀಲಿಸಿ';

  @override
  String get consentIntro =>
      'ನಿಮ್ಮ ವರದಿಯು ಉದ್ಯೋಗಿ ಭದ್ರತಾ ತಂಡಕ್ಕೆ ತಲುಪುತ್ತದೆ. ಏನನ್ನು ಹಂಚಿಕೊಳ್ಳಲಾಗುತ್ತದೆ ಎಂಬುದನ್ನು ಪರಿಶೀಲಿಸಿ.';

  @override
  String get consentWordsTitle => 'ನಿಮ್ಮ ಮಾತುಗಳು';

  @override
  String get consentWordsText =>
      'ನೀವು ನೀಡಿದ ವಿವರಣೆ ಮತ್ತು ಟಿಪ್ಪಣಿಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಲಾಗುತ್ತದೆ.';

  @override
  String get consentChoiceTitle => 'ನಿಮ್ಮ ಆಯ್ಕೆಗಳು';

  @override
  String get consentChoiceText =>
      'ಸಾಧನದ ಪರಿಶೀಲನೆಗಳು ಐಚ್ಛಿಕವಾಗಿವೆ ಮತ್ತು ನೀವು ಅನುಮತಿಸಿದರೆ ಮಾತ್ರ ಒಳಗೊಂಡಿರುತ್ತವೆ.';

  @override
  String get consentStorageTitle => 'ಸುರಕ್ಷಿತ ಸಂಗ್ರಹಣೆ';

  @override
  String get consentStorageText =>
      'ವರದಿಗಳನ್ನು ಎನ್‌ಕ್ರಿಪ್ಟ್ ಮಾಡಲಾಗುತ್ತದೆ ಮತ್ತು ಆಂತರಿಕವಾಗಿ ಮಾತ್ರ ಬಳಸಲಾಗುತ್ತದೆ.';

  @override
  String get consentNotice =>
      'ಸಲ್ಲಿಸುವ ಮೂಲಕ, ನೀವು ನೀತಿ ಉಲ್ಲೇಖಗಳು ಮತ್ತು ವರದಿ ಮಾಡುವ ಮಾರ್ಗಸೂಚಿಗಳನ್ನು ಒಪ್ಪುತ್ತೀರಿ.';

  @override
  String get consentContinue => 'ಮುಂದುವರಿಯಿರಿ';

  @override
  String get describeIncident => 'ಘಟನೆಯನ್ನು ವಿವರಿಸಿ';

  @override
  String get whatHappened => 'ಏನಾಯಿತು?';

  @override
  String get reviewReport => 'ವರದಿಯನ್ನು ಪರಿಶೀಲಿಸಿ';

  @override
  String get reviewBeforeSending => 'ಕಳುಹಿಸುವ ಮೊದಲು ಪರಿಶೀಲಿಸಿ';

  @override
  String get reviewFactsDescription =>
      'ನೀವು ನಮೂದಿಸಿದ ವಿವರಗಳು ಮತ್ತು ಐಚ್ಛಿಕ ತಪಾಸಣೆಗಳು ಕೆಳಗೆ ಪಟ್ಟಿಮಾಡಲಾಗಿದೆ.';

  @override
  String get reviewConfirmationIncluded => 'ದೃಢೀಕರಣವನ್ನು ಸೇರಿಸಲಾಗಿದೆ';

  @override
  String get reviewConfirmFacts =>
      'ನಾನು ಈ ಮಾಹಿತಿಯನ್ನು ಪರಿಶೀಲಿಸಿದ್ದೇನೆ ಮತ್ತು ದೃಢೀಕರಿಸುತ್ತೇನೆ.';

  @override
  String get submitting => 'ಸಲ್ಲಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get confirmAndSubmit => 'ದೃಢೀಕರಿಸಿ ಮತ್ತು ಸಲ್ಲಿಸಿ';

  @override
  String get backDraftPreserved => 'ಕರಡು ಉಳಿಸಲಾಗಿದೆ';

  @override
  String get backToEdit => 'ಸಂಪಾದಿಸಲು ಹಿಂತಿರುಗಿ';

  @override
  String get syntheticExample => 'ಸಿಂಥೆಟಿಕ್ ಪ್ರದರ್ಶನ ಉದಾಹರಣೆ';

  @override
  String get pendingSubmission => 'ಸಲ್ಲಿಕೆ ಬಾಕಿ ಇದೆ';

  @override
  String get appNameOptional => 'ಆ್ಯಪ್ ಹೆಸರು (ಐಚ್ಛಿಕ)';

  @override
  String get evidenceNotesOptional => 'ಪುರಾವೆ ಟಿಪ್ಪಣಿಗಳು (ಐಚ್ಛಿಕ)';

  @override
  String get descriptionTooShort => 'ವಿವರಣೆ ತುಂಬಾ ಚಿಕ್ಕದಾಗಿದೆ.';

  @override
  String get reportLanguageLabel => 'ವರದಿಯ ಭಾಷೆ';

  @override
  String get englishLanguage => 'ಇಂಗ್ಲಿಷ್';

  @override
  String get hindiLanguage => 'ಹಿಂದಿ';

  @override
  String get mixedLanguage => 'ಮಿಶ್ರ ಭಾಷೆ';

  @override
  String get incidentTypeLabel => 'ಘಟನೆಯ ಪ್ರಕಾರ';

  @override
  String get supportCall => 'ಬೆಂಬಲ ಕರೆ';

  @override
  String get suspiciousMessage => 'ಅನುಮಾನಾಸ್ಪದ ಸಂದೇಶ';

  @override
  String get mistakenReport => 'ತಪ್ಪಾದ ವರದಿ';

  @override
  String get otherIncident => 'ಇತರ ಘಟನೆ';

  @override
  String get optionalDeviceReview => 'ಐಚ್ಛಿಕ ಸಾಧನ ಪರಿಶೀಲನೆ';

  @override
  String get androidDeviceReview => 'Android ಸಾಧನ ಪರಿಶೀಲನೆ';

  @override
  String get iosDeviceReview => 'iOS ಸಾಧನ ಪರಿಶೀಲನೆ';

  @override
  String get allowOneCheck => 'ಒಂದು ಪರಿಶೀಲನೆಯನ್ನು ಅನುಮತಿಸಿ';

  @override
  String get checkExplanation =>
      'ಸಾಧನದ ಭದ್ರತಾ ಸ್ಥಿತಿಯನ್ನು ಪರಿಶೀಲಿಸಲು ಅನುಮತಿಸಿ.';

  @override
  String get cancelAction => 'ರದ್ದುಮಾಡಿ';

  @override
  String get checkAndInclude => 'ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಸೇರಿಸಿ';

  @override
  String get checking => 'ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get reviewDeviceCheck => 'ಸಾಧನ ಪರಿಶೀಲನೆ';

  @override
  String get removeObservation => 'ತೆಗೆದುಹಾಕಿ';

  @override
  String get detailTitle => 'ವರದಿಯ ವಿವರ';

  @override
  String get ticketDetails => 'ಟಿಕೆಟ್ ವಿವರಗಳು';

  @override
  String get refreshStatus => 'ಸ್ಥಿತಿಯನ್ನು ನವೀಕರಿಸಿ';

  @override
  String get latestUpdate => 'ಇತ್ತೀಚಿನ ಮಾಹಿತಿ';

  @override
  String get statusLabel => 'ಸ್ಥಿತಿ';

  @override
  String get statusSubmitted => 'ಸಲ್ಲಿಸಲಾಗಿದೆ';

  @override
  String get statusInReview => 'ಪರಿಶೀಲನೆಯಲ್ಲಿದೆ';

  @override
  String get statusAwaitingEmployee => 'ಉದ್ಯೋಗಿಯ ಪ್ರತಿಕ್ರಿಯೆಗಾಗಿ ಕಾಯುತ್ತಿದೆ';

  @override
  String get statusEscalated => 'ಹೆಚ್ಚಿನ ಪರಿಶೀಲನೆಗೆ ಕಳುಹಿಸಲಾಗಿದೆ';

  @override
  String get statusClosed => 'ಮುಚ್ಚಲಾಗಿದೆ';

  @override
  String get submittedAt => 'ಸಲ್ಲಿಸಲಾಗಿದೆ';

  @override
  String get updatedAt => 'ನವೀಕರಿಸಲಾಗಿದೆ';

  @override
  String get timesInUtc => 'ಸಮಯಗಳನ್ನು UTCಯಲ್ಲಿ ತೋರಿಸಲಾಗಿದೆ.';

  @override
  String get helpTitle => 'ಸಹಾಯ, ಗೌಪ್ಯತೆ ಮತ್ತು ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get stayInControl => 'ನಿಯಂತ್ರಣ ನಿಮ್ಮ ಕೈಯಲ್ಲಿದೆ.';

  @override
  String get helpIntro =>
      'ಏನನ್ನು ಹಂಚಿಕೊಳ್ಳಲಾಗುತ್ತದೆ, ಸಂಗ್ರಹಿಸಲಾಗುತ್ತದೆ ಮತ್ತು ಈ ಹಂತದಲ್ಲಿ ಏನನ್ನು ಪರಿಶೀಲಿಸಬಹುದು ಎಂಬುದನ್ನು ತಿಳಿಯಿರಿ.';

  @override
  String get reportExplained => 'ನಿಮ್ಮ ವರದಿಯ ವಿವರಣೆ';

  @override
  String get demoConnection => 'ಪ್ರದರ್ಶನ ಸಂಪರ್ಕ';

  @override
  String get openAppSettings => 'ಈ ಆ್ಯಪ್‌ನ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ';

  @override
  String get stepDescribe => 'ವಿವರಿಸಿ';

  @override
  String get stepReview => 'ಪರಿಶೀಲಿಸಿ';

  @override
  String get stepSubmit => 'ಸಲ್ಲಿಸಿ';

  @override
  String get submittedStatements => 'ಸಲ್ಲಿಸಲಾದ ಹೇಳಿಕೆಗಳು';

  @override
  String get employeeReported => 'ಉದ್ಯೋಗಿ ವರದಿ ಮಾಡಿದ್ದಾರೆ';

  @override
  String get descriptionLabel => 'ವಿವರಣೆ';

  @override
  String get appNameLabel => 'ಆ್ಯಪ್ ಹೆಸರು';

  @override
  String get evidenceNotesLabel => 'ಪುರಾವೆ ಟಿಪ್ಪಣಿಗಳು';

  @override
  String get notSupplied => 'ನೀಡಲಾಗಿಲ್ಲ';

  @override
  String get demoEmployeeIdentity => 'ಡೆಮೊ ಉದ್ಯೋಗಿ ಗುರುತು';

  @override
  String get optionalChecks => 'ಐಚ್ಛಿಕ ತಪಾಸಣೆಗಳು';

  @override
  String get deviceObserved => 'ಸಾಧನ ಅವಲೋಕನಗಳು';

  @override
  String get noDeviceFacts => 'ಯಾವುದೇ ಸಾಧನ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ.';

  @override
  String get secureScreenLock => 'ಸುರಕ್ಷಿತ ಸ್ಕ್ರೀನ್ ಲಾಕ್';

  @override
  String get configured => 'ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get notConfigured => 'ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿಲ್ಲ';

  @override
  String get publicApiClientReported => 'ಸಾರ್ವಜನಿಕ API ಕ್ಲೈಂಟ್ ವರದಿ ಮಾಡಿದೆ';

  @override
  String get checkedAt => 'ಪರಿಶೀಲಿಸಿದ ಸಮಯ';

  @override
  String get observationDisclaimer =>
      'ಅವಲೋಕನಗಳು ಸಾಧನದ ಭದ್ರತಾ ಸ್ಥಿತಿಯನ್ನು ಮಾತ್ರ ತೋರಿಸುತ್ತವೆ.';

  @override
  String get helpStorage => 'ಸಂಗ್ರಹಣೆ ಮತ್ತು ಗೌಪ್ಯತೆ';

  @override
  String get helpSettings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು ಮತ್ತು ನಿಯಂತ್ರಣಗಳು';

  @override
  String get helpRoles => 'ಪಾತ್ರಗಳು ಮತ್ತು ಜವಾಬ್ದಾರಿಗಳು';

  @override
  String get settingsOpenError => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ.';

  @override
  String get apiAddressLabel => 'API ವಿಳಾಸ';

  @override
  String get apiBuildHint => 'ನಿರ್ಮಾಣ ಆವೃತ್ತಿ ಮತ್ತು API ಮಾಹಿತಿ';

  @override
  String get voiceWelcome => 'ಮಾತನಾಡೋಣ.';

  @override
  String get voiceWelcomeHint =>
      'ಏನಾಯಿತು ಎಂದು ಹೇಳಿ. ಮಾತನಾಡಬಹುದು ಅಥವಾ ಟೈಪ್ ಮಾಡಬಹುದು.';

  @override
  String get voiceAssistant => 'ಅನುವಾಚ್ ಸಹಾಯಕ';

  @override
  String get voiceYou => 'ನೀವು';

  @override
  String get voiceReady => 'ಕೇಳಲು ಸಿದ್ಧ';

  @override
  String get voiceConnecting => 'ಸಂಪರ್ಕಿಸುತ್ತಿದೆ…';

  @override
  String get voiceListening => 'ಕೇಳುತ್ತಿದೆ';

  @override
  String get voiceThinking => 'ಯೋಚಿಸುತ್ತಿದೆ…';

  @override
  String get voiceSpeaking => 'ಮಾತನಾಡುತ್ತಿದೆ';

  @override
  String get voiceEnding => 'ಮುಗಿಸುತ್ತಿದೆ…';

  @override
  String get voiceUnavailable => 'ಧ್ವನಿ ಸೌಲಭ್ಯ ಲಭ್ಯವಿಲ್ಲ. ಟೈಪ್ ಮಾಡಬಹುದು.';

  @override
  String get voicePartial => 'ನೇರ ಪ್ರತಿಲಿಪಿ';

  @override
  String get voiceCorrect => 'ಪ್ರತಿಲಿಪಿ ತಿದ್ದಿ';

  @override
  String get voiceUse => 'ವರದಿಗೆ ಸೇರಿಸಿ';

  @override
  String get voiceDraft => 'ವರದಿಯ ಕರಡು ನೋಡಿ';

  @override
  String get voiceStart => 'ಧ್ವನಿ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get voiceEnd => 'ಧ್ವನಿ ನಿಲ್ಲಿಸಿ';

  @override
  String get voiceApply => 'ತಿದ್ದುಪಡಿ ಅನ್ವಯಿಸಿ';

  @override
  String get voiceType => 'ಸಂದೇಶ ಟೈಪ್ ಮಾಡಿ';
}
