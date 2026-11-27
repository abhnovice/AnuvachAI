// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get unknown => 'ਅਣਜਾਣ';

  @override
  String get check => 'ਜਾਂਚ';

  @override
  String get reports => 'ਰਿਪੋਰਟਾਂ';

  @override
  String get apps => 'ਪਹੁੰਚ';

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get theme => 'ਦਿੱਖ';

  @override
  String get system => 'ਸਿਸਟਮ';

  @override
  String get light => 'ਹਲਕਾ';

  @override
  String get dark => 'ਗੂੜ੍ਹਾ';

  @override
  String get message => 'ਸੁਨੇਹਾ';

  @override
  String get send => 'ਭੇਜੋ';

  @override
  String get start => 'ਮਾਈਕ੍ਰੋਫ਼ੋਨ ਚਾਲੂ ਕਰੋ';

  @override
  String get stop => 'ਮਾਈਕ੍ਰੋਫ਼ੋਨ ਬੰਦ ਕਰੋ';

  @override
  String get local => 'ਮਾਈਕ੍ਰੋਫ਼ੋਨ ਚਾਲੂ · ਆਡੀਓ ਸੰਭਾਲੀ ਜਾਂ ਭੇਜੀ ਨਹੀਂ ਜਾਂਦੀ';

  @override
  String get soon => 'AI ਗੱਲਬਾਤ ਬਾਅਦ ਵਿੱਚ ਆਵੇਗੀ';

  @override
  String get scan => 'ਐਪਾਂ ਦੀ ਸਮੀਖਿਆ';

  @override
  String get search => 'ਐਪਾਂ ਖੋਜੋ';

  @override
  String get permissions => 'ਇਜਾਜ਼ਤਾਂ';

  @override
  String get granted => 'ਮਨਜ਼ੂਰ';

  @override
  String get notGranted => 'ਮਨਜ਼ੂਰ ਨਹੀਂ';

  @override
  String get openSettings => 'ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੋ';

  @override
  String get unavailable => 'iOS ਤੇ ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get micDenied => 'ਮਾਈਕ੍ਰੋਫ਼ੋਨ ਦੀ ਇਜਾਜ਼ਤ ਨਹੀਂ ਦਿੱਤੀ ਗਈ।';

  @override
  String get micUnavailable => 'ਮਾਈਕ੍ਰੋਫ਼ੋਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।';

  @override
  String get iosGuide => 'iOS ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਇਜਾਜ਼ਤਾਂ ਦੇਖੋ।';

  @override
  String get visibilityNote =>
      'ਕੇਵਲ ਦਿਸਣ ਵਾਲੀਆਂ ਲਾਂਚਰ ਐਪਾਂ · ਇਜਾਜ਼ਤ ਵਰਤੋਂ ਦਾ ਸਬੂਤ ਨਹੀਂ।';

  @override
  String welcomeName(String name) {
    return 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਰਿਪੋਰਟਾਂ',
      one: '1 ਰਿਪੋਰਟ',
      zero: 'ਕੋਈ ਰਿਪੋਰਟ ਨਹੀਂ',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'ਐਪਾਂ ਲੋਡ ਨਹੀਂ ਹੋ ਸਕੀਆਂ।';

  @override
  String get settingsUnavailable => 'ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੀਆਂ ਨਹੀਂ ਜਾ ਸਕੀਆਂ।';

  @override
  String get consentEyebrow => 'ਗੋਪਨੀਯਤਾ ਅਤੇ ਸਹਿਮਤੀ';

  @override
  String get consentHeadline => 'ਰਿਪੋਰਟ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਸਮੀਖਿਆ ਕਰੋ';

  @override
  String get consentIntro =>
      'ਤੁਹਾਡੀ ਰਿਪੋਰਟ ਕਰਮਚਾਰੀ ਸੁਰੱਖਿਆ ਟੀਮ ਕੋਲ ਜਾਵੇਗੀ। ਸਮੀਖਿਆ ਕਰੋ ਕਿ ਕੀ ਸਾਂਝਾ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ।';

  @override
  String get consentWordsTitle => 'ਤੁਹਾਡੇ ਸ਼ਬਦ';

  @override
  String get consentWordsText =>
      'ਤੁਹਾਡੇ ਵੱਲੋਂ ਦਿੱਤੇ ਗਏ ਵੇਰਵੇ ਅਤੇ ਸਬੂਤ ਨੋਟ ਸਾਂਝੇ ਕੀਤੇ ਜਾਣਗੇ।';

  @override
  String get consentChoiceTitle => 'ਤੁਹਾਡੀਆਂ ਚੋਣਾਂ';

  @override
  String get consentChoiceText =>
      'ਡਿਵਾਈਸ ਜਾਂਚਾਂ ਵਿਕਲਪਿਕ ਹਨ ਅਤੇ ਕੇਵਲ ਤੁਹਾਡੀ ਇਜਾਜ਼ਤ ਨਾਲ ਹੀ ਸ਼ਾਮਲ ਕੀਤੀਆਂ ਜਾਂਦੀਆਂ ਹਨ।';

  @override
  String get consentStorageTitle => 'ਸੁਰੱਖਿਅਤ ਸਟੋਰੇਜ';

  @override
  String get consentStorageText =>
      'ਰਿਪੋਰਟਾਂ ਨੂੰ ਐਨਕ੍ਰਿਪਟ ਕੀਤਾ ਜਾਂਦਾ ਹੈ ਅਤੇ ਕੇਵਲ ਅੰਦਰੂਨੀ ਤੌਰ \'ਤੇ ਵਰਤਿਆ ਜਾਂਦਾ ਹੈ।';

  @override
  String get consentNotice =>
      'ਜਮ੍ਹਾਂ ਕਰਕੇ, ਤੁਸੀਂ ਨੀਤੀ ਅਤੇ ਰਿਪੋਰਟਿੰਗ ਦਿਸ਼ਾ-ਨਿਰਦੇਸ਼ਾਂ ਨਾਲ ਸਹਿਮਤ ਹੁੰਦੇ ਹੋ।';

  @override
  String get consentContinue => 'ਜਾਰੀ ਰੱਖੋ';

  @override
  String get describeIncident => 'ਘਟਨਾ ਦਾ ਵੇਰਵਾ ਦਿਓ';

  @override
  String get whatHappened => 'ਕੀ ਹੋਇਆ ਸੀ?';

  @override
  String get reviewReport => 'ਰਿਪੋਰਟ ਦੀ ਸਮੀਖਿਆ ਕਰੋ';

  @override
  String get reviewBeforeSending => 'ਭੇਜਣ ਤੋਂ ਪਹਿਲਾਂ ਸਮੀਖਿਆ ਕਰੋ';

  @override
  String get reviewFactsDescription =>
      'ਤੁਹਾਡੇ ਦਰਜ ਕੀਤੇ ਵੇਰਵੇ ਅਤੇ ਵਿਕਲਪਿਕ ਜਾਂਚਾਂ ਹੇਠਾਂ ਦਿੱਤੀਆਂ ਗਈਆਂ ਹਨ।';

  @override
  String get reviewConfirmationIncluded => 'ਪੁਸ਼ਟੀਕਰਨ ਸ਼ਾਮਲ ਹੈ';

  @override
  String get reviewConfirmFacts =>
      'ਮੈਂ ਇਸ ਜਾਣਕਾਰੀ ਦੀ ਸਮੀਖਿਆ ਕੀਤੀ ਹੈ ਅਤੇ ਪੁਸ਼ਟੀ ਕਰਦਾ ਹਾਂ।';

  @override
  String get submitting => 'ਜਮ੍ਹਾਂ ਹੋ ਰਿਹਾ ਹੈ…';

  @override
  String get confirmAndSubmit => 'ਪੁਸ਼ਟੀ ਕਰੋ ਅਤੇ ਜਮ੍ਹਾਂ ਕਰੋ';

  @override
  String get backDraftPreserved => 'ਡਰਾਫਟ ਸੁਰੱਖਿਅਤ ਹੈ';

  @override
  String get backToEdit => 'ਸੋਧਣ ਲਈ ਵਾਪਸ ਜਾਓ';

  @override
  String get syntheticExample => 'ਸਿੰਥੈਟਿਕ ਪ੍ਰਦਰਸ਼ਨ ਉਦਾਹਰਨ';

  @override
  String get pendingSubmission => 'ਜਮ੍ਹਾਂ ਕਰਨਾ ਬਾਕੀ ਹੈ';

  @override
  String get appNameOptional => 'ਐਪ ਦਾ ਨਾਮ (ਵਿਕਲਪਿਕ)';

  @override
  String get evidenceNotesOptional => 'ਸਬੂਤ ਨੋਟ (ਵਿਕਲਪਿਕ)';

  @override
  String get descriptionTooShort => 'ਵੇਰਵਾ ਬਹੁਤ ਛੋਟਾ ਹੈ।';

  @override
  String get reportLanguageLabel => 'ਰਿਪੋਰਟ ਦੀ ਭਾਸ਼ਾ';

  @override
  String get englishLanguage => 'ਅੰਗਰੇਜ਼ੀ';

  @override
  String get hindiLanguage => 'ਹਿੰਦੀ';

  @override
  String get mixedLanguage => 'ਰਲੀ-ਮਿਲੀ ਭਾਸ਼ਾ';

  @override
  String get incidentTypeLabel => 'ਘਟਨਾ ਦੀ ਕਿਸਮ';

  @override
  String get supportCall => 'ਸਹਾਇਤਾ ਕਾਲ';

  @override
  String get suspiciousMessage => 'ਸ਼ੱਕੀ ਸੁਨੇਹਾ';

  @override
  String get mistakenReport => 'ਗਲਤੀ ਨਾਲ ਦਿੱਤੀ ਰਿਪੋਰਟ';

  @override
  String get otherIncident => 'ਹੋਰ ਘਟਨਾ';

  @override
  String get optionalDeviceReview => 'ਵਿਕਲਪਿਕ ਡਿਵਾਈਸ ਸਮੀਖਿਆ';

  @override
  String get androidDeviceReview => 'Android ਡਿਵਾਈਸ ਸਮੀਖਿਆ';

  @override
  String get iosDeviceReview => 'iOS ਡਿਵਾਈਸ ਸਮੀਖਿਆ';

  @override
  String get allowOneCheck => 'ਇੱਕ ਜਾਂਚ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ';

  @override
  String get checkExplanation =>
      'ਡਿਵਾਈਸ ਦੀ ਸੁਰੱਖਿਆ ਸਥਿਤੀ ਦੀ ਜਾਂਚ ਕਰਨ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ।';

  @override
  String get cancelAction => 'ਰੱਦ ਕਰੋ';

  @override
  String get checkAndInclude => 'ਜਾਂਚੋ ਅਤੇ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get checking => 'ਜਾਂਚ ਹੋ ਰਹੀ ਹੈ…';

  @override
  String get reviewDeviceCheck => 'ਡਿਵਾਈਸ ਜਾਂਚ ਦੀ ਸਮੀਖਿਆ';

  @override
  String get removeObservation => 'ਹਟਾਓ';

  @override
  String get detailTitle => 'ਰਿਪੋਰਟ ਦੇ ਵੇਰਵੇ';

  @override
  String get ticketDetails => 'ਟਿਕਟ ਦੇ ਵੇਰਵੇ';

  @override
  String get refreshStatus => 'ਸਥਿਤੀ ਤਾਜ਼ਾ ਕਰੋ';

  @override
  String get latestUpdate => 'ਤਾਜ਼ਾ ਜਾਣਕਾਰੀ';

  @override
  String get statusLabel => 'ਸਥਿਤੀ';

  @override
  String get statusSubmitted => 'ਜਮ੍ਹਾਂ ਕਰ ਦਿੱਤੀ ਗਈ';

  @override
  String get statusInReview => 'ਸਮੀਖਿਆ ਅਧੀਨ';

  @override
  String get statusAwaitingEmployee => 'ਕਰਮਚਾਰੀ ਦੇ ਜਵਾਬ ਦੀ ਉਡੀਕ ਹੈ';

  @override
  String get statusEscalated => 'ਅਗਲੀ ਸਮੀਖਿਆ ਲਈ ਭੇਜੀ ਗਈ';

  @override
  String get statusClosed => 'ਬੰਦ';

  @override
  String get submittedAt => 'ਜਮ੍ਹਾਂ ਕਰਨ ਦਾ ਸਮਾਂ';

  @override
  String get updatedAt => 'ਤਾਜ਼ਾ ਕਰਨ ਦਾ ਸਮਾਂ';

  @override
  String get timesInUtc => 'ਸਮਾਂ UTC ਫਾਰਮੈਟ ਵਿੱਚ ਹੈ।';

  @override
  String get helpTitle => 'ਮਦਦ, ਗੋਪਨੀਯਤਾ ਅਤੇ ਸੈਟਿੰਗਾਂ';

  @override
  String get stayInControl => 'ਨਿਯੰਤਰਣ ਤੁਹਾਡੇ ਹੱਥ ਵਿੱਚ ਹੈ।';

  @override
  String get helpIntro =>
      'ਜਾਣੋ ਕਿ ਕੀ ਸਾਂਝਾ ਕੀਤਾ ਜਾਂਦਾ ਹੈ, ਕੀ ਸੁਰੱਖਿਅਤ ਹੁੰਦਾ ਹੈ ਅਤੇ ਇਸ ਪੜਾਅ ਵਿੱਚ ਕੀ ਜਾਂਚਿਆ ਜਾ ਸਕਦਾ ਹੈ।';

  @override
  String get reportExplained => 'ਤੁਹਾਡੀ ਰਿਪੋਰਟ ਦੀ ਵਿਆਖਿਆ';

  @override
  String get demoConnection => 'ਡੈਮੋ ਕਨੈਕਸ਼ਨ';

  @override
  String get openAppSettings => 'ਇਸ ਐਪ ਦੀਆਂ ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੋ';

  @override
  String get stepDescribe => 'ਵੇਰਵਾ';

  @override
  String get stepReview => 'ਸਮੀਖਿਆ';

  @override
  String get stepSubmit => 'ਜਮ੍ਹਾਂ ਕਰੋ';

  @override
  String get submittedStatements => 'ਜਮ੍ਹਾਂ ਕੀਤੇ ਬਿਆਨ';

  @override
  String get employeeReported => 'ਕਰਮਚਾਰੀ ਦੁਆਰਾ ਰਿਪੋਰਟ ਕੀਤਾ ਗਿਆ';

  @override
  String get descriptionLabel => 'ਵੇਰਵਾ';

  @override
  String get appNameLabel => 'ਐਪ ਦਾ ਨਾਮ';

  @override
  String get evidenceNotesLabel => 'ਸਬੂਤ ਨੋਟ';

  @override
  String get notSupplied => 'ਨਹੀਂ ਦਿੱਤਾ ਗਿਆ';

  @override
  String get demoEmployeeIdentity => 'ਡੈਮੋ ਕਰਮਚਾਰੀ ਦੀ ਪਛਾਣ';

  @override
  String get optionalChecks => 'ਵਿਕਲਪਿਕ ਜਾਂਚਾਂ';

  @override
  String get deviceObserved => 'ਡਿਵਾਈਸ ਨਿਰੀਖਣ';

  @override
  String get noDeviceFacts => 'ਕੋਈ ਡਿਵਾਈਸ ਜਾਣਕਾਰੀ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।';

  @override
  String get secureScreenLock => 'ਸੁਰੱਖਿਅਤ ਸਕ੍ਰੀਨ ਲੌਕ';

  @override
  String get configured => 'ਕੌਂਫਿਗਰ ਕੀਤਾ ਗਿਆ ਹੈ';

  @override
  String get notConfigured => 'ਕੌਂਫਿਗਰ ਨਹੀਂ ਕੀਤਾ ਗਿਆ';

  @override
  String get publicApiClientReported =>
      'ਪਬਲਿਕ API ਕਲਾਇੰਟ ਦੁਆਰਾ ਰਿਪੋਰਟ ਕੀਤਾ ਗਿਆ';

  @override
  String get checkedAt => 'ਜਾਂਚ ਦਾ ਸਮਾਂ';

  @override
  String get observationDisclaimer =>
      'ਨਿਰੀਖਣ ਕੇਵਲ ਡਿਵਾਈਸ ਦੀ ਸੁਰੱਖਿਆ ਸਥਿਤੀ ਨੂੰ ਦਰਸਾਉਂਦੇ ਹਨ।';

  @override
  String get helpStorage => 'ਸਟੋਰੇਜ ਅਤੇ ਗੋਪਨੀਯਤਾ';

  @override
  String get helpSettings => 'ਸੈਟਿੰਗਾਂ ਅਤੇ ਨਿਯੰਤਰਣ';

  @override
  String get helpRoles => 'ਭੂਮਿਕਾਵਾਂ ਅਤੇ ਜ਼ਿੰਮੇਵਾਰੀਆਂ';

  @override
  String get settingsOpenError => 'ਸੈਟਿੰਗਾਂ ਖੋਲ੍ਹੀਆਂ ਨਹੀਂ ਜਾ ਸਕੀਆਂ।';

  @override
  String get apiAddressLabel => 'API ਪਤਾ';

  @override
  String get apiBuildHint => 'ਬਿਲਡ ਸੰਸਕਰਣ ਅਤੇ API ਜਾਣਕਾਰੀ';

  @override
  String get voiceWelcome => 'ਆਓ ਗੱਲ ਕਰੀਏ।';

  @override
  String get voiceWelcomeHint =>
      'ਦੱਸੋ ਕੀ ਹੋਇਆ। ਤੁਸੀਂ ਬੋਲ ਸਕਦੇ ਹੋ ਜਾਂ ਲਿਖ ਸਕਦੇ ਹੋ।';

  @override
  String get voiceAssistant => 'ਅਨੁਵਾਚ ਸਹਾਇਕ';

  @override
  String get voiceYou => 'ਤੁਸੀਂ';

  @override
  String get voiceReady => 'ਸੁਣਨ ਲਈ ਤਿਆਰ';

  @override
  String get voiceConnecting => 'ਜੁੜ ਰਿਹਾ ਹੈ…';

  @override
  String get voiceListening => 'ਸੁਣ ਰਿਹਾ ਹੈ';

  @override
  String get voiceThinking => 'ਸੋਚ ਰਿਹਾ ਹੈ…';

  @override
  String get voiceSpeaking => 'ਬੋਲ ਰਿਹਾ ਹੈ';

  @override
  String get voiceEnding => 'ਗੱਲ ਮੁਕਾ ਰਿਹਾ ਹੈ…';

  @override
  String get voiceUnavailable => 'ਆਵਾਜ਼ ਉਪਲਬਧ ਨਹੀਂ। ਤੁਸੀਂ ਲਿਖ ਸਕਦੇ ਹੋ।';

  @override
  String get voicePartial => 'ਲਾਈਵ ਲਿਖਤ';

  @override
  String get voiceCorrect => 'ਲਿਖਤ ਠੀਕ ਕਰੋ';

  @override
  String get voiceUse => 'ਰਿਪੋਰਟ ਵਿੱਚ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get voiceDraft => 'ਰਿਪੋਰਟ ਦਾ ਖਰੜਾ ਵੇਖੋ';

  @override
  String get voiceStart => 'ਆਵਾਜ਼ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get voiceEnd => 'ਆਵਾਜ਼ ਬੰਦ ਕਰੋ';

  @override
  String get voiceApply => 'ਸੋਧ ਲਾਗੂ ਕਰੋ';

  @override
  String get voiceType => 'ਸੁਨੇਹਾ ਲਿਖੋ';

  @override
  String get noReports => 'ਹਾਲੇ ਕੋਈ ਰਿਪੋਰਟ ਨਹੀਂ ਹੈ';

  @override
  String get reportHistoryHint =>
      'ਜਮ੍ਹਾਂ ਕੀਤੀਆਂ ਟਿਕਟਾਂ ਅਤੇ ਉਨ੍ਹਾਂ ਦੀ ਨਵੀਨਤਮ ਸਥਿਤੀ ਇੱਥੇ ਦਿਸੇਗੀ।';

  @override
  String get refreshReports => 'ਰਿਪੋਰਟਾਂ ਤਾਜ਼ਾ ਕਰੋ';

  @override
  String get tryAgain => 'ਮੁੜ ਕੋਸ਼ਿਸ਼ ਕਰੋ';
}
