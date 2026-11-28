// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get unknown => 'తెలియదు';

  @override
  String get check => 'తనిఖీ';

  @override
  String get reports => 'నివేదికలు';

  @override
  String get apps => 'యాక్సెస్';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get language => 'భాష';

  @override
  String get theme => 'రూపం';

  @override
  String get system => 'సిస్టమ్';

  @override
  String get light => 'లైట్';

  @override
  String get dark => 'డార్క్';

  @override
  String get message => 'సందేశం';

  @override
  String get send => 'పంపు';

  @override
  String get start => 'మైక్రోఫోన్ ప్రారంభించు';

  @override
  String get stop => 'మైక్రోఫోన్ ఆపు';

  @override
  String get local => 'మైక్రోఫోన్ ఆన్ · ఆడియో సేవ్ లేదా పంపబడదు';

  @override
  String get soon => 'AI సంభాషణ తర్వాత వస్తుంది';

  @override
  String get scan => 'యాప్‌లను పరిశీలించు';

  @override
  String get search => 'యాప్‌లను వెతుకు';

  @override
  String get permissions => 'అనుమతులు';

  @override
  String get granted => 'అనుమతించబడింది';

  @override
  String get notGranted => 'అనుమతి లేదు';

  @override
  String get openSettings => 'సెట్టింగ్‌లు తెరువు';

  @override
  String get unavailable => 'iOS లో అందుబాటులో లేదు';

  @override
  String get micDenied => 'మైక్రోఫోన్ అనుమతి ఇవ్వలేదు.';

  @override
  String get micUnavailable => 'మైక్రోఫోన్ అందుబాటులో లేదు.';

  @override
  String get iosGuide => 'iOS సెట్టింగ్‌లలో అనుమతులను చూడండి.';

  @override
  String get visibilityNote =>
      'కనిపించే లాంచర్ యాప్‌లు మాత్రమే · అనుమతి వాడకానికి రుజువు కాదు.';

  @override
  String welcomeName(String name) {
    return 'నమస్కారం, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count నివేదికలు',
      one: '1 నివేదిక',
      zero: 'నివేదికలు లేవు',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'యాప్‌లను లోడ్ చేయలేకపోయాం.';

  @override
  String get settingsUnavailable => 'సెట్టింగ్‌లు తెరవలేకపోయాం.';

  @override
  String get consentEyebrow => 'EMPLOYEE INCIDENT REPORTING';

  @override
  String get consentHeadline => 'A clear account.\nA safer next step.';

  @override
  String get consentIntro =>
      'Something felt wrong? Start here.\nDescribe it in your words, then review before sharing.';

  @override
  String get consentWordsTitle => 'Your words, your report';

  @override
  String get consentWordsText =>
      'Description, language, incident type, and optional app and evidence notes.';

  @override
  String get consentChoiceTitle => 'You choose what to share';

  @override
  String get consentChoiceText =>
      'Device checks are optional. Nothing is submitted until you review and confirm.';

  @override
  String get consentStorageTitle => 'Stored locally for this demo';

  @override
  String get consentStorageText =>
      'Drafts stay on this device. Submitted reports go to the local API for administrator review.';

  @override
  String get consentNotice =>
      'Synthetic demonstration only. Do not enter real employee information. No sign-in or production access controls. Microphone audio is not saved, sent or analysed.';

  @override
  String get consentContinue => 'I understand · Continue';

  @override
  String get describeIncident => 'घटना का विवरण दें';

  @override
  String get whatHappened => 'What happened?';

  @override
  String get reviewReport => 'Review report';

  @override
  String get reviewBeforeSending => 'Review before sending';

  @override
  String get reviewFactsDescription =>
      'These are the exact report facts to be sent. The API adds a ticket ID, timestamps and initial status.';

  @override
  String get reviewConfirmationIncluded =>
      'Submission includes your explicit confirmation: true.';

  @override
  String get reviewConfirmFacts =>
      'I confirm these facts and want to create this ticket.';

  @override
  String get submitting => 'సమర్పಿಸುತ್ತಿದೆ…';

  @override
  String get confirmAndSubmit => 'Confirm and submit';

  @override
  String get backDraftPreserved => 'Back · draft preserved';

  @override
  String get backToEdit => 'Back to edit';

  @override
  String get syntheticExample =>
      'Use synthetic details only. Example: an unexpected IT-support caller asked you to install a remote-access app or share a code.';

  @override
  String get pendingSubmission =>
      'A submission may already have reached the API. Retry the preserved reviewed report to retrieve its ticket safely. Editing is paused until this is resolved.';

  @override
  String get appNameOptional => 'యాప్ పేరు (ఐచ్ఛికం)';

  @override
  String get evidenceNotesOptional => 'సాక్ష్య గమనికలు (ఐచ్ఛికం)';

  @override
  String get descriptionTooShort => 'కనీసం 10 అక్షరాలలో సంఘటనను వివరించండి.';

  @override
  String get reportLanguageLabel => 'నివేదిక భాష';

  @override
  String get englishLanguage => 'ఆంగ్లం';

  @override
  String get hindiLanguage => 'హిందీ';

  @override
  String get mixedLanguage => 'మిశ్రమ ఆంగ్లం / హిందీ';

  @override
  String get incidentTypeLabel => 'సంఘటన రకం';

  @override
  String get supportCall => 'మద్దతు కాల్';

  @override
  String get suspiciousMessage => 'అనుమానాస్పద సందేశం';

  @override
  String get mistakenReport => 'పొరపాటు నివేదిక';

  @override
  String get otherIncident => 'ఇతర';

  @override
  String get optionalDeviceReview => 'ఐచ్ఛిక పరికర సమీక్ష';

  @override
  String get androidDeviceReview =>
      'మీ సమ్మతితో, ఆండ్రాయిడ్ సురక్షిత స్క్రీన్ లాక్‌ని నివేదిస్తుందో లేదో తనిఖీ చేయండి.';

  @override
  String get iosDeviceReview =>
      'ఈ దశలో iOS లో ఆటోమేటిక్ పరికర తనిఖీలు అందుబాటులో లేవు.';

  @override
  String get allowOneCheck => 'ఈ ఒక్క తనిఖీని అనుమతించాలా?';

  @override
  String get checkExplanation =>
      'ఇப்போது സുരക്ഷിത സ്ക്രീൻ-ലോക്ക് കോൺഫിഗറേഷൻ വായിക്കുക.';

  @override
  String get cancelAction => 'రద్దు చేయి';

  @override
  String get checkAndInclude => 'తనిఖీ చేసి చేర్చు';

  @override
  String get checking => 'తనిఖీ చేస్తోంది…';

  @override
  String get reviewDeviceCheck => 'పరికర తనిఖీని సమీక్షించి సమ్మతి తెలపండి';

  @override
  String get removeObservation => 'పరికర పరిశీలనను తొలగించు';

  @override
  String get detailTitle => 'నివేదిక వివరాలు';

  @override
  String get ticketDetails => 'టికెట్ వివరాలు';

  @override
  String get refreshStatus => 'స్థితిని నవీకరించండి';

  @override
  String get latestUpdate => 'తాజా సమాచారం';

  @override
  String get statusLabel => 'స్థితి';

  @override
  String get statusSubmitted => 'సమర్పించబడింది';

  @override
  String get statusInReview => 'సమీక్షలో ఉంది';

  @override
  String get statusAwaitingEmployee => 'ఉద్యోగి స్పందన కోసం వేచి ఉంది';

  @override
  String get statusEscalated => 'ఉన్నత సమీక్షకు పంపబడింది';

  @override
  String get statusClosed => 'మూసివేయబడింది';

  @override
  String get submittedAt => 'సమర్పించబడింది';

  @override
  String get updatedAt => 'నవీకరించబడింది';

  @override
  String get timesInUtc => 'సమయాలు UTCలో చూపబడతాయి.';

  @override
  String get helpTitle => 'సహాయం, గోప్యత మరియు సెట్టింగ్‌లు';

  @override
  String get stayInControl => 'నియంత్రణ మీ చేతుల్లోనే ఉంటుంది.';

  @override
  String get helpIntro =>
      'ఏది పంచబడుతుంది, ఏది నిల్వ చేయబడుతుంది, ఈ దశలో ఏమి తనిఖీ చేయవచ్చో తెలుసుకోండి.';

  @override
  String get reportExplained => 'మీ నివేదిక గురించి';

  @override
  String get demoConnection => 'ప్రదర్శన కనెక్షన్';

  @override
  String get openAppSettings => 'ఈ యాప్ సెట్టింగ్‌లను తెరవండి';

  @override
  String get stepDescribe => 'వివరించు';

  @override
  String get stepReview => 'సమీక్షించు';

  @override
  String get stepSubmit => 'సమర్పించు';

  @override
  String get submittedStatements => 'సమర్పించిన ప్రకటనలు';

  @override
  String get employeeReported => 'ఉద్యోగి నివేదించారు';

  @override
  String get descriptionLabel => 'వివరణ';

  @override
  String get appNameLabel => 'యాప్ పేరు';

  @override
  String get evidenceNotesLabel => 'సాక్ష్య గమనికలు';

  @override
  String get notSupplied => 'అందించబడలేదు';

  @override
  String get demoEmployeeIdentity => 'ఉద్యోగి గుర్తింపు: demo-employee';

  @override
  String get optionalChecks => 'ఐచ్ఛిక తనిఖీలు';

  @override
  String get deviceObserved => 'పరికర పరిశీలన';

  @override
  String get noDeviceFacts => 'పరికర వాస్తవాలు ఏవీ చేర్చబడలేదు.';

  @override
  String get secureScreenLock => 'సురక్షిత స్క్రీన్ లాక్';

  @override
  String get configured => 'కాన్ఫిగర్ చేయబడింది';

  @override
  String get notConfigured => 'కాన్ఫిగర్ చేయబడలేదు';

  @override
  String get publicApiClientReported =>
      'ఆండ్రాయిడ్ పబ్లిక్ API · క్లయింట్ నివేదించింది';

  @override
  String get checkedAt => 'తనిఖీ చేసిన సమయం';

  @override
  String get observationDisclaimer =>
      'ఈ పరిశీలనలు రిమోట్ యాక్సెస్, భద్రతా ఉల్లంఘన లేదా అనుమతి භාවිතాన్ని ధృవీకరించవు.';

  @override
  String get helpStorage =>
      'సింథటిక్ డెమో డేటా మాత్రమే. డ్రాఫ్ట్‌లు స్థానికంగా గుప్తీకరణ లేకుండా నిల్వ చేయబడతాయి. సమర్పించిన నివేదికలు స్థానిక API ద్వారా SQLite లో నిల్వ చేయబడతాయి. నిర్వాహక గమనికలు నిర్వాహక వీక్షణలోనే ఉంటాయి.';

  @override
  String get helpSettings =>
      'సెట్టింగ్‌లను తెరవడం వల్ల ఏ సెట్టింగ్‌లు మారవు. ఆండ్రాయిడ్ మరియు iOS లో మీరు ఈ యాప్ సెట్టింగ్‌లను సమీక్షించవచ్చు.';

  @override
  String get helpRoles =>
      'ఈ డెమోలో భద్రత మరియు డేటా రక్షణ వేర్వేరు సమీక్షకుల పాత్రలు.';

  @override
  String get settingsOpenError => 'సెట్టింగ్‌లను తెరవడం విఫలమైంది.';

  @override
  String get apiAddressLabel => 'API చిరునామా';

  @override
  String get apiBuildHint =>
      'బిల్డ్ లేదా రన్ చేస్తున్నప్పుడు API_BASE_URL ని సెట్ చేయండి.';

  @override
  String get voiceWelcome => 'మాట్లాడుకుందాం.';

  @override
  String get voiceWelcomeHint =>
      'ఏం జరిగిందో చెప్పండి. మాట్లాడవచ్చు లేదా టైప్ చేయవచ్చు.';

  @override
  String get voiceAssistant => 'అనువాచ్ సహాయకుడు';

  @override
  String get voiceYou => 'మీరు';

  @override
  String get voiceReady => 'వినడానికి సిద్ధం';

  @override
  String get voiceConnecting => 'కనెక్ట్ అవుతోంది…';

  @override
  String get voiceListening => 'వింటోంది';

  @override
  String get voiceThinking => 'ఆలోచిస్తోంది…';

  @override
  String get voiceSpeaking => 'మాట్లాడుతోంది';

  @override
  String get voiceEnding => 'ముగిస్తోంది…';

  @override
  String get voiceUnavailable => 'వాయిస్ అందుబాటులో లేదు. మీరు టైప్ చేయవచ్చు.';

  @override
  String get voicePartial => 'ప్రత్యక్ష లిప్యంతరీకరణ';

  @override
  String get voiceCorrect => 'లిప్యంతరీకరణను సరిచేయండి';

  @override
  String get voiceUse => 'నివేదికలో చేర్చండి';

  @override
  String get voiceDraft => 'నివేదిక ముసాయిదాను చూడండి';

  @override
  String get voiceStart => 'వాయిస్ ప్రారంభించండి';

  @override
  String get voiceEnd => 'వాయిస్ ఆపండి';

  @override
  String get voiceApply => 'సవరణను వర్తింపజేయండి';

  @override
  String get voiceType => 'సందేశాన్ని టైప్ చేయండి';

  @override
  String get noReports => 'ఇంకా నివేదికలు లేవు';

  @override
  String get reportHistoryHint =>
      'సమర్పించిన టికెట్లు, వాటి తాజా స్థితి ఇక్కడ కనిపిస్తాయి.';

  @override
  String get refreshReports => 'నివేదికలను నవీకరించండి';

  @override
  String get tryAgain => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get showReports => 'నివేదికలు చూపించు';

  @override
  String get callPrompt =>
      'నాకు ఫోన్ చేసిన వ్యక్తి తనను ఇలా పరిచయం చేసుకున్నారు';

  @override
  String get messagePrompt => 'నాకు వచ్చిన సందేశం ఇలా చేయమని కోరింది';

  @override
  String get voiceLogoStart => 'అనువాచ్ లోగోతో వాయిస్ ప్రారంభించండి';

  @override
  String get accessOverview => 'యాప్ యాక్సెస్ అవలోకనం';

  @override
  String get accessBriefing => 'Gemini · ప్రాప్యత సారాంశం';

  @override
  String get accessBriefingUnavailable =>
      'Gemini సారాంశం ఇక్కడ అందుబాటులో లేదు. యాప్‌లు, సెట్టింగ్‌లను పరికరంలో చూడవచ్చు.';

  @override
  String get voiceStartupNotice =>
      'కృత్రిమ వివరాలను మాత్రమే ఉపయోగించండి. Android లో మైక్రోఫోన్ అనుమతి ఉంటే యాప్ తెరవగానే వాయిస్ ప్రారంభమవుతుంది. మీరు వాయిస్ ఆపే వరకు లేదా చెక్ నుంచి బయటకు వెళ్లే వరకు మైక్రోఫోన్ ఆడియో రిపోర్టింగ్ సహాయకుడికి వెళ్తుంది.';

  @override
  String get chats => 'చాట్‌లు';

  @override
  String get newChat => 'కొత్త చాట్';

  @override
  String get reportsOverview => 'నివేదికల అవలోకనం';

  @override
  String get reportCountsUnavailable => 'నివేదికల సంఖ్య అందుబాటులో లేదు.';

  @override
  String get scamTips => 'మోసాల నివారణ చిట్కాలు';

  @override
  String get protectCodes =>
      'OTP, PIN గోప్యంగా ఉంచండి. కోడ్ అడిగితే కాల్ ముగించి సంస్థను నేరుగా సంప్రదించండి.';

  @override
  String get verifyRequests =>
      'వెంటనే చర్య తీసుకోమని లేదా లింక్ తెరవమని సందేశం చెబితే సంస్థ అధికారిక యాప్ లేదా వెబ్‌సైట్‌లో ధృవీకరించండి.';

  @override
  String get reportFraudPrompt =>
      'భారతదేశంలో ఆర్థిక సైబర్ మోసం జరిగితే వెంటనే 1930కి కాల్ చేయండి లేదా అధికారిక పోర్టల్‌లో నివేదించండి.';

  @override
  String get descriptionTranslation => 'వివరణను అనువదించండి';

  @override
  String get descriptionTranslationUnavailable =>
      'అనువాదం అందుబాటులో లేదు. అసలు వివరణ కింద ఉంది.';

  @override
  String get launcherApps => 'కనిపించే యాప్‌లు';

  @override
  String get nonLauncherApps => 'కనిపించని యాప్‌లు';

  @override
  String get appInventoryCoverage =>
      'Android చూపించే యాప్‌లు మాత్రమే జాబితాలో ఉంటాయి. ఐకాన్ లేకపోవడం లేదా అనుమతి ఉండటం దుర్వినియోగానికి రుజువు కాదు.';

  @override
  String get openAccessibilitySettings =>
      'Android ప్రాప్యత సెట్టింగ్‌లను తెరవండి';

  @override
  String get systemApps => 'సిస్టమ్ యాప్‌లు';

  @override
  String get uncategorizedApps => 'వర్గీకరించని యాప్‌లు';

  @override
  String get noMatchingApps => 'సరిపోలే యాప్‌లు లేవు.';

  @override
  String get otherPermissions => 'ఇతర అనుమతులు';
}
