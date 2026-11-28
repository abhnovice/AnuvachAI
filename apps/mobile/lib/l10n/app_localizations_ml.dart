// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get unknown => 'അജ്ഞാതം';

  @override
  String get check => 'പരിശോധന';

  @override
  String get reports => 'റിപ്പോർട്ടുകൾ';

  @override
  String get apps => 'ആക്സസ്';

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get language => 'ഭാഷ';

  @override
  String get theme => 'രൂപം';

  @override
  String get system => 'സിസ്റ്റം';

  @override
  String get light => 'ലൈറ്റ്';

  @override
  String get dark => 'ഡാർക്ക്';

  @override
  String get message => 'സന്ദേശം';

  @override
  String get send => 'അയയ്ക്കുക';

  @override
  String get start => 'മൈക്രോഫോൺ ആരംഭിക്കുക';

  @override
  String get stop => 'മൈക്രോഫോൺ നിർത്തുക';

  @override
  String get local => 'മൈക്രോഫോൺ ഓൺ · ഓഡിയോ സേവ് ചെയ്യുകയോ അയയ്ക്കുകയോ ഇല്ല';

  @override
  String get soon => 'AI സംഭാഷണം പിന്നീട് വരും';

  @override
  String get scan => 'ആപ്പുകൾ പരിശോധിക്കുക';

  @override
  String get search => 'ആപ്പുകൾ തിരയുക';

  @override
  String get permissions => 'അനുമതികൾ';

  @override
  String get granted => 'അനുവദിച്ചു';

  @override
  String get notGranted => 'അനുവദിച്ചിട്ടില്ല';

  @override
  String get openSettings => 'ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get unavailable => 'iOS-ൽ ലഭ്യമല്ല';

  @override
  String get micDenied => 'മൈക്രോഫോൺ അനുമതി നൽകിയിട്ടില്ല.';

  @override
  String get micUnavailable => 'മൈക്രോഫോൺ ലഭ്യമല്ല.';

  @override
  String get iosGuide => 'iOS ക്രമീകരണങ്ങളിൽ അനുമതികൾ പരിശോധിക്കുക.';

  @override
  String get visibilityNote =>
      'ദൃശ്യമാകുന്ന ലോഞ്ചർ ആപ്പുകൾ മാത്രം · അനുമതി ഉപയോഗത്തിന് തെളിവല്ല.';

  @override
  String welcomeName(String name) {
    return 'നമസ്കാരം, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count റിപ്പോർട്ടുകൾ',
      one: '1 റിപ്പോർട്ട്',
      zero: 'റിപ്പോർട്ടുകളില്ല',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'ആപ്പുകൾ ലോഡ് ചെയ്യാനായില്ല.';

  @override
  String get settingsUnavailable => 'ക്രമീകരണങ്ങൾ തുറക്കാനായില്ല.';

  @override
  String get consentEyebrow => 'സ്വകാര്യതയും സമ്മതവും';

  @override
  String get consentHeadline => 'റിപ്പോർട്ട് ചെയ്യുന്നതിന് മുമ്പ് പരിശോധിക്കുക';

  @override
  String get consentIntro =>
      'നിങ്ങളുടെ റിപ്പോർട്ട് സുരക്ഷാ ടീമിലേക്ക് എത്തും. എന്താണ് പങ്കിടുന്നതെന്ന് അവലോകനം ചെയ്യുക.';

  @override
  String get consentWordsTitle => 'നിങ്ങളുടെ വാക്കുകൾ';

  @override
  String get consentWordsText =>
      'നിങ്ങൾ നൽകിയ വിവരണവും കുറിപ്പുകളും പങ്കിടപ്പെടും.';

  @override
  String get consentChoiceTitle => 'നിങ്ങളുടെ തിരഞ്ഞെടുപ്പുകൾ';

  @override
  String get consentChoiceText =>
      'ഉപകരണ പരിശോധനകൾ ഓപ്ഷണലാണ്, നിങ്ങൾ അനുവദിച്ചാൽ മാത്രമേ ഉൾപ്പെടുത്തൂ.';

  @override
  String get consentStorageTitle => 'സുരക്ഷിത സംഭരണം';

  @override
  String get consentStorageText =>
      'റിപ്പോർട്ടുകൾ എൻക്രിപ്റ്റ് ചെയ്തതും ആന്തരികമായി മാത്രം ഉപയോഗിക്കുന്നതുമാണ്.';

  @override
  String get consentNotice =>
      'സമർപ്പിക്കുന്നതിലൂടെ, നിങ്ങൾ നയ മാർഗ്ഗനിർദ്ദേശങ്ങൾ അംഗീകരിക്കുന്നു.';

  @override
  String get consentContinue => 'തുടരുക';

  @override
  String get describeIncident => 'സംഭവം വിവരിക്കുക';

  @override
  String get whatHappened => 'എന്താണ് സംഭവിച്ചത്?';

  @override
  String get reviewReport => 'റിപ്പോർട്ട് പരിശോധിക്കുക';

  @override
  String get reviewBeforeSending => 'അയയ്ക്കുന്നതിന് മുമ്പ് പരിശോധിക്കുക';

  @override
  String get reviewFactsDescription =>
      'നിങ്ങൾ നൽകിയ വിവരങ്ങളും ഓപ്ഷണൽ പരിശോധനകളും താഴെ നൽകിയിരിക്കുന്നു.';

  @override
  String get reviewConfirmationIncluded => 'സ്ഥിരീകരണം ഉൾപ്പെടുത്തിയിട്ടുണ്ട്';

  @override
  String get reviewConfirmFacts =>
      'ഞാൻ ഈ വിവരങ്ങൾ പരിശോധിച്ച് സ്ഥിരീകരിക്കുന്നു.';

  @override
  String get submitting => 'സമർപ്പിക്കുന്നു…';

  @override
  String get confirmAndSubmit => 'സ്ഥിരീകരിച്ച് സമർപ്പിക്കുക';

  @override
  String get backDraftPreserved => 'ഡ്രാഫ്റ്റ് സംരക്ഷിച്ചിരിക്കുന്നു';

  @override
  String get backToEdit => 'തിരുത്താൻ മടങ്ങുക';

  @override
  String get syntheticExample => 'സിന്തറ്റിക് ഡെമോ ഉദാഹരണം';

  @override
  String get pendingSubmission => 'സമർപ്പിക്കാൻ ബാക്കിയുണ്ട്';

  @override
  String get appNameOptional => 'ആപ്പിൻ്റെ പേര് (ഓപ്ഷണൽ)';

  @override
  String get evidenceNotesOptional => 'തെളിവ് കുറിപ്പുകൾ (ഓപ്ഷണൽ)';

  @override
  String get descriptionTooShort => 'വിവരണം വളരെ ചെറുതാണ്.';

  @override
  String get reportLanguageLabel => 'റിപ്പോർട്ടിൻ്റെ ഭാഷ';

  @override
  String get englishLanguage => 'ഇംഗ്ലീഷ്';

  @override
  String get hindiLanguage => 'ഹിന്ദി';

  @override
  String get mixedLanguage => 'മിശ്ര ഭാഷ';

  @override
  String get incidentTypeLabel => 'സംഭവത്തിന്റെ തരം';

  @override
  String get supportCall => 'സപ്പോർട്ട് കോൾ';

  @override
  String get suspiciousMessage => 'സംശയാസ്പദമായ സന്ദേശം';

  @override
  String get mistakenReport => 'അബദ്ധത്തിൽ നൽകിയ റിപ്പോർട്ട്';

  @override
  String get otherIncident => 'മറ്റ് സംഭവം';

  @override
  String get optionalDeviceReview => 'ഓപ്ഷണൽ ഉപകരണ പരിശോധന';

  @override
  String get androidDeviceReview => 'Android ഉപകരണ പരിശോധന';

  @override
  String get iosDeviceReview => 'iOS ഉപകരണ പരിശോധന';

  @override
  String get allowOneCheck => 'ഒരു പരിശോധന അനുവദിക്കുക';

  @override
  String get checkExplanation => 'ഉപകരണ സുരക്ഷാ നില പരിശോധിക്കാൻ അനുവദിക്കുക.';

  @override
  String get cancelAction => 'റദ്ദാക്കുക';

  @override
  String get checkAndInclude => 'പരിശോധിച്ച് ഉൾപ്പെടുത്തുക';

  @override
  String get checking => 'പരിശോധിക്കുന്നു…';

  @override
  String get reviewDeviceCheck => 'ഉപകരണ പരിശോധന അവലോകനം ചെയ്യുക';

  @override
  String get removeObservation => 'നീക്കം ചെയ്യുക';

  @override
  String get detailTitle => 'റിപ്പോർട്ട് വിശദാംശങ്ങൾ';

  @override
  String get ticketDetails => 'ടിക്കറ്റ് വിശദാംശങ്ങൾ';

  @override
  String get refreshStatus => 'സ്റ്റാറ്റസ് പുതുക്കുക';

  @override
  String get latestUpdate => 'ഏറ്റവും പുതിയ വിവരങ്ങൾ';

  @override
  String get statusLabel => 'സ്റ്റാറ്റസ്';

  @override
  String get statusSubmitted => 'സമർപ്പിച്ചു';

  @override
  String get statusInReview => 'പരിശോധനയിലാണ്';

  @override
  String get statusAwaitingEmployee =>
      'ജീവനക്കാരൻ്റെ പ്രതികരണത്തിനായി കാത്തിരിക്കുന്നു';

  @override
  String get statusEscalated => 'ഉയർന്ന പരിശോധനയ്ക്കായി കൈമാറി';

  @override
  String get statusClosed => 'അടച്ചു';

  @override
  String get submittedAt => 'സമർപ്പിച്ചത്';

  @override
  String get updatedAt => 'അവസാനം പുതുക്കിയത്';

  @override
  String get timesInUtc => 'സമയങ്ങൾ UTC ഫോർമാറ്റിലാണ് നൽകിയിരിക്കുന്നത്.';

  @override
  String get helpTitle => 'സഹായം, സ്വകാര്യത, ക്രമീകരണങ്ങൾ';

  @override
  String get stayInControl => 'നിയന്ത്രണം നിങ്ങളുടെ കൈകളിലാണ്.';

  @override
  String get helpIntro =>
      'എന്താണ് പങ്കിടുന്നത്, സംഭരിക്കുന്നത്, പരിശോധിക്കുന്നത് എന്ന് മനസ്സിലാക്കുക.';

  @override
  String get reportExplained => 'നിങ്ങളുടെ റിപ്പോർട്ടിൻ്റെ വിശദീകരണം';

  @override
  String get demoConnection => 'ഡെമോ കണക്ഷൻ';

  @override
  String get openAppSettings => 'ഈ ആപ്പിൻ്റെ ക്രമീകരണങ്ങൾ തുറക്കുക';

  @override
  String get stepDescribe => 'വിവരിക്കുക';

  @override
  String get stepReview => 'പരിശോധിക്കുക';

  @override
  String get stepSubmit => 'സമർപ്പിക്കുക';

  @override
  String get submittedStatements => 'സമർപ്പിച്ച വിവരങ്ങൾ';

  @override
  String get employeeReported => 'ജീവനക്കാരൻ റിപ്പോർട്ട് ചെയ്തത്';

  @override
  String get descriptionLabel => 'വിവരണം';

  @override
  String get appNameLabel => 'ആപ്പിൻ്റെ പേര്';

  @override
  String get evidenceNotesLabel => 'തെളിവ് കുറിപ്പുകൾ';

  @override
  String get notSupplied => 'നൽകിയിട്ടില്ല';

  @override
  String get demoEmployeeIdentity => 'ഡെമോ ജീവനക്കാരന്റെ ഐഡന്റിറ്റി';

  @override
  String get optionalChecks => 'ഓപ്ഷണൽ പരിശോധനകൾ';

  @override
  String get deviceObserved => 'ഉപകരണ നിരീക്ഷണങ്ങൾ';

  @override
  String get noDeviceFacts => 'ഉപകരണ വിവരങ്ങൾ ലഭ്യമല്ല.';

  @override
  String get secureScreenLock => 'സുരക്ഷിത സ്ക്രീൻ ലോക്ക്';

  @override
  String get configured => 'ക്രമീകരിച്ചിട്ടുണ്ട്';

  @override
  String get notConfigured => 'ക്രമീകരിച്ചിട്ടില്ല';

  @override
  String get publicApiClientReported =>
      'പബ്ലിക് API ക്ലയൻ്റ് റിപ്പോർട്ട് ചെയ്തത്';

  @override
  String get checkedAt => 'പരിശോധിച്ച സമയം';

  @override
  String get observationDisclaimer =>
      'നിരീക്ഷണങ്ങൾ ഉപകരണത്തിന്റെ സുരക്ഷാ നിലയെ മാത്രമാണ് സൂചിപ്പിക്കുന്നത്.';

  @override
  String get helpStorage => 'സംഭരണവും സ്വകാര്യതയും';

  @override
  String get helpSettings => 'ക്രമീകരണങ്ങളും നിയന്ത്രണങ്ങളും';

  @override
  String get helpRoles => 'റോളുകളും ഉത്തരവാദിത്തങ്ങളും';

  @override
  String get settingsOpenError => 'ക്രമീകരണങ്ങൾ തുറക്കാനായില്ല.';

  @override
  String get apiAddressLabel => 'API വിലാസം';

  @override
  String get apiBuildHint => 'ബിൽഡ് പതിപ്പും API വിവരങ്ങളും';

  @override
  String get voiceWelcome => 'സംസാരിക്കാം.';

  @override
  String get voiceWelcomeHint =>
      'എന്താണ് സംഭവിച്ചതെന്ന് പറയൂ. സംസാരിക്കുകയോ ടൈപ്പ് ചെയ്യുകയോ ചെയ്യാം.';

  @override
  String get voiceAssistant => 'അനുവാച് സഹായി';

  @override
  String get voiceYou => 'നിങ്ങൾ';

  @override
  String get voiceReady => 'കേൾക്കാൻ തയ്യാറാണ്';

  @override
  String get voiceConnecting => 'ബന്ധിപ്പിക്കുന്നു…';

  @override
  String get voiceListening => 'കേൾക്കുന്നു';

  @override
  String get voiceThinking => 'ആലോചിക്കുന്നു…';

  @override
  String get voiceSpeaking => 'സംസാരിക്കുന്നു';

  @override
  String get voiceEnding => 'അവസാനിപ്പിക്കുന്നു…';

  @override
  String get voiceUnavailable => 'ശബ്ദസേവനം ലഭ്യമല്ല. ടൈപ്പ് ചെയ്യാം.';

  @override
  String get voicePartial => 'തത്സമയ പകർപ്പ്';

  @override
  String get voiceCorrect => 'പകർപ്പ് തിരുത്തുക';

  @override
  String get voiceUse => 'റിപ്പോർട്ടിൽ ചേർക്കുക';

  @override
  String get voiceDraft => 'റിപ്പോർട്ട് കരട് കാണുക';

  @override
  String get voiceStart => 'ശബ്ദം ആരംഭിക്കുക';

  @override
  String get voiceEnd => 'ശബ്ദം നിർത്തുക';

  @override
  String get voiceApply => 'തിരുത്തൽ ഉപയോഗിക്കുക';

  @override
  String get voiceType => 'സന്ദേശം ടൈപ്പ് ചെയ്യുക';

  @override
  String get noReports => 'ഇതുവരെ റിപ്പോർട്ടുകളില്ല';

  @override
  String get reportHistoryHint =>
      'സമർപ്പിച്ച ടിക്കറ്റുകളും അവയുടെ ഏറ്റവും പുതിയ നിലയും ഇവിടെ കാണാം.';

  @override
  String get refreshReports => 'റിപ്പോർട്ടുകൾ പുതുക്കുക';

  @override
  String get tryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get showReports => 'റിപ്പോർട്ടുകൾ കാണിക്കുക';

  @override
  String get callPrompt => 'എന്നെ വിളിച്ചയാൾ സ്വയം ഇങ്ങനെ പരിചയപ്പെടുത്തി';

  @override
  String get messagePrompt =>
      'എനിക്ക് ലഭിച്ച സന്ദേശത്തിൽ ഇങ്ങനെ ചെയ്യാൻ ആവശ്യപ്പെട്ടു';

  @override
  String get voiceLogoStart => 'അനുവാച് ലോഗോ ഉപയോഗിച്ച് ശബ്ദം തുടങ്ങുക';

  @override
  String get accessOverview => 'ആപ്പ് ആക്‌സസ് അവലോകനം';

  @override
  String get accessBriefing => 'Gemini · ആക്‌സസിബിലിറ്റി സംഗ്രഹം';

  @override
  String get accessBriefingUnavailable =>
      'Gemini സംഗ്രഹം ഇവിടെ ലഭ്യമല്ല. ആപ്പുകളും ക്രമീകരണങ്ങളും ഉപകരണത്തിൽ കാണാം.';

  @override
  String get voiceStartupNotice =>
      'കൃത്രിമ വിവരങ്ങൾ മാത്രം ഉപയോഗിക്കുക. Android-ൽ മൈക്രോഫോൺ അനുമതി നേരത്തേ നൽകിയിട്ടുണ്ടെങ്കിൽ ആപ്പ് തുറക്കുമ്പോൾ ശബ്ദം തുടങ്ങും. ശബ്ദം നിർത്തുകയോ ചെക്ക് സ്ക്രീൻ വിടുകയോ ചെയ്യുന്നതുവരെ മൈക്രോഫോൺ ഓഡിയോ റിപ്പോർട്ടിങ് സഹായിയിലേക്ക് അയയ്ക്കും.';
}
