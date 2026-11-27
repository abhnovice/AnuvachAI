// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get unknown => 'نامعلوم';

  @override
  String get check => 'جانچ';

  @override
  String get reports => 'رپورٹس';

  @override
  String get apps => 'رسائی';

  @override
  String get settings => 'ترتیبات';

  @override
  String get language => 'زبان';

  @override
  String get theme => 'ظاہری شکل';

  @override
  String get system => 'سسٹم';

  @override
  String get light => 'ہلکا';

  @override
  String get dark => 'گہرا';

  @override
  String get message => 'پیغام';

  @override
  String get send => 'بھیجیں';

  @override
  String get start => 'مائیکروفون شروع کریں';

  @override
  String get stop => 'مائیکروفون بند کریں';

  @override
  String get local => 'مائیکروفون آن · آڈیو محفوظ یا ارسال نہیں ہوتی';

  @override
  String get soon => 'AI گفتگو بعد میں آئے گی';

  @override
  String get scan => 'ایپس کا جائزہ';

  @override
  String get search => 'ایپس تلاش کریں';

  @override
  String get permissions => 'اجازتیں';

  @override
  String get granted => 'منظور';

  @override
  String get notGranted => 'منظور نہیں';

  @override
  String get openSettings => 'ترتیبات کھولیں';

  @override
  String get unavailable => 'iOS پر دستیاب نہیں';

  @override
  String get micDenied => 'مائیکروفون کی اجازت نہیں دی گئی۔';

  @override
  String get micUnavailable => 'مائیکروفون دستیاب نہیں۔';

  @override
  String get iosGuide => 'iOS ترتیبات میں اجازتیں دیکھیں۔';

  @override
  String get visibilityNote =>
      'صرف نظر آنے والی لانچر ایپس · اجازت استعمال کا ثبوت نہیں۔';

  @override
  String welcomeName(String name) {
    return 'سلام، $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رپورٹس',
      one: '1 رپورٹ',
      zero: 'کوئی رپورٹ نہیں',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'ایپس لوڈ نہیں ہو سکیں۔';

  @override
  String get settingsUnavailable => 'ترتیبات نہیں کھل سکیں۔';

  @override
  String get consentEyebrow => 'رازداری اور رضامندی';

  @override
  String get consentHeadline => 'رپورٹ کرنے سے پہلے جائزہ لیں';

  @override
  String get consentIntro =>
      'آپ کی رپورٹ ملازمین کی سیکیورٹی ٹیم کو پہنچے گی۔ جائزہ لیں کہ کیا شیئر کیا جا رہا ہے۔';

  @override
  String get consentWordsTitle => 'آپ کے الفاظ';

  @override
  String get consentWordsText =>
      'آپ کی فراہم کردہ تفصیل اور شواہد کے نوٹس شیئر کیے جائیں گے۔';

  @override
  String get consentChoiceTitle => 'آپ کے اختیارات';

  @override
  String get consentChoiceText =>
      'ڈیوائس کی جانچ اختیاری ہے اور صرف آپ کی اجازت سے شامل کی جاتی ہے۔';

  @override
  String get consentStorageTitle => 'محفوظ اسٹوریج';

  @override
  String get consentStorageText =>
      'رپورٹس کو انکرپٹ کیا جاتا ہے اور صرف اندرونی طور پر استعمال کیا جاتا ہے۔';

  @override
  String get consentNotice =>
      'ارسال کر کے، آپ پالیسی اور رپورٹنگ کے رہنما اصولوں سے اتفاق کرتے ہیں۔';

  @override
  String get consentContinue => 'جاری رکھیں';

  @override
  String get describeIncident => 'واقعے کی تفصیل بتائیں';

  @override
  String get whatHappened => 'کیا ہوا تھا؟';

  @override
  String get reviewReport => 'رپورٹ کا جائزہ لیں';

  @override
  String get reviewBeforeSending => 'ارسال کرنے سے پہلے جائزہ لیں';

  @override
  String get reviewFactsDescription =>
      'آپ کی درج کردہ تفصیلات اور اختیاری جانچ نیچے درج ہیں۔';

  @override
  String get reviewConfirmationIncluded => 'تصدیق شامل ہے';

  @override
  String get reviewConfirmFacts =>
      'میں نے ان معلومات کا جائزہ لیا ہے اور تصدیق کرتا ہوں۔';

  @override
  String get submitting => 'ارسال ہو رہا ہے…';

  @override
  String get confirmAndSubmit => 'تصدیق کریں اور ارسال کریں';

  @override
  String get backDraftPreserved => 'ڈرافٹ محفوظ ہے';

  @override
  String get backToEdit => 'ترمیم پر واپس جائیں';

  @override
  String get syntheticExample => 'مصنوعی ڈیمو مثال';

  @override
  String get pendingSubmission => 'ارسال زیر التواء';

  @override
  String get appNameOptional => 'ایپ کا نام (اختیاری)';

  @override
  String get evidenceNotesOptional => 'شواہد کے نوٹس (اختیاری)';

  @override
  String get descriptionTooShort => 'تفصیل بہت مختصر ہے۔';

  @override
  String get reportLanguageLabel => 'رپورٹ کی زبان';

  @override
  String get englishLanguage => 'انگریزی';

  @override
  String get hindiLanguage => 'ہندی';

  @override
  String get mixedLanguage => 'مخلوط زبان';

  @override
  String get incidentTypeLabel => 'واقعے کی نوعیت';

  @override
  String get supportCall => 'سپورٹ کال';

  @override
  String get suspiciousMessage => 'مشکوک پیغام';

  @override
  String get mistakenReport => 'غلطی سے بھیجی گئی رپورٹ';

  @override
  String get otherIncident => 'دیگر واقعہ';

  @override
  String get optionalDeviceReview => 'اختیاری ڈیوائس کا جائزہ';

  @override
  String get androidDeviceReview => 'Android ڈیوائس کا جائزہ';

  @override
  String get iosDeviceReview => 'iOS ڈیوائس کا جائزہ';

  @override
  String get allowOneCheck => 'ایک جانچ کی اجازت دیں';

  @override
  String get checkExplanation =>
      'ڈیوائس کی سیکیورٹی حیثیت کی جانچ کی اجازت دیں۔';

  @override
  String get cancelAction => 'منسوخ کریں';

  @override
  String get checkAndInclude => 'جانچیں اور شامل کریں';

  @override
  String get checking => 'جانچ ہو رہی ہے…';

  @override
  String get reviewDeviceCheck => 'ڈیوائس جانچ کا جائزہ';

  @override
  String get removeObservation => 'ہٹائیں';

  @override
  String get detailTitle => 'رپورٹ کی تفصیلات';

  @override
  String get ticketDetails => 'ٹکٹ کی تفصیلات';

  @override
  String get refreshStatus => 'حیثیت تازہ کریں';

  @override
  String get latestUpdate => 'تازہ ترین معلومات';

  @override
  String get statusLabel => 'حیثیت';

  @override
  String get statusSubmitted => 'ارسال کر دیا گیا';

  @override
  String get statusInReview => 'زیر جائزہ';

  @override
  String get statusAwaitingEmployee => 'ملازم کے جواب کا انتظار ہے';

  @override
  String get statusEscalated => 'اعلیٰ جائزے کے لیے منتقل';

  @override
  String get statusClosed => 'بند';

  @override
  String get submittedAt => 'ارسال کا وقت';

  @override
  String get updatedAt => 'تازہ کاری کا وقت';

  @override
  String get timesInUtc => 'اوقات UTC فارمیٹ میں ہیں۔';

  @override
  String get helpTitle => 'مدد، رازداری اور ترتیبات';

  @override
  String get stayInControl => 'اختیار آپ کے ہاتھ میں ہے۔';

  @override
  String get helpIntro =>
      'جانیں کہ کیا شیئر کیا جاتا ہے، کیا محفوظ ہوتا ہے اور اس مرحلے میں کیا چیک کیا جا سکتا ہے۔';

  @override
  String get reportExplained => 'آپ کی رپورٹ کی وضاحت';

  @override
  String get demoConnection => 'ڈیمو کنکشن';

  @override
  String get openAppSettings => 'اس ایپ کی ترتیبات کھولیں';

  @override
  String get stepDescribe => 'تفصیل';

  @override
  String get stepReview => 'جائزہ';

  @override
  String get stepSubmit => 'ارسال';

  @override
  String get submittedStatements => 'ارسال کردہ بیانات';

  @override
  String get employeeReported => 'ملازم کی رپورٹ کردہ';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String get appNameLabel => 'ایپ کا نام';

  @override
  String get evidenceNotesLabel => 'شواہد کے نوٹس';

  @override
  String get notSupplied => 'فراہم نہیں کیا گیا';

  @override
  String get demoEmployeeIdentity => 'ڈیمو ملازم کی شناخت';

  @override
  String get optionalChecks => 'اختیاری جانچ';

  @override
  String get deviceObserved => 'ڈیوائس کے مشاہدات';

  @override
  String get noDeviceFacts => 'ڈیوائس کی کوئی معلومات فراہم نہیں کی گئیں۔';

  @override
  String get secureScreenLock => 'محفوظ اسکرین لاک';

  @override
  String get configured => 'کنفیگر شدہ';

  @override
  String get notConfigured => 'کنفیگر نہیں ہے';

  @override
  String get publicApiClientReported => 'پبلک API کلائنٹ کی رپورٹ';

  @override
  String get checkedAt => 'جانچ کا وقت';

  @override
  String get observationDisclaimer =>
      'مشاہدات صرف ڈیوائس کی سیکیورٹی حیثیت کو ظاہر کرتے ہیں۔';

  @override
  String get helpStorage => 'اسٹوریج اور رازداری';

  @override
  String get helpSettings => 'ترتیبات اور کنٹرولز';

  @override
  String get helpRoles => 'کردار اور ذمہ داریاں';

  @override
  String get settingsOpenError => 'ترتیبات نہیں کھل سکیں۔';

  @override
  String get apiAddressLabel => 'API کا پتہ';

  @override
  String get apiBuildHint => 'بلڈ ورژن اور API معلومات';

  @override
  String get voiceWelcome => 'آئیے بات کریں۔';

  @override
  String get voiceWelcomeHint =>
      'بتائیں کیا ہوا۔ آپ بول سکتے ہیں یا لکھ سکتے ہیں۔';

  @override
  String get voiceAssistant => 'انوواچ معاون';

  @override
  String get voiceYou => 'آپ';

  @override
  String get voiceReady => 'سننے کے لیے تیار';

  @override
  String get voiceConnecting => 'رابطہ ہو رہا ہے…';

  @override
  String get voiceListening => 'سن رہا ہے';

  @override
  String get voiceThinking => 'سوچ رہا ہے…';

  @override
  String get voiceSpeaking => 'بول رہا ہے';

  @override
  String get voiceEnding => 'گفتگو سمیٹ رہا ہے…';

  @override
  String get voiceUnavailable => 'آواز دستیاب نہیں۔ آپ لکھ سکتے ہیں۔';

  @override
  String get voicePartial => 'براہ راست نقل';

  @override
  String get voiceCorrect => 'نقل درست کریں';

  @override
  String get voiceUse => 'رپورٹ میں شامل کریں';

  @override
  String get voiceDraft => 'رپورٹ کا مسودہ دیکھیں';

  @override
  String get voiceStart => 'آواز شروع کریں';

  @override
  String get voiceEnd => 'آواز بند کریں';

  @override
  String get voiceApply => 'درستی لاگو کریں';

  @override
  String get voiceType => 'پیغام لکھیں';
}
