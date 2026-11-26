// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get unknown => 'अज्ञात';

  @override
  String get check => 'जाँच';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get apps => 'ऐप एक्सेस';

  @override
  String get settings => 'सेटिंग';

  @override
  String get language => 'भाषा';

  @override
  String get theme => 'दिखावट';

  @override
  String get system => 'सिस्टम';

  @override
  String get light => 'हल्का';

  @override
  String get dark => 'गहरा';

  @override
  String get message => 'संदेश';

  @override
  String get send => 'भेजें';

  @override
  String get start => 'माइक्रोफ़ोन शुरू करें';

  @override
  String get stop => 'माइक्रोफ़ोन बंद करें';

  @override
  String get local => 'माइक्रोफ़ोन चालू · ऑडियो सहेजा या भेजा नहीं जाता';

  @override
  String get soon => 'AI बातचीत बाद में आएगी';

  @override
  String get scan => 'ऐप देखें';

  @override
  String get search => 'ऐप खोजें';

  @override
  String get permissions => 'अनुमतियाँ';

  @override
  String get granted => 'स्वीकृत';

  @override
  String get notGranted => 'स्वीकृत नहीं';

  @override
  String get openSettings => 'सेटिंग खोलें';

  @override
  String get unavailable => 'iOS पर उपलब्ध नहीं';

  @override
  String get micDenied => 'माइक्रोफ़ोन की अनुमति नहीं मिली।';

  @override
  String get micUnavailable => 'माइक्रोफ़ोन उपलब्ध नहीं है।';

  @override
  String get iosGuide => 'iOS सेटिंग में अनुमतियाँ देखें।';

  @override
  String get visibilityNote =>
      'केवल दिखने वाले लॉन्चर ऐप · अनुमति से उपयोग सिद्ध नहीं होता।';

  @override
  String welcomeName(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट',
      one: '1 रिपोर्ट',
      zero: 'कोई रिपोर्ट नहीं',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'ऐप लोड नहीं हो सके।';

  @override
  String get settingsUnavailable => 'सेटिंग नहीं खुल सकी।';

  @override
  String get consentEyebrow => 'कर्मचारी घटना रिपोर्टिंग';

  @override
  String get consentHeadline => 'स्पष्ट विवरण।\nसुरक्षित अगला कदम।';

  @override
  String get consentIntro =>
      'कुछ गलत लगा? यहाँ शुरू करें।\nअपने शब्दों में बताएँ, फिर साझा करने से पहले समीक्षा करें।';

  @override
  String get consentWordsTitle => 'आपके शब्द, आपकी रिपोर्ट';

  @override
  String get consentWordsText =>
      'विवरण, भाषा, घटना का प्रकार और वैकल्पिक ऐप व साक्ष्य संबंधी टिप्पणियाँ।';

  @override
  String get consentChoiceTitle => 'आप तय करते हैं कि क्या साझा करना है';

  @override
  String get consentChoiceText =>
      'डिवाइस की जाँच वैकल्पिक है। आपकी समीक्षा और पुष्टि से पहले कुछ भी जमा नहीं होता।';

  @override
  String get consentStorageTitle =>
      'इस प्रदर्शन के लिए स्थानीय रूप से संग्रहित';

  @override
  String get consentStorageText =>
      'ड्राफ़्ट इस डिवाइस पर रहते हैं। जमा की गई रिपोर्ट प्रशासक की समीक्षा के लिए स्थानीय API को भेजी जाती हैं।';

  @override
  String get consentNotice =>
      'केवल कृत्रिम डेटा वाले प्रदर्शन के लिए। वास्तविक कर्मचारी जानकारी न डालें। साइन-इन या वास्तविक उपयोग के लिए पहुँच नियंत्रण उपलब्ध नहीं हैं। माइक्रोफ़ोन का ऑडियो सहेजा, भेजा या विश्लेषित नहीं किया जाता।';

  @override
  String get consentContinue => 'मैं समझ गया · आगे बढ़ें';

  @override
  String get describeIncident => 'घटना का विवरण दें';

  @override
  String get whatHappened => 'क्या हुआ?';

  @override
  String get reviewReport => 'रिपोर्ट की समीक्षा करें';

  @override
  String get reviewBeforeSending => 'भेजने से पहले समीक्षा करें';

  @override
  String get reviewFactsDescription =>
      'भेजी जाने वाली रिपोर्ट में यही तथ्य होंगे। API टिकट आईडी, समय और शुरुआती स्थिति जोड़ता है।';

  @override
  String get reviewConfirmationIncluded =>
      'जमा करते समय आपकी स्पष्ट पुष्टि शामिल होती है: true.';

  @override
  String get reviewConfirmFacts =>
      'मैं इन तथ्यों की पुष्टि करता हूँ और यह टिकट बनाना चाहता हूँ।';

  @override
  String get submitting => 'जमा हो रहा है…';

  @override
  String get confirmAndSubmit => 'पुष्टि करके जमा करें';

  @override
  String get backDraftPreserved => 'वापस · ड्राफ़्ट सुरक्षित है';

  @override
  String get backToEdit => 'संपादन के लिए वापस जाएँ';

  @override
  String get syntheticExample =>
      'केवल कृत्रिम विवरण का उपयोग करें। उदाहरण: अनपेक्षित आईटी सहायता कॉल में आपसे रिमोट एक्सेस ऐप इंस्टॉल करने या कोड साझा करने को कहा गया।';

  @override
  String get pendingSubmission =>
      'हो सकता है कि पिछला अनुरोध API तक पहुँच चुका हो। टिकट सुरक्षित रूप से पाने के लिए सुरक्षित रखी गई समीक्षित रिपोर्ट फिर से भेजें। समाधान होने तक संपादन रुका रहेगा।';

  @override
  String get appNameOptional => 'ऐप का नाम (वैकल्पिक)';

  @override
  String get evidenceNotesOptional => 'साक्ष्य संबंधी टिप्पणियाँ (वैकल्पिक)';

  @override
  String get descriptionTooShort =>
      'घटना का विवरण कम से कम 10 अक्षरों में दें।';

  @override
  String get reportLanguageLabel => 'रिपोर्ट की भाषा';

  @override
  String get englishLanguage => 'अंग्रेज़ी';

  @override
  String get hindiLanguage => 'हिन्दी';

  @override
  String get mixedLanguage => 'मिश्रित अंग्रेज़ी / हिन्दी';

  @override
  String get incidentTypeLabel => 'घटना का प्रकार';

  @override
  String get supportCall => 'सहायता कॉल';

  @override
  String get suspiciousMessage => 'संदिग्ध संदेश';

  @override
  String get mistakenReport => 'गलती से की गई रिपोर्ट';

  @override
  String get otherIncident => 'अन्य';

  @override
  String get optionalDeviceReview => 'वैकल्पिक डिवाइस समीक्षा';

  @override
  String get androidDeviceReview =>
      'आपकी सहमति से जाँचें कि Android के अनुसार सुरक्षित स्क्रीन लॉक लगा है या नहीं। इससे इंस्टॉल किए गए रिमोट एक्सेस ऐप या अनुमति के उपयोग की जाँच नहीं होती।';

  @override
  String get iosDeviceReview =>
      'इस चरण में iOS पर स्वचालित डिवाइस जाँच उपलब्ध नहीं है। सेटिंग में इंस्टॉल किए गए ऐप और अनुमतियाँ स्वयं देखें या अपने परिचित सहायता केंद्र से संपर्क करें।';

  @override
  String get allowOneCheck => 'इस एक जाँच की अनुमति दें?';

  @override
  String get checkExplanation =>
      'अभी सुरक्षित स्क्रीन लॉक की सेटिंग पढ़ें और उसका परिणाम व समय रिपोर्ट में शामिल करें। रनटाइम अनुमति की आवश्यकता नहीं है।';

  @override
  String get cancelAction => 'रद्द करें';

  @override
  String get checkAndInclude => 'जाँचकर शामिल करें';

  @override
  String get checking => 'जाँच हो रही है…';

  @override
  String get reviewDeviceCheck => 'डिवाइस जाँच की समीक्षा करें और सहमति दें';

  @override
  String get removeObservation => 'डिवाइस संबंधी अवलोकन हटाएँ';

  @override
  String get detailTitle => 'रिपोर्ट का विवरण';

  @override
  String get ticketDetails => 'टिकट विवरण';

  @override
  String get refreshStatus => 'स्थिति ताज़ा करें';

  @override
  String get latestUpdate => 'नवीनतम जानकारी';

  @override
  String get statusLabel => 'स्थिति';

  @override
  String get statusSubmitted => 'जमा किया गया';

  @override
  String get statusInReview => 'समीक्षाधीन';

  @override
  String get statusAwaitingEmployee => 'कर्मचारी की प्रतीक्षा';

  @override
  String get statusEscalated => 'उच्चतर समीक्षा के लिए भेजा गया';

  @override
  String get statusClosed => 'बंद';

  @override
  String get submittedAt => 'जमा किया गया';

  @override
  String get updatedAt => 'अद्यतन किया गया';

  @override
  String get timesInUtc => 'समय UTC में दिखाया गया है।';

  @override
  String get helpTitle => 'सहायता, गोपनीयता और सेटिंग';

  @override
  String get stayInControl => 'नियंत्रण आपके हाथ में है।';

  @override
  String get helpIntro =>
      'जानें कि क्या साझा और संग्रहित होता है तथा इस चरण में क्या जाँचा जा सकता है।';

  @override
  String get reportExplained => 'आपकी रिपोर्ट की जानकारी';

  @override
  String get demoConnection => 'प्रदर्शन कनेक्शन';

  @override
  String get openAppSettings => 'इस ऐप की सेटिंग खोलें';

  @override
  String get stepDescribe => 'विवरण दें';

  @override
  String get stepReview => 'समीक्षा करें';

  @override
  String get stepSubmit => 'जमा करें';

  @override
  String get submittedStatements => 'जमा किए गए बयान';

  @override
  String get employeeReported => 'कर्मचारी द्वारा बताए गए तथ्य';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get appNameLabel => 'ऐप का नाम';

  @override
  String get evidenceNotesLabel => 'साक्ष्य संबंधी टिप्पणियाँ';

  @override
  String get notSupplied => 'नहीं दिया गया';

  @override
  String get demoEmployeeIdentity => 'कर्मचारी पहचान: demo-employee';

  @override
  String get optionalChecks => 'वैकल्पिक जाँच';

  @override
  String get deviceObserved => 'डिवाइस से प्राप्त अवलोकन';

  @override
  String get noDeviceFacts =>
      'डिवाइस से प्राप्त कोई स्वचालित तथ्य शामिल नहीं है।';

  @override
  String get secureScreenLock => 'सुरक्षित स्क्रीन लॉक';

  @override
  String get configured => 'सेट है';

  @override
  String get notConfigured => 'सेट नहीं है';

  @override
  String get publicApiClientReported =>
      'Android सार्वजनिक API · क्लाइंट द्वारा बताया गया';

  @override
  String get checkedAt => 'जाँच का समय';

  @override
  String get observationDisclaimer =>
      'इन अवलोकनों से रिमोट एक्सेस, सुरक्षा भंग होने या किसी अनुमति के इस्तेमाल की पुष्टि नहीं होती।';

  @override
  String get helpStorage =>
      'केवल कृत्रिम डेटा का उपयोग करें। ड्राफ़्ट ऐप की प्राथमिकताओं में स्थानीय रूप से बिना एन्क्रिप्शन के संग्रहित होते हैं। जमा किए गए तथ्य स्थानीय API द्वारा SQLite में रखे जाते हैं। प्रशासक की टिप्पणियाँ केवल प्रशासक दृश्य में रहती हैं। इस प्रदर्शन में प्रमाणीकरण नहीं है।';

  @override
  String get helpSettings =>
      'सेटिंग खोलने से कोई सेटिंग बदलती नहीं है। Android और iOS पर आप इस ऐप की सेटिंग देख सकते हैं। दूसरे ऐप और उनकी अनुमतियाँ सिस्टम सेटिंग में स्वयं देखें। किसी अनुमति का दिखना उसके इस्तेमाल का प्रमाण नहीं है।';

  @override
  String get helpRoles =>
      'इस प्रदर्शन में सुरक्षा और डेटा संरक्षण अलग-अलग समीक्षक भूमिकाएँ हैं। वास्तविक कर्मचारी डेटा के लिए सर्वर पर लागू पहुँच नियंत्रण और निर्धारित डेटा प्रतिधारण नीति आवश्यक हैं।';

  @override
  String get settingsOpenError =>
      'सेटिंग नहीं खुल सकी। सिस्टम सेटिंग स्वयं खोलें।';

  @override
  String get apiAddressLabel => 'API पता';

  @override
  String get apiBuildHint => 'बिल्ड या रन करते समय API_BASE_URL सेट करें।';
}
