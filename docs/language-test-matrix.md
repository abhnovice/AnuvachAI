# Stage 3 language test matrix

Text uses `gemini-3.5-flash-lite` for reporting and real A2A triage. Speech uses `gemini-2.5-flash-native-audio-preview-12-2025` and eSpeak NG audio sent through the localhost workbench WebSocket. Results are from November 26, 2026.

| Language | Synthetic case | Gemini text and A2A | Missing facts logged | Time to confirmed ticket (s) | A2A (s) | Speech first audio (s) | Speech input word recall |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| English | `I received a suspicious support call.` | Passed across runs | 4 | 13.745 | 4.279 | 5.514 | 100% |
| Hindi | `मुझे एक संदिग्ध सहायता कॉल आया।` | Passed across runs | 4 | 3.299 | 3.042 | 4.971 | 0% |
| Tamil | `எனக்கு சந்தேகமான ஆதரவு அழைப்பு வந்தது.` | Passed across runs | 4 | 5.430 | 2.122 | Timed out | No final input |
| Telugu | `నాకు అనుమానాస్పద మద్దతు కాల్ వచ్చింది.` | Passed across runs | 3 | 2.876 | 1.992 | 6.055 | 0% |
| Bengali | `আমি একটি সন্দেহজনক সহায়তা ফোন পেয়েছি।` | Passed across runs | 3 | 11.429 | 4.139 | 8.321 | 0% |
| Kannada | `ನನಗೆ ಅನುಮಾನಾಸ್ಪದ ಬೆಂಬಲ ಕರೆ ಬಂದಿದೆ.` | Passed across runs | 4 | 4.585 | 3.001 | Timed out | No final input |
| Malayalam | `എനിക്ക് സംശയാസ്പദമായ സഹായ കോൾ ലഭിച്ചു.` | Passed across runs | 3 | 6.754 | 4.287 | 7.434 | 0% |
| Urdu | `مجھے ایک مشکوک معاونتی کال موصول ہوئی۔` | Passed across runs | 3 | 5.523 | 3.559 | 6.288 | 0% |
| Punjabi | `ਮੈਨੂੰ ਇੱਕ ਸ਼ੱਕੀ ਸਹਾਇਤਾ ਕਾਲ ਆਈ।` | Passed across runs | 3 | 5.309 | 8.865 | 4.871 | 0% |
| Mixed Tamil + English | `IT support என்று சொன்னவர் pairing code கேட்டார்.` | Passed across runs | 4 | 6.432 | 4.130 | Not run | Not run |

### Text findings

The application preserved all 10 first statements and the English follow-up exactly. The reporting model called `update_draft_unknowns` once in each of the 11 successful turns with zero tool-result errors. It recorded 3–4 remaining details per first turn, generally timing, caller request, employee action, or uncertainty. In English it moved on to the caller request after timing was supplied, even though sharing a pairing code was denied. The draft correction preserved the original transcript and saved the corrected text separately. Urdu combined timing and caller request into one reply. Some tool arguments and administrator recommendations were in English or bilingual. The study covered one short case per language and did not assess general extraction or response quality.

All 10 reported successful triage runs proposed `unassessed` severity with human review required. There were zero unsupported severity claims in those outputs. Offline tests reject nonexistent evidence IDs and unsupported high or critical proposals. A full matrix invocation hit two `RESOURCE_EXHAUSTED` errors. A targeted retry completed Bengali, preserved the Kannada ticket after a peer failure, and hit a second-turn English `DEADLINE_EXCEEDED`. A further targeted run completed Kannada and both English turns. The timing column uses successful runs with scripted employee confirmation and includes the reporting request and review/edit calls where applicable.

The selected successful runs returned 16,561 prompt tokens and 4,281 candidate tokens, or 20,842 total. The estimated standard paid-tier equivalent is USD 0.01567 for the reported calls. This is computed at USD 0.30/M input and USD 2.50/M output and excludes retries and failures absent from the selected usage records. Actual account charges were unavailable. [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing#gemini-3.5-flash-lite)

### Speech findings

In the final Live run, English matched its reference after case and punctuation normalization and returned a spoken follow-up. Six other languages returned audio and input text but had zero exact reference-word recall. Tamil and Kannada timed out without a final transcript or audio in this run. An earlier run received output audio for both, without a final input transcript. The resulting audio timings measure from the first fixture PCM send to the workbench's first received model audio packet. The SDK emitted no collected Live usage metadata during these runs, so audio cost is unavailable.

The voice gate failed. The input fixtures are synthesized speech, which tests a real audio round trip with a single voice per language. Browser microphone capture, audible playback, live interruption and reconnect with people speaking remain unverified. PCM scheduling and stopping queued playback passed with a mocked AudioContext. Synthetic text capture and A2A fixture results are covered by `tests/test_language_matrix.py`.

## Stage 3 closeout speech assessment

One eSpeak NG fixture per language was streamed as mono PCM16 at 16 kHz through the existing Gemini Live workbench. The English and Tamil targeted check ran first. These are synthesized spoken inputs. Native-speaker and physical-device speech quality are unverified. The correction column provides the fixture reference an employee would need to restore. No employee corrections were assumed to have occurred in the automated speech run. Audio timing measures reception of the first PCM packet. Gemini supplied no usable audio-usage metadata in these runs.

| Language | Spoken reference and correction target | Input transcript | Essential facts surviving capture | Output transcript and audio | First audio | Voice status |
| --- | --- | --- | --- | --- | ---: | --- |
| English | I received a suspicious support call. | I received a suspicious support call. | Suspicious support call received | A suspicious support call? Could you describe what the caller requested from you? | 4.821 s | Verified with synthesized audio |
| Hindi | मुझे एक संदिग्ध सहायता कॉल आया। | Muchie, SMG account. | No reliable suspicious support call fact | नमस्ते। क्या आप मुझे संदिग्ध गतिविधि के बारे में बता सकते हैं? | 4.760 s | Limited, use text fallback |
| Tamil | எனக்கு சந்தேகமான ஆதரவு அழைப்பு வந்தது. | No final transcript | No reliable suspicious support call fact | No output, 30 s timeout | — | Limited, use text fallback |
| Telugu | నాకు అనుమానాస్పద మద్దతు కాల్ వచ్చింది. | . | No reliable suspicious support call fact | ఏం జరిగింది? అనుమానిత భద్రతా సంఘటనకు సంబంధించి మీరు ఏదైనా తెలియజేయాలనుకుంటున్నారా? | 7.057 s | Limited, use text fallback |
| Bengali | আমি একটি সন্দেহজনক সহায়তা ফোন পেয়েছি। | A miek pišo neho jo nokšo Hajota Fonpi. | No reliable suspicious support call fact | ফোনে কি হয়েছিল? | 6.467 s | Limited, use text fallback |
| Kannada | ನನಗೆ ಅನುಮಾನಾಸ್ಪದ ಬೆಂಬಲ ಕರೆ ಬಂದಿದೆ. | No final transcript | No reliable suspicious support call fact | No output, 30 s timeout | — | Limited, use text fallback |
| Malayalam | എനിക്ക് സംശയാസ്പദമായ സഹായ കോൾ ലഭിച്ചു. | . | No reliable suspicious support call fact | തീർച്ചയായും, ഞാൻ സഹായിക്കാം. എന്താണ് സംഭവിച്ചത്? | 9.119 s | Limited, use text fallback |
| Urdu | مجھے ایک مشکوک معاونتی کال موصول ہوئی۔ | . | No reliable suspicious support call fact | ٹھیک ہے۔ اس ای میل میں کیا مانگا گیا تھا؟ | 7.633 s | Limited, use text fallback |
| Punjabi | ਮੈਨੂੰ ਇੱਕ ਸ਼ੱਕੀ ਸਹਾਇਤਾ ਕਾਲ ਆਈ। | मैं एक शा की सहायता का | No reliable suspicious support call fact | ਮੈਂ ਸੁਰੱਖਿਆ ਘਟਨਾ ਵਿੱਚ ਤੁਹਾਡੀ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ। ਕਿਰਪਾ ਕਰਕੇ ਦੱਸੋ ਕਿ ਕੀ ਹੋਇਆ? | 7.215 s | Limited, use text fallback |

English retained the essential fact. Hindi and Bengali mangled the sentence, Telugu, Malayalam and Urdu produced punctuation only, and Punjabi produced a fragment in Devanagari. An Urdu assistant reply asked about email even though the reference described a call. Tamil and Kannada supplied neither a final transcript nor audio. These are failures on the incident-fact rubric as well as on literal recall. Seven languages returned output audio bytes. The nine-language quality test exited with one failure as expected from these rows.
