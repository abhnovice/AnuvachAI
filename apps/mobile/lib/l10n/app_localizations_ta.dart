// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get unknown => 'தெரியாது';

  @override
  String get check => 'சரிபார்';

  @override
  String get reports => 'அறிக்கைகள்';

  @override
  String get apps => 'அணுகல்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get theme => 'தோற்றம்';

  @override
  String get system => 'கணினி';

  @override
  String get light => 'வெளிர்';

  @override
  String get dark => 'இருண்ட';

  @override
  String get message => 'செய்தி';

  @override
  String get send => 'அனுப்பு';

  @override
  String get start => 'மைக்ரோஃபோனைத் தொடங்கு';

  @override
  String get stop => 'மைக்ரோஃபோனை நிறுத்து';

  @override
  String get local => 'மைக்ரோஃபோன் இயக்கத்தில் · ஒலி சேமிக்கவோ அனுப்பவோ இல்லை';

  @override
  String get soon => 'AI உரையாடல் பின்னர் வரும்';

  @override
  String get scan => 'செயலிகளைப் பார்வையிடு';

  @override
  String get search => 'செயலிகளைத் தேடு';

  @override
  String get permissions => 'அனுமதிகள்';

  @override
  String get granted => 'அனுமதிக்கப்பட்டது';

  @override
  String get notGranted => 'அனுமதி இல்லை';

  @override
  String get openSettings => 'அமைப்புகளைத் திற';

  @override
  String get unavailable => 'iOS இல் கிடைக்காது';

  @override
  String get micDenied => 'மைக்ரோஃபோன் அனுமதி வழங்கப்படவில்லை.';

  @override
  String get micUnavailable => 'மைக்ரோஃபோன் கிடைக்கவில்லை.';

  @override
  String get iosGuide => 'iOS அமைப்புகளில் அனுமதிகளைப் பாருங்கள்.';

  @override
  String get visibilityNote =>
      'காணக்கூடிய தொடக்கச் செயலிகள் மட்டும் · அனுமதி பயன்பாட்டை நிரூபிக்காது.';

  @override
  String welcomeName(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count அறிக்கைகள்',
      one: '1 அறிக்கை',
      zero: 'அறிக்கைகள் இல்லை',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'செயலிகளை ஏற்ற முடியவில்லை.';

  @override
  String get settingsUnavailable => 'அமைப்புகளைத் திறக்க முடியவில்லை.';

  @override
  String get consentEyebrow => 'பணியாளர் சம்பவ அறிக்கை';

  @override
  String get consentHeadline => 'தெளிவான விளக்கம்.\nபாதுகாப்பான அடுத்த படி.';

  @override
  String get consentIntro =>
      'ஏதோ தவறாகத் தோன்றியதா? இங்கே தொடங்குங்கள்.\nஉங்கள் சொற்களில் விவரித்து, பகிர்வதற்கு முன் மதிப்பாய்வு செய்யுங்கள்.';

  @override
  String get consentWordsTitle => 'உங்கள் சொற்கள், உங்கள் அறிக்கை';

  @override
  String get consentWordsText =>
      'விளக்கம், மொழி, சம்பவ வகை மற்றும் விருப்பமான செயலி மற்றும் ஆதாரக் குறிப்புகள்.';

  @override
  String get consentChoiceTitle =>
      'எதைப் பகிர வேண்டும் என்பதை நீங்களே தேர்வுசெய்கிறீர்கள்';

  @override
  String get consentChoiceText =>
      'சாதனச் சோதனைகள் விருப்பமானவை. நீங்கள் மதிப்பாய்வு செய்து உறுதிப்படுத்தும் வரை எதுவும் சமர்ப்பிக்கப்படாது.';

  @override
  String get consentStorageTitle =>
      'இந்த விளக்கத்திற்காக உள்ளூரில் சேமிக்கப்படுகிறது';

  @override
  String get consentStorageText =>
      'வரைவுகள் இந்தச் சாதனத்தில் இருக்கும். சமர்ப்பிக்கப்பட்ட அறிக்கைகள் நிர்வாக மதிப்பாய்விற்காக உள்ளூர் APIக்கு அனுப்பப்படும்.';

  @override
  String get consentNotice =>
      'செயற்கை விளக்கத்திற்காக மட்டும். உண்மையான பணியாளர் தகவலை உள்ளிட வேண்டாம். உள்நுழைவு அல்லது பயன்பாட்டிற்கான அணுகல் கட்டுப்பாடுகள் இல்லை. மைக்ரோஃபோன் ஒலி சேமிக்கப்படவோ, அனுப்பப்படவோ, பகுப்பாய்வு செய்யப்படவோ இல்லை.';

  @override
  String get consentContinue => 'புரிந்தது · தொடரவும்';

  @override
  String get describeIncident => 'சம்பவத்தை விவரிக்கவும்';

  @override
  String get whatHappened => 'என்ன நடந்தது?';

  @override
  String get reviewReport => 'அறிக்கையை மதிப்பாய்வு செய்க';

  @override
  String get reviewBeforeSending => 'அனுப்பும் முன் மதிப்பாய்வு செய்யவும்';

  @override
  String get reviewFactsDescription =>
      'அனுப்பப்படும் அறிக்கை விவரங்கள் இவை. API புகார் எண், நேரங்கள் மற்றும் ஆரம்ப நிலையைச் சேர்க்கும்.';

  @override
  String get reviewConfirmationIncluded =>
      'சமர்ப்பிப்பில் உங்கள் வெளிப்படையான உறுதிப்படுத்தல் அடங்கும்: true.';

  @override
  String get reviewConfirmFacts =>
      'இந்த விவரங்களை உறுதிசெய்து புகாரை உருவாக்க விரும்புகிறேன்.';

  @override
  String get submitting => 'சமர்ப்பிக்கப்படுகிறது…';

  @override
  String get confirmAndSubmit => 'உறுதிசெய்து சமர்ப்பிக்கவும்';

  @override
  String get backDraftPreserved => 'திரும்பு · வரைவு பாதுகாக்கப்பட்டது';

  @override
  String get backToEdit => 'திருத்தத் திரும்பு';

  @override
  String get syntheticExample =>
      'செயற்கையான விவரங்களை மட்டும் பயன்படுத்தவும். உதாரணம்: எதிர்பாராத தகவல் தொழில்நுட்ப ஆதரவு அழைப்பாளர் தொலைநிலை அணுகல் செயலியை நிறுவ அல்லது குறியீட்டைப் பகிரக் கேட்டார்.';

  @override
  String get pendingSubmission =>
      'ஒரு சமர்ப்பிப்பு ஏற்கனவே API-ஐ அடைந்திருக்கலாம். புகாரைப் பாதுகாப்பாகப் பெற, சேமிக்கப்பட்ட மதிப்பாய்வு அறிக்கையை மீண்டும் முயற்சிக்கவும். இது தீரும் வரை திருத்தம் நிறுத்தப்படும்.';

  @override
  String get appNameOptional => 'செயலியின் பெயர் (விருப்பமானது)';

  @override
  String get evidenceNotesOptional => 'ஆதாரக் குறிப்புகள் (விருப்பமானவை)';

  @override
  String get descriptionTooShort =>
      'சம்பவத்தை குறைந்தது 10 எழுத்துகளில் விவரிக்கவும்.';

  @override
  String get reportLanguageLabel => 'அறிக்கை மொழி';

  @override
  String get englishLanguage => 'ஆங்கிலம்';

  @override
  String get hindiLanguage => 'இந்தி';

  @override
  String get mixedLanguage => 'ஆங்கிலம் / இந்தி கலப்பு';

  @override
  String get incidentTypeLabel => 'சம்பவ வகை';

  @override
  String get supportCall => 'ஆதரவு அழைப்பு';

  @override
  String get suspiciousMessage => 'சந்தேகத்திற்குரிய செய்தி';

  @override
  String get mistakenReport => 'தவறான அறிக்கை';

  @override
  String get otherIncident => 'மற்றவை';

  @override
  String get optionalDeviceReview => 'விருப்பமான சாதன மதிப்பாய்வு';

  @override
  String get androidDeviceReview =>
      'உங்கள் ஒப்புதலுடன், பாதுகாப்பான திரைப் பூட்டு இருப்பதாக Android தெரிவிக்கிறதா எனச் சரிபார்க்கவும். நிறுவப்பட்ட தொலைநிலை அணுகல் செயலிகளையோ அனுமதிப் பயன்பாட்டையோ இது சரிபார்க்காது.';

  @override
  String get iosDeviceReview =>
      'இந்த நிலையில் iOS-இல் தானியக்க சாதனச் சோதனைகள் கிடைக்காது. அமைப்புகளில் நிறுவப்பட்ட செயலிகளையும் அனுமதிகளையும் கைமுறையாக மதிப்பாய்வு செய்யவும் அல்லது தெரிந்த உதவி மையத்தைத் தொடர்புகொள்ளவும்.';

  @override
  String get allowOneCheck => 'இந்த ஒரு சோதனையை அனுமதிக்கவா?';

  @override
  String get checkExplanation =>
      'பாதுகாப்பான திரைப் பூட்டு அமைப்பை இப்போது படித்து, அதன் முடிவையும் நேரத்தையும் உங்கள் அறிக்கையில் சேர்க்கவும். இயக்கநேர அனுமதி தேவையில்லை.';

  @override
  String get cancelAction => 'ரத்துசெய்';

  @override
  String get checkAndInclude => 'சரிபார்த்துச் சேர்';

  @override
  String get checking => 'சரிபார்க்கப்படுகிறது…';

  @override
  String get reviewDeviceCheck =>
      'சாதனச் சோதனையை மதிப்பாய்வு செய்து ஒப்புதல் அளிக்கவும்';

  @override
  String get removeObservation => 'சாதனக் கண்காணிப்பை நீக்கு';

  @override
  String get detailTitle => 'அறிக்கை விவரம்';

  @override
  String get ticketDetails => 'புகார் விவரங்கள்';

  @override
  String get refreshStatus => 'நிலையைப் புதுப்பி';

  @override
  String get latestUpdate => 'சமீபத்திய புதுப்பிப்பு';

  @override
  String get statusLabel => 'நிலை';

  @override
  String get statusSubmitted => 'சமர்ப்பிக்கப்பட்டது';

  @override
  String get statusInReview => 'மதிப்பாய்வில் உள்ளது';

  @override
  String get statusAwaitingEmployee => 'பணியாளருக்காகக் காத்திருக்கிறது';

  @override
  String get statusEscalated => 'மேலாய்வுக்கு அனுப்பப்பட்டது';

  @override
  String get statusClosed => 'மூடப்பட்டது';

  @override
  String get submittedAt => 'சமர்ப்பிக்கப்பட்டது';

  @override
  String get updatedAt => 'புதுப்பிக்கப்பட்டது';

  @override
  String get timesInUtc => 'நேரங்கள் UTC-இல் காட்டப்படுகின்றன.';

  @override
  String get helpTitle => 'உதவி, தனியுரிமை மற்றும் அமைப்புகள்';

  @override
  String get stayInControl => 'கட்டுப்பாடு உங்களிடமே உள்ளது.';

  @override
  String get helpIntro =>
      'எது பகிரப்படுகிறது, சேமிக்கப்படுகிறது மற்றும் இந்த நிலையில் எதைச் சரிபார்க்கலாம் என்பதை அறியவும்.';

  @override
  String get reportExplained => 'உங்கள் அறிக்கை பற்றிய விளக்கம்';

  @override
  String get demoConnection => 'மாதிரி இணைப்பு';

  @override
  String get openAppSettings => 'இந்தச் செயலியின் அமைப்புகளைத் திற';

  @override
  String get stepDescribe => 'விவரி';

  @override
  String get stepReview => 'மதிப்பாய்வு';

  @override
  String get stepSubmit => 'சமர்ப்பி';

  @override
  String get submittedStatements => 'சமர்ப்பிக்கப்பட்ட தகவல்கள்';

  @override
  String get employeeReported => 'பணியாளர் தெரிவித்தவை';

  @override
  String get descriptionLabel => 'விளக்கம்';

  @override
  String get appNameLabel => 'செயலியின் பெயர்';

  @override
  String get evidenceNotesLabel => 'ஆதாரக் குறிப்புகள்';

  @override
  String get notSupplied => 'வழங்கப்படவில்லை';

  @override
  String get demoEmployeeIdentity => 'பணியாளர் அடையாளம்: demo-employee';

  @override
  String get optionalChecks => 'விருப்பச் சோதனைகள்';

  @override
  String get deviceObserved => 'சாதனத்தில் கண்டவை';

  @override
  String get noDeviceFacts =>
      'தானியக்கச் சாதனத் தகவல்கள் எதுவும் சேர்க்கப்படவில்லை.';

  @override
  String get secureScreenLock => 'பாதுகாப்பான திரைப் பூட்டு';

  @override
  String get configured => 'அமைக்கப்பட்டுள்ளது';

  @override
  String get notConfigured => 'அமைக்கப்படவில்லை';

  @override
  String get publicApiClientReported =>
      'Android பொதுப் பயன்பாட்டு இடைமுகம் · சாதனம் தெரிவித்தது';

  @override
  String get checkedAt => 'சரிபார்க்கப்பட்ட நேரம்';

  @override
  String get observationDisclaimer =>
      'இந்தக் கண்காணிப்புகள் தொலைநிலை அணுகல், ஊடுருவல் அல்லது அனுமதி பயன்படுத்தப்பட்டதா என்பதை உறுதிப்படுத்தாது.';

  @override
  String get helpStorage =>
      'செயற்கைத் தரவை மட்டும் பயன்படுத்தவும். வரைவுகள் குறியாக்கமின்றி செயலியின் உள்ளூர் விருப்பத்தேர்வுகளில் சேமிக்கப்படும். சமர்ப்பிக்கப்பட்ட தகவல்கள் உள்ளூர் API மூலம் SQLite-இல் சேமிக்கப்படும். நிர்வாகிக் குறிப்புகள் நிர்வாகி பார்வையில் மட்டுமே இருக்கும். இந்த விளக்கத்தில் அங்கீகாரம் இல்லை.';

  @override
  String get helpSettings =>
      'அமைப்புகளைத் திறப்பது எந்த அமைப்பையும் மாற்றாது. Android மற்றும் iOS-இல் இந்தச் செயலியின் அமைப்புகளைத் திறக்கலாம். பிற செயலிகளையும் அனுமதிகளையும் கணினி அமைப்புகளில் கைமுறையாக மதிப்பாய்வு செய்யவும். காணப்படும் அனுமதி பயன்படுத்தப்பட்டதை நிரூபிக்காது.';

  @override
  String get helpRoles =>
      'இந்த விளக்கத்தில் பாதுகாப்பு மற்றும் தரவுப் பாதுகாப்பு தனித்தனி மதிப்பாய்வாளர் பொறுப்புகள். உண்மையான பணியாளர் தரவிற்குச் சேவையக அணுகல் கட்டுப்பாடும் வரையறுக்கப்பட்ட தரவுத் தக்கவைப்பு கொள்கையும் தேவை.';

  @override
  String get settingsOpenError =>
      'அமைப்புகளைத் திறக்க முடியவில்லை. கணினி அமைப்புகளைக் கைமுறையாகத் திறக்கவும்.';

  @override
  String get apiAddressLabel => 'API முகவரி';

  @override
  String get apiBuildHint =>
      'உருவாக்கும் அல்லது இயக்கும் போது API_BASE_URL அமைக்கவும்.';

  @override
  String get voiceWelcome => 'பேசித் தீர்ப்போம்.';

  @override
  String get voiceWelcomeHint =>
      'என்ன நடந்தது என்று சொல்லுங்கள். பேசலாம் அல்லது தட்டச்சு செய்யலாம்.';

  @override
  String get voiceAssistant => 'அனுவாச் உதவியாளர்';

  @override
  String get voiceYou => 'நீங்கள்';

  @override
  String get voiceReady => 'கேட்கத் தயார்';

  @override
  String get voiceConnecting => 'இணைக்கிறது…';

  @override
  String get voiceListening => 'கேட்கிறது';

  @override
  String get voiceThinking => 'சிந்திக்கிறது…';

  @override
  String get voiceSpeaking => 'பேசுகிறது';

  @override
  String get voiceEnding => 'முடிக்கிறது…';

  @override
  String get voiceUnavailable =>
      'குரல் வசதி கிடைக்கவில்லை. தட்டச்சு செய்யலாம்.';

  @override
  String get voicePartial => 'நேரடி உரை';

  @override
  String get voiceCorrect => 'உரையைத் திருத்தவும்';

  @override
  String get voiceUse => 'அறிக்கையில் சேர்க்கவும்';

  @override
  String get voiceDraft => 'வரைவு அறிக்கையைப் பார்க்கவும்';

  @override
  String get voiceStart => 'குரலைத் தொடங்கவும்';

  @override
  String get voiceEnd => 'குரலை நிறுத்தவும்';

  @override
  String get voiceApply => 'திருத்தத்தைப் பயன்படுத்தவும்';

  @override
  String get voiceType => 'செய்தியைத் தட்டச்சு செய்யவும்';

  @override
  String get noReports => 'இன்னும் அறிக்கைகள் இல்லை';

  @override
  String get reportHistoryHint =>
      'சமர்ப்பித்த டிக்கெட்டுகளும் அவற்றின் தற்போதைய நிலையும் இங்கே தெரியும்.';

  @override
  String get refreshReports => 'அறிக்கைகளைப் புதுப்பிக்கவும்';

  @override
  String get tryAgain => 'மீண்டும் முயலவும்';
}
