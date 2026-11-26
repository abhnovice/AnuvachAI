# Remote Config payload status

`arb_overrides_ta.json` contains Tamil values for every key currently declared in the Flutter English ARB and admin English dictionary. It does not translate UI text that is still hardcoded in application code.

Files named `arb_overrides_<locale>.draft.json` contain only currently available bundled translations. They are incomplete for most locales and must not be used as complete replacement values in Firebase: doing so can remove existing remote overrides. See `localization-coverage.json` for the missing declared keys per locale. English is complete for the declared keys.

For Firebase, the parameter names are `arb_overrides_en`, `arb_overrides_hi`, `arb_overrides_ta`, `arb_overrides_te`, `arb_overrides_bn`, `arb_overrides_kn`, `arb_overrides_ml`, `arb_overrides_ur`, and `arb_overrides_pa`. Merge any intended changes with existing parameter values before publishing.
