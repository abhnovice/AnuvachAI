# Your exercise: confirmation validity

Create a pure Dart function in a new exercise file:

```dart
bool canSubmitReviewedDraft({
  required int draftRevision,
  required int? reviewedRevision,
  required int? confirmedRevision,
  required bool submitting,
});
```

Acceptance criteria:

- Return true only when reviewedRevision and confirmedRevision both equal the current draftRevision and submitting is false.
- Unreviewed and unconfirmed drafts return false.
- Editing after review or confirmation returns false, even if a confirmation boolean was previously true.
- While submitting, return false to prevent double submission.
- Add a small table-driven unit test covering these cases.

Keep this isolated from the working submission flow initially. Send your implementation and tests back; I will review the logic and discuss how to integrate it safely.
