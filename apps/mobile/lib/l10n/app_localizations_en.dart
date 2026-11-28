// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get unknown => 'Unknown';

  @override
  String get check => 'Check';

  @override
  String get reports => 'Reports';

  @override
  String get apps => 'Access';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get message => 'Message';

  @override
  String get send => 'Send';

  @override
  String get start => 'Start microphone';

  @override
  String get stop => 'Stop microphone';

  @override
  String get local => 'Microphone on · no audio saved or sent';

  @override
  String get soon => 'AI conversation coming later';

  @override
  String get scan => 'Review apps';

  @override
  String get search => 'Search apps';

  @override
  String get permissions => 'Permissions';

  @override
  String get granted => 'Granted';

  @override
  String get notGranted => 'Not granted';

  @override
  String get openSettings => 'Open settings';

  @override
  String get unavailable => 'Unavailable on iOS';

  @override
  String get micDenied => 'Microphone permission not granted.';

  @override
  String get micUnavailable => 'Microphone unavailable.';

  @override
  String get iosGuide => 'Review permissions in iOS Settings.';

  @override
  String get visibilityNote =>
      'Visible launcher apps only · Permission grants do not prove use.';

  @override
  String welcomeName(String name) {
    return 'Hello, $name';
  }

  @override
  String reportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
      zero: 'No reports',
    );
    return '$_temp0';
  }

  @override
  String get accessUnavailable => 'Could not load apps.';

  @override
  String get settingsUnavailable => 'Could not open settings.';

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
  String get describeIncident => 'Describe the incident';

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
  String get submitting => 'Submitting…';

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
  String get appNameOptional => 'App name (optional)';

  @override
  String get evidenceNotesOptional => 'Evidence notes (optional)';

  @override
  String get descriptionTooShort =>
      'Describe the incident in at least 10 characters.';

  @override
  String get reportLanguageLabel => 'Report language';

  @override
  String get englishLanguage => 'English';

  @override
  String get hindiLanguage => 'Hindi';

  @override
  String get mixedLanguage => 'Mixed English / Hindi';

  @override
  String get incidentTypeLabel => 'Incident type';

  @override
  String get supportCall => 'Support call';

  @override
  String get suspiciousMessage => 'Suspicious message';

  @override
  String get mistakenReport => 'Mistaken report';

  @override
  String get otherIncident => 'Other';

  @override
  String get optionalDeviceReview => 'Optional device review';

  @override
  String get androidDeviceReview =>
      'With your consent, check whether Android reports a secure screen lock. This does not check installed remote-access apps or permission use.';

  @override
  String get iosDeviceReview =>
      'Automatic device checks are unavailable on iOS in this stage. Review installed apps and permissions manually in Settings, or contact your known helpdesk.';

  @override
  String get allowOneCheck => 'Allow this one check?';

  @override
  String get checkExplanation =>
      'Read secure screen-lock configuration now and include its result and timestamp in your report. No runtime permission is needed.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get checkAndInclude => 'Check and include';

  @override
  String get checking => 'Checking…';

  @override
  String get reviewDeviceCheck => 'Review and consent to device check';

  @override
  String get removeObservation => 'Remove device observation';

  @override
  String get detailTitle => 'Report detail';

  @override
  String get ticketDetails => 'TICKET DETAILS';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get latestUpdate => 'LATEST UPDATE';

  @override
  String get statusLabel => 'Status';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusAwaitingEmployee => 'Awaiting employee';

  @override
  String get statusEscalated => 'Escalated';

  @override
  String get statusClosed => 'Closed';

  @override
  String get submittedAt => 'Submitted';

  @override
  String get updatedAt => 'Updated';

  @override
  String get timesInUtc => 'Times shown in UTC.';

  @override
  String get helpTitle => 'Help, privacy and settings';

  @override
  String get stayInControl => 'You stay in control.';

  @override
  String get helpIntro =>
      'Know what is shared, what is stored, and what this stage can check.';

  @override
  String get reportExplained => 'Your report, explained';

  @override
  String get demoConnection => 'Demo connection';

  @override
  String get openAppSettings => 'Open this app’s settings';

  @override
  String get stepDescribe => 'Describe';

  @override
  String get stepReview => 'Review';

  @override
  String get stepSubmit => 'Submit';

  @override
  String get submittedStatements => 'SUBMITTED STATEMENTS';

  @override
  String get employeeReported => 'Employee reported';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get appNameLabel => 'App name';

  @override
  String get evidenceNotesLabel => 'Evidence notes';

  @override
  String get notSupplied => 'Not supplied';

  @override
  String get demoEmployeeIdentity => 'Employee identity: demo-employee';

  @override
  String get optionalChecks => 'OPTIONAL CHECKS';

  @override
  String get deviceObserved => 'Device observed';

  @override
  String get noDeviceFacts => 'No automatic device facts included.';

  @override
  String get secureScreenLock => 'Secure screen lock';

  @override
  String get configured => 'configured';

  @override
  String get notConfigured => 'not configured';

  @override
  String get publicApiClientReported => 'Android public API · client-reported';

  @override
  String get checkedAt => 'Checked';

  @override
  String get observationDisclaimer =>
      'These observations do not establish remote access, compromise, or whether a permission was used.';

  @override
  String get helpStorage =>
      'Use synthetic data only. Drafts are stored locally in app preferences, without encryption. Submitted facts are stored by the local API in SQLite. Administrator notes stay in the administrator view. This demonstration has no authentication.';

  @override
  String get helpSettings =>
      'Opening settings does not change any setting. On Android you can inspect this app’s settings; on iOS you can open this app’s Settings page. Review other apps and permissions manually through system Settings. A visible permission does not prove it was used.';

  @override
  String get helpRoles =>
      'Security and data protection are separate reviewer roles in the demonstration model. Real employee data requires server-enforced access control and a defined retention policy.';

  @override
  String get settingsOpenError =>
      'Could not open settings. Open system Settings manually.';

  @override
  String get apiAddressLabel => 'API address';

  @override
  String get apiBuildHint => 'Set API_BASE_URL at build/run time.';

  @override
  String get voiceWelcome => 'Talk it through.';

  @override
  String get voiceWelcomeHint =>
      'Tell me what happened. You can speak or type.';

  @override
  String get voiceAssistant => 'Anuvach assistant';

  @override
  String get voiceYou => 'You';

  @override
  String get voiceReady => 'Ready to listen';

  @override
  String get voiceConnecting => 'Connecting…';

  @override
  String get voiceListening => 'Listening';

  @override
  String get voiceThinking => 'Thinking…';

  @override
  String get voiceSpeaking => 'Speaking';

  @override
  String get voiceEnding => 'Wrapping up…';

  @override
  String get voiceUnavailable => 'Voice unavailable. You can still type.';

  @override
  String get voicePartial => 'Live transcript';

  @override
  String get voiceCorrect => 'Correct transcript';

  @override
  String get voiceUse => 'Use in report';

  @override
  String get voiceDraft => 'Review ticket draft';

  @override
  String get voiceStart => 'Start voice';

  @override
  String get voiceEnd => 'End voice';

  @override
  String get voiceApply => 'Apply correction';

  @override
  String get voiceType => 'Type a message';

  @override
  String get noReports => 'No reports yet';

  @override
  String get reportHistoryHint =>
      'Submitted tickets and their latest status will appear here.';

  @override
  String get refreshReports => 'Refresh reports';

  @override
  String get tryAgain => 'Try again';

  @override
  String get showReports => 'Show reports';

  @override
  String get callPrompt => 'I got a call from someone claiming to be';

  @override
  String get messagePrompt => 'I received a message asking me to';

  @override
  String get voiceLogoStart => 'Start voice with the Anuvach logo';

  @override
  String get accessOverview => 'Your access overview';

  @override
  String get accessBriefing => 'Gemini · accessibility briefing';

  @override
  String get accessBriefingUnavailable =>
      'Gemini briefing is unavailable here. You can still review apps and settings locally.';

  @override
  String get voiceStartupNotice =>
      'Use synthetic details only. On Android, voice starts on opening if microphone access is already granted. Live voice sends microphone audio to the reporting assistant until you stop voice or leave Check.';
}
