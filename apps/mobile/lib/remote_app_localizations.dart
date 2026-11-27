import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

class RemoteAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const RemoteAppLocalizationsDelegate(this.overrides, this.revision);
  final Map<String, Map<String, String>> overrides;
  final int revision;
  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);
  @override
  Future<AppLocalizations> load(Locale locale) async {
    final base = await AppLocalizations.delegate.load(locale);
    return RemoteAppLocalizations(
      base,
      overrides[locale.languageCode] ?? const {},
    );
  }

  @override
  bool shouldReload(RemoteAppLocalizationsDelegate old) =>
      revision != old.revision;
}

class RemoteAppLocalizations extends AppLocalizations {
  RemoteAppLocalizations(this.base, this.values) : super(base.localeName);
  final AppLocalizations base;
  final Map<String, String> values;
  @override
  String get unknown => values['unknown'] ?? base.unknown;
  @override
  String get check => values['check'] ?? base.check;
  @override
  String get reports => values['reports'] ?? base.reports;
  @override
  String get apps => values['apps'] ?? base.apps;
  @override
  String get settings => values['settings'] ?? base.settings;
  @override
  String get language => values['language'] ?? base.language;
  @override
  String get theme => values['theme'] ?? base.theme;
  @override
  String get system => values['system'] ?? base.system;
  @override
  String get light => values['light'] ?? base.light;
  @override
  String get dark => values['dark'] ?? base.dark;
  @override
  String get message => values['message'] ?? base.message;
  @override
  String get send => values['send'] ?? base.send;
  @override
  String get start => values['start'] ?? base.start;
  @override
  String get stop => values['stop'] ?? base.stop;
  @override
  String get local => values['local'] ?? base.local;
  @override
  String get soon => values['soon'] ?? base.soon;
  @override
  String get scan => values['scan'] ?? base.scan;
  @override
  String get search => values['search'] ?? base.search;
  @override
  String get permissions => values['permissions'] ?? base.permissions;
  @override
  String get granted => values['granted'] ?? base.granted;
  @override
  String get notGranted => values['notGranted'] ?? base.notGranted;
  @override
  String get openSettings => values['openSettings'] ?? base.openSettings;
  @override
  String get unavailable => values['unavailable'] ?? base.unavailable;
  @override
  String get micDenied => values['micDenied'] ?? base.micDenied;
  @override
  String get micUnavailable => values['micUnavailable'] ?? base.micUnavailable;
  @override
  String get iosGuide => values['iosGuide'] ?? base.iosGuide;
  @override
  String get visibilityNote => values['visibilityNote'] ?? base.visibilityNote;
  @override
  String get accessUnavailable =>
      values['accessUnavailable'] ?? base.accessUnavailable;
  @override
  String get settingsUnavailable =>
      values['settingsUnavailable'] ?? base.settingsUnavailable;
  @override
  String get consentEyebrow => values['consentEyebrow'] ?? base.consentEyebrow;
  @override
  String get consentHeadline =>
      values['consentHeadline'] ?? base.consentHeadline;
  @override
  String get consentIntro => values['consentIntro'] ?? base.consentIntro;
  @override
  String get consentWordsTitle =>
      values['consentWordsTitle'] ?? base.consentWordsTitle;
  @override
  String get consentWordsText =>
      values['consentWordsText'] ?? base.consentWordsText;
  @override
  String get consentChoiceTitle =>
      values['consentChoiceTitle'] ?? base.consentChoiceTitle;
  @override
  String get consentChoiceText =>
      values['consentChoiceText'] ?? base.consentChoiceText;
  @override
  String get consentStorageTitle =>
      values['consentStorageTitle'] ?? base.consentStorageTitle;
  @override
  String get consentStorageText =>
      values['consentStorageText'] ?? base.consentStorageText;
  @override
  String get consentNotice => values['consentNotice'] ?? base.consentNotice;
  @override
  String get consentContinue =>
      values['consentContinue'] ?? base.consentContinue;
  @override
  String get describeIncident =>
      values['describeIncident'] ?? base.describeIncident;
  @override
  String get whatHappened => values['whatHappened'] ?? base.whatHappened;
  @override
  String get reviewReport => values['reviewReport'] ?? base.reviewReport;
  @override
  String get reviewBeforeSending =>
      values['reviewBeforeSending'] ?? base.reviewBeforeSending;
  @override
  String get reviewFactsDescription =>
      values['reviewFactsDescription'] ?? base.reviewFactsDescription;
  @override
  String get reviewConfirmationIncluded =>
      values['reviewConfirmationIncluded'] ?? base.reviewConfirmationIncluded;
  @override
  String get reviewConfirmFacts =>
      values['reviewConfirmFacts'] ?? base.reviewConfirmFacts;
  @override
  String get submitting => values['submitting'] ?? base.submitting;
  @override
  String get confirmAndSubmit =>
      values['confirmAndSubmit'] ?? base.confirmAndSubmit;
  @override
  String get backDraftPreserved =>
      values['backDraftPreserved'] ?? base.backDraftPreserved;
  @override
  String get backToEdit => values['backToEdit'] ?? base.backToEdit;
  @override
  String get syntheticExample =>
      values['syntheticExample'] ?? base.syntheticExample;
  @override
  String get pendingSubmission =>
      values['pendingSubmission'] ?? base.pendingSubmission;
  @override
  String get appNameOptional =>
      values['appNameOptional'] ?? base.appNameOptional;
  @override
  String get evidenceNotesOptional =>
      values['evidenceNotesOptional'] ?? base.evidenceNotesOptional;
  @override
  String get descriptionTooShort =>
      values['descriptionTooShort'] ?? base.descriptionTooShort;
  @override
  String get reportLanguageLabel =>
      values['reportLanguageLabel'] ?? base.reportLanguageLabel;
  @override
  String get englishLanguage =>
      values['englishLanguage'] ?? base.englishLanguage;
  @override
  String get hindiLanguage => values['hindiLanguage'] ?? base.hindiLanguage;
  @override
  String get mixedLanguage => values['mixedLanguage'] ?? base.mixedLanguage;
  @override
  String get incidentTypeLabel =>
      values['incidentTypeLabel'] ?? base.incidentTypeLabel;
  @override
  String get supportCall => values['supportCall'] ?? base.supportCall;
  @override
  String get suspiciousMessage =>
      values['suspiciousMessage'] ?? base.suspiciousMessage;
  @override
  String get mistakenReport => values['mistakenReport'] ?? base.mistakenReport;
  @override
  String get otherIncident => values['otherIncident'] ?? base.otherIncident;
  @override
  String get optionalDeviceReview =>
      values['optionalDeviceReview'] ?? base.optionalDeviceReview;
  @override
  String get androidDeviceReview =>
      values['androidDeviceReview'] ?? base.androidDeviceReview;
  @override
  String get iosDeviceReview =>
      values['iosDeviceReview'] ?? base.iosDeviceReview;
  @override
  String get allowOneCheck => values['allowOneCheck'] ?? base.allowOneCheck;
  @override
  String get checkExplanation =>
      values['checkExplanation'] ?? base.checkExplanation;
  @override
  String get cancelAction => values['cancelAction'] ?? base.cancelAction;
  @override
  String get checkAndInclude =>
      values['checkAndInclude'] ?? base.checkAndInclude;
  @override
  String get checking => values['checking'] ?? base.checking;
  @override
  String get reviewDeviceCheck =>
      values['reviewDeviceCheck'] ?? base.reviewDeviceCheck;
  @override
  String get removeObservation =>
      values['removeObservation'] ?? base.removeObservation;
  @override
  String get detailTitle => values['detailTitle'] ?? base.detailTitle;
  @override
  String get ticketDetails => values['ticketDetails'] ?? base.ticketDetails;
  @override
  String get refreshStatus => values['refreshStatus'] ?? base.refreshStatus;
  @override
  String get latestUpdate => values['latestUpdate'] ?? base.latestUpdate;
  @override
  String get statusLabel => values['statusLabel'] ?? base.statusLabel;
  @override
  String get statusSubmitted =>
      values['statusSubmitted'] ?? base.statusSubmitted;
  @override
  String get statusInReview => values['statusInReview'] ?? base.statusInReview;
  @override
  String get statusAwaitingEmployee =>
      values['statusAwaitingEmployee'] ?? base.statusAwaitingEmployee;
  @override
  String get statusEscalated =>
      values['statusEscalated'] ?? base.statusEscalated;
  @override
  String get statusClosed => values['statusClosed'] ?? base.statusClosed;
  @override
  String get submittedAt => values['submittedAt'] ?? base.submittedAt;
  @override
  String get updatedAt => values['updatedAt'] ?? base.updatedAt;
  @override
  String get timesInUtc => values['timesInUtc'] ?? base.timesInUtc;
  @override
  String get helpTitle => values['helpTitle'] ?? base.helpTitle;
  @override
  String get stayInControl => values['stayInControl'] ?? base.stayInControl;
  @override
  String get helpIntro => values['helpIntro'] ?? base.helpIntro;
  @override
  String get reportExplained =>
      values['reportExplained'] ?? base.reportExplained;
  @override
  String get demoConnection => values['demoConnection'] ?? base.demoConnection;
  @override
  String get openAppSettings =>
      values['openAppSettings'] ?? base.openAppSettings;
  @override
  String get stepDescribe => values['stepDescribe'] ?? base.stepDescribe;
  @override
  String get stepReview => values['stepReview'] ?? base.stepReview;
  @override
  String get stepSubmit => values['stepSubmit'] ?? base.stepSubmit;
  @override
  String get submittedStatements =>
      values['submittedStatements'] ?? base.submittedStatements;
  @override
  String get employeeReported =>
      values['employeeReported'] ?? base.employeeReported;
  @override
  String get descriptionLabel =>
      values['descriptionLabel'] ?? base.descriptionLabel;
  @override
  String get appNameLabel => values['appNameLabel'] ?? base.appNameLabel;
  @override
  String get evidenceNotesLabel =>
      values['evidenceNotesLabel'] ?? base.evidenceNotesLabel;
  @override
  String get notSupplied => values['notSupplied'] ?? base.notSupplied;
  @override
  String get demoEmployeeIdentity =>
      values['demoEmployeeIdentity'] ?? base.demoEmployeeIdentity;
  @override
  String get optionalChecks => values['optionalChecks'] ?? base.optionalChecks;
  @override
  String get deviceObserved => values['deviceObserved'] ?? base.deviceObserved;
  @override
  String get noDeviceFacts => values['noDeviceFacts'] ?? base.noDeviceFacts;
  @override
  String get secureScreenLock =>
      values['secureScreenLock'] ?? base.secureScreenLock;
  @override
  String get configured => values['configured'] ?? base.configured;
  @override
  String get notConfigured => values['notConfigured'] ?? base.notConfigured;
  @override
  String get publicApiClientReported =>
      values['publicApiClientReported'] ?? base.publicApiClientReported;
  @override
  String get checkedAt => values['checkedAt'] ?? base.checkedAt;
  @override
  String get observationDisclaimer =>
      values['observationDisclaimer'] ?? base.observationDisclaimer;
  @override
  String get helpStorage => values['helpStorage'] ?? base.helpStorage;
  @override
  String get helpSettings => values['helpSettings'] ?? base.helpSettings;
  @override
  String get helpRoles => values['helpRoles'] ?? base.helpRoles;
  @override
  String get settingsOpenError =>
      values['settingsOpenError'] ?? base.settingsOpenError;
  @override
  String get apiAddressLabel =>
      values['apiAddressLabel'] ?? base.apiAddressLabel;
  @override
  String get apiBuildHint => values['apiBuildHint'] ?? base.apiBuildHint;
  @override
  String welcomeName(String name) {
    final value = values['welcomeName'];
    if (value == null ||
        !value.contains('{name}') ||
        value.replaceAll('{name}', '').contains(RegExp(r'[{}]'))) {
      return base.welcomeName(name);
    }
    return value.replaceAll('{name}', name);
  }

  @override
  String reportCount(int count) {
    final value = values['reportCount'];
    if (value == null) return base.reportCount(count);
    try {
      return _formatPlural(value, count, localeName);
    } on FormatException {
      return base.reportCount(count);
    }
  }

  @override
  String get voiceWelcome => values['voiceWelcome'] ?? base.voiceWelcome;
  @override
  String get voiceWelcomeHint =>
      values['voiceWelcomeHint'] ?? base.voiceWelcomeHint;
  @override
  String get voiceAssistant => values['voiceAssistant'] ?? base.voiceAssistant;
  @override
  String get voiceYou => values['voiceYou'] ?? base.voiceYou;
  @override
  String get voiceReady => values['voiceReady'] ?? base.voiceReady;
  @override
  String get voiceConnecting =>
      values['voiceConnecting'] ?? base.voiceConnecting;
  @override
  String get voiceListening => values['voiceListening'] ?? base.voiceListening;
  @override
  String get voiceThinking => values['voiceThinking'] ?? base.voiceThinking;
  @override
  String get voiceSpeaking => values['voiceSpeaking'] ?? base.voiceSpeaking;
  @override
  String get voiceEnding => values['voiceEnding'] ?? base.voiceEnding;
  @override
  String get voiceUnavailable =>
      values['voiceUnavailable'] ?? base.voiceUnavailable;
  @override
  String get voicePartial => values['voicePartial'] ?? base.voicePartial;
  @override
  String get voiceCorrect => values['voiceCorrect'] ?? base.voiceCorrect;
  @override
  String get voiceUse => values['voiceUse'] ?? base.voiceUse;
  @override
  String get voiceDraft => values['voiceDraft'] ?? base.voiceDraft;
  @override
  String get voiceStart => values['voiceStart'] ?? base.voiceStart;
  @override
  String get voiceEnd => values['voiceEnd'] ?? base.voiceEnd;
  @override
  String get voiceApply => values['voiceApply'] ?? base.voiceApply;
  @override
  String get voiceType => values['voiceType'] ?? base.voiceType;
}

// Supports ICU cardinal plural messages with the count argument, including
// exact-value selectors, standard plural categories, {count}, and #.
// Unsupported ICU syntax is rejected so the compiled message is used.
String _formatPlural(String input, int count, String locale) {
  final header = RegExp(r'^\s*\{count\s*,\s*plural\s*,').firstMatch(input);
  if (header == null) throw const FormatException();
  var pos = header.end;
  final forms = <String, String>{};
  while (true) {
    while (pos < input.length && input[pos].trim().isEmpty) {
      pos++;
    }
    if (pos >= input.length) throw const FormatException();
    if (input[pos] == '}') {
      pos++;
      break;
    }
    final selector = RegExp(
      r'^(=\d+|zero|one|two|few|many|other)\s*\{',
    ).firstMatch(input.substring(pos));
    if (selector == null) throw const FormatException();
    final key = selector.group(1)!;
    if (forms.containsKey(key)) throw const FormatException();
    pos += selector.end;
    final start = pos;
    var depth = 1;
    while (pos < input.length && depth > 0) {
      if (input[pos] == '{') depth++;
      if (input[pos] == '}') depth--;
      pos++;
    }
    if (depth != 0) throw const FormatException();
    final form = input.substring(start, pos - 1);
    if (form.replaceAll('{count}', '').contains(RegExp(r'[{}]'))) {
      throw const FormatException();
    }
    forms[key] = form;
  }
  if (input.substring(pos).trim().isNotEmpty || !forms.containsKey('other')) {
    throw const FormatException();
  }
  String render(String value) =>
      value.replaceAll('{count}', '$count').replaceAll('#', '$count');
  final exact = forms['=$count'];
  if (exact != null) return render(exact);
  return render(
    Intl.plural(
      count,
      locale: locale,
      zero: forms['zero'],
      one: forms['one'],
      two: forms['two'],
      few: forms['few'],
      many: forms['many'],
      other: forms['other']!,
    ),
  );
}
