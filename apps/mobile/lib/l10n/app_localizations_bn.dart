// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get unknown => 'অজানা';

  @override
  String get check => 'পরীক্ষা';

  @override
  String get reports => 'রিপোর্ট';

  @override
  String get apps => 'অ্যাক্সেস';

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get theme => 'চেহারা';

  @override
  String get system => 'সিস্টেম';

  @override
  String get light => 'হালকা';

  @override
  String get dark => 'গাঢ়';

  @override
  String get message => 'বার্তা';

  @override
  String get send => 'পাঠান';

  @override
  String get start => 'মাইক্রোফোন চালু করুন';

  @override
  String get stop => 'মাইক্রোফোন বন্ধ করুন';

  @override
  String get local => 'মাইক্রোফোন চালু · অডিও সংরক্ষণ বা পাঠানো হয় না';

  @override
  String get soon => 'AI কথোপকথন পরে আসছে';

  @override
  String get scan => 'অ্যাপ পর্যালোচনা';

  @override
  String get search => 'অ্যাপ খুঁজুন';

  @override
  String get permissions => 'অনুমতি';

  @override
  String get granted => 'অনুমোদিত';

  @override
  String get notGranted => 'অনুমোদিত নয়';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get unavailable => 'iOS-এ উপলব্ধ নয়';

  @override
  String get micDenied => 'মাইক্রোফোনের অনুমতি দেওয়া হয়নি।';

  @override
  String get micUnavailable => 'মাইক্রোফোন উপলব্ধ নয়।';

  @override
  String get iosGuide => 'iOS সেটিংসে অনুমতি দেখুন।';

  @override
  String get visibilityNote =>
      'শুধু দৃশ্যমান লঞ্চার অ্যাপ · অনুমতি ব্যবহার প্রমাণ করে না।';

  @override
  String welcomeName(String name) {
    return 'নমস্কার, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিপোর্ট',
      one: '১টি রিপোর্ট',
      zero: 'কোনো রিপোর্ট নেই',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'অ্যাপ লোড করা যায়নি।';

  @override
  String get settingsUnavailable => 'সেটিংস খোলা যায়নি।';

  @override
  String get consentEyebrow => 'গোপনীয়তা ও সম্মতি';

  @override
  String get consentHeadline => 'রিপোর্ট করার আগে পর্যালোচনা করুন';

  @override
  String get consentIntro =>
      'আপনার রিপোর্ট কর্মী সুরক্ষা দলের কাছে পৌঁছাবে। কী শেয়ার করা হচ্ছে তা দেখে নিন।';

  @override
  String get consentWordsTitle => 'আপনার বক্তব্য';

  @override
  String get consentWordsText =>
      'আপনার প্রদত্ত বিবরণ এবং প্রমাণ নোট শেয়ার করা হবে।';

  @override
  String get consentChoiceTitle => 'আপনার পছন্দ';

  @override
  String get consentChoiceText =>
      'ডিভাইস পরীক্ষা ঐচ্ছিক এবং আপনার অনুমতি পেলেই অন্তর্ভুক্ত করা হয়।';

  @override
  String get consentStorageTitle => 'সুরক্ষিত সঞ্চয়স্থান';

  @override
  String get consentStorageText =>
      'রিপোর্ট এনক্রিপ্ট করা হয় এবং শুধুমাত্র অভ্যন্তরীণভাবে ব্যবহৃত হয়।';

  @override
  String get consentNotice =>
      'জমা দেওয়ার মাধ্যমে, আপনি নীতি উদ্ধৃতি এবং রিপোর্টিং নির্দেশিকা মেনে নিচ্ছেন।';

  @override
  String get consentContinue => 'চালিয়ে যান';

  @override
  String get describeIncident => 'ঘটনার বিবরণ দিন';

  @override
  String get whatHappened => 'কী ঘটেছিল?';

  @override
  String get reviewReport => 'রিপোর্ট পর্যালোচনা করুন';

  @override
  String get reviewBeforeSending => 'পাঠানোর আগে পর্যালোচনা করুন';

  @override
  String get reviewFactsDescription =>
      'আপনার প্রবেশ করানো বিবরণ এবং ঐচ্ছিক পরীক্ষা নিচে তালিকাভুক্ত করা হয়েছে।';

  @override
  String get reviewConfirmationIncluded => 'নিশ্চিতকরণ অন্তর্ভুক্ত রয়েছে';

  @override
  String get reviewConfirmFacts =>
      'আমি এই তথ্য পর্যালোচনা করেছি এবং নিশ্চিত করছি।';

  @override
  String get submitting => 'জমা দেওয়া হচ্ছে…';

  @override
  String get confirmAndSubmit => 'নিশ্চিত করুন এবং জমা দিন';

  @override
  String get backDraftPreserved => 'খসড়া সংরক্ষিত আছে';

  @override
  String get backToEdit => 'সম্পাদনায় ফিরে যান';

  @override
  String get syntheticExample => 'সিন্থেটিক প্রদর্শনী উদাহরণ';

  @override
  String get pendingSubmission => 'জমা দেওয়া বাকি আছে';

  @override
  String get appNameOptional => 'অ্যাপের নাম (ঐচ্ছিক)';

  @override
  String get evidenceNotesOptional => 'প্রমাণ নোট (ঐচ্ছিক)';

  @override
  String get descriptionTooShort => 'বিবরণটি খুব সংক্ষিপ্ত।';

  @override
  String get reportLanguageLabel => 'রিপোর্টের ভাষা';

  @override
  String get englishLanguage => 'ইংরেজি';

  @override
  String get hindiLanguage => 'হিন্দি';

  @override
  String get mixedLanguage => 'মিশ্র ভাষা';

  @override
  String get incidentTypeLabel => 'ঘটনার ধরন';

  @override
  String get supportCall => 'সাপোর্ট কল';

  @override
  String get suspiciousMessage => 'সন্দেহজনক বার্তা';

  @override
  String get mistakenReport => 'ভুলবশত রিপোর্ট';

  @override
  String get otherIncident => 'অন্যান্য ঘটনা';

  @override
  String get optionalDeviceReview => 'ঐচ্ছিক ডিভাইস পর্যালোচনা';

  @override
  String get androidDeviceReview => 'Android ডিভাইস পর্যালোচনা';

  @override
  String get iosDeviceReview => 'iOS ডিভাইস পর্যালোচনা';

  @override
  String get allowOneCheck => 'একটি পরীক্ষা করার অনুমতি দিন';

  @override
  String get checkExplanation =>
      'ডিভাইসের সুরক্ষা অবস্থা যাচাই করার অনুমতি দিন।';

  @override
  String get cancelAction => 'বাতিল করুন';

  @override
  String get checkAndInclude => 'পরীক্ষা করুন এবং অন্তর্ভুক্ত করুন';

  @override
  String get checking => 'পরীক্ষা করা হচ্ছে…';

  @override
  String get reviewDeviceCheck => 'ডিভাইস পরীক্ষা পর্যালোচনা';

  @override
  String get removeObservation => 'পর্যবেক্ষণ সরান';

  @override
  String get detailTitle => 'রিপোর্টের বিবরণ';

  @override
  String get ticketDetails => 'টিকিটের বিবরণ';

  @override
  String get refreshStatus => 'স্ট্যাটাস রিফ্রেশ করুন';

  @override
  String get latestUpdate => 'সর্বশেষ আপডেট';

  @override
  String get statusLabel => 'স্ট্যাটাস';

  @override
  String get statusSubmitted => 'জমা দেওয়া হয়েছে';

  @override
  String get statusInReview => 'পর্যালোচনাধীন';

  @override
  String get statusAwaitingEmployee => 'কর্মীর প্রতিক্রিয়ার জন্য প্রতীক্ষারত';

  @override
  String get statusEscalated => 'উচ্চতর পর্যালোচনায় পাঠানো হয়েছে';

  @override
  String get statusClosed => 'বন্ধ করা হয়েছে';

  @override
  String get submittedAt => 'জমা দেওয়ার সময়';

  @override
  String get updatedAt => 'আপডেটের সময়';

  @override
  String get timesInUtc => 'সময় UTC ফরম্যাটে দেখানো হয়েছে।';

  @override
  String get helpTitle => 'সহায়তা, গোপনীয়তা এবং সেটিংস';

  @override
  String get stayInControl => 'নিয়ন্ত্রণ আপনার হাতে।';

  @override
  String get helpIntro =>
      'কী শেয়ার করা হয়, কী সংরক্ষিত হয় এবং এই পর্যায়ে কী পর্যালোচনা করা যায় তা জানুন।';

  @override
  String get reportExplained => 'আপনার রিপোর্টের ব্যাখ্যা';

  @override
  String get demoConnection => 'ডেমো সংযোগ';

  @override
  String get openAppSettings => 'এই অ্যাপের সেটিংস খুলুন';

  @override
  String get stepDescribe => 'বিবরণ';

  @override
  String get stepReview => 'পর্যালোচনা';

  @override
  String get stepSubmit => 'জমা দিন';

  @override
  String get submittedStatements => 'জমা দেওয়া বক্তব্য';

  @override
  String get employeeReported => 'কর্মী দ্বারা রিপোর্ট করা';

  @override
  String get descriptionLabel => 'বিবরণ';

  @override
  String get appNameLabel => 'অ্যাপের নাম';

  @override
  String get evidenceNotesLabel => 'প্রমাণ নোট';

  @override
  String get notSupplied => 'প্রদান করা হয়নি';

  @override
  String get demoEmployeeIdentity => 'ডেমো কর্মীর পরিচয়';

  @override
  String get optionalChecks => 'ঐচ্ছিক পরীক্ষা';

  @override
  String get deviceObserved => 'ডিভাইস পর্যবেক্ষণ';

  @override
  String get noDeviceFacts => 'কোনো ডিভাইস তথ্য উপলব্ধ নেই।';

  @override
  String get secureScreenLock => 'সুরক্ষিত স্ক্রিন লক';

  @override
  String get configured => 'কনফিগার করা আছে';

  @override
  String get notConfigured => 'কনফিগার করা নেই';

  @override
  String get publicApiClientReported => 'পাবলিক API ক্লায়েন্ট রিপোর্ট করেছে';

  @override
  String get checkedAt => 'পরীক্ষার সময়';

  @override
  String get observationDisclaimer =>
      'পর্যবেক্ষণগুলি শুধুমাত্র ডিভাইসের সুরক্ষা অবস্থা নির্দেশ করে।';

  @override
  String get helpStorage => 'সঞ্চয়স্থান ও গোপনীয়তা';

  @override
  String get helpSettings => 'সেটিংস ও নিয়ন্ত্রণ';

  @override
  String get helpRoles => 'ভূমিকা ও দায়িত্ব';

  @override
  String get settingsOpenError => 'সেটিংস খোলা যায়নি।';

  @override
  String get apiAddressLabel => 'API ঠিকানা';

  @override
  String get apiBuildHint => 'বিল্ড সংস্করণ এবং API তথ্য';
}
