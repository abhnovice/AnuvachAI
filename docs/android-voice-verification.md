# Android voice preview verification

The Android preview opens an authenticated WebSocket directly to Cloud Run. The Fastify route forwards mic frames to the existing Python Live endpoint. Capture is mono signed PCM16 at 16 kHz in 20 ms frames (640 bytes). Gemini returns mono PCM16 at 24 kHz. Both are little-endian. Android supplies the requested sample rates using its audio stack. The app requests communication audio focus and enables the device echo canceler when available. Only Gemini's interruption signal clears an active reply.

## Build and deploy

From the repository root, build a new image and update the Firebase Hosting target service by image. Updating the existing service preserves its configured environment, secret bindings, and service account.

```bash
voice_image="asia-south1-docker.pkg.dev/anuvachai/anuvach-repo/anuvach-backend:voice-$(date +%Y%m%d-%H%M%S)"
gcloud builds submit --project=anuvachai --tag="$voice_image" .
gcloud run services update anuvachai-git --project=anuvachai --region=asia-south1 --image="$voice_image"
VOICE_TRACE=true npm run build:mobile
adb install -r apps/mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
adb logcat -v monotonic -s flutter:I VoicePreview:I
```

Run `npm run build:mobile` for an APK with tracing disabled. If the phone uses a different ABI, check it with `adb shell getprop ro.product.cpu.abi` and install the matching APK.

## Four short device sessions

1. Sign in to the trial account and open Check. Set media and call volume to a comfortable level. Disconnect earbuds for the initial feedback check and note whether Android routes playback to the loudspeaker or earpiece.
2. Select English and tap **Start voice**. Wait for **Listening**, then say “Someone claiming to be support asked for my ExampleApp code.” Repeat with Hindi, Tamil, and Urdu selected. Start in the selected language every time.

   - Hindi — “सपोर्ट से होने का दावा करने वाले एक व्यक्ति ने मेरा ExampleApp कोड माँगा।”
   - Tamil — “ஆதரவுக் குழுவிலிருந்து பேசுவதாகச் சொன்ன ஒருவர் என் ExampleApp குறியீட்டைக் கேட்டார்.”
   - Urdu — “ایک شخص نے خود کو سپورٹ سے بتایا اور میرا ExampleApp کوڈ مانگا۔”

3. Log the language of the first audible reply and one follow-up. Compare what you hear with the reply transcript. Check that the employee transcript preserves ExampleApp, the reported request, and the uncertainty about who called. Tap **Use in draft**, edit a word, and verify that the draft reflects the edit. Stop before confirming unless you intend to create a test ticket.
4. During one reply, start speaking over it with a new synthetic detail. Check that queued assistant audio stops, the new statement is captured, and the next reply answers it. Deliberately switch to another language within one session and check that both statements remain in their original languages.
5. During another reply, stay silent. If the app interrupts itself or displays its own audio as employee speech, repeat that turn with headphones and compare. Note the audio route and the `aec_enabled` diagnostic. During each language check, background the app or briefly disable network access. Start voice again with the same selection and verify the first reply is still in that language and completed statements are available.
6. Compare `capture_read_ms`, the first Flutter capture/upload and delivery times, `gemini_input_to_audio_ms`, and `playback_started_ms`. Use the monotonic log timestamps to align Flutter delivery with native playback start. Record `max_arrival_gap_ms` and `playback_underruns`, and distinguish transport gaps from audible gaps. To measure audible gap duration, capture playback with an external recorder during the synthetic session and inspect the waveform alongside the trace. Note which pauses are normal speech pauses. Stop after the four checks and any one repeat needed to isolate echo.

## Measurements from development

The local benchmark ran the Fastify routes with a simulated 90 ms round trip and a loopback agent emitting ten 40 ms chunks, then an interruption. Times start at the first synthetic frame. This measures transport and receipt. The live fixture uses a separate synthetic English utterance.

| Measurement                     | HTTP polling | WebSocket |
| ------------------------------- | -----------: | --------: |
| First frame at agent            |        52 ms |     48 ms |
| Mock first audio generated      |       203 ms |    199 ms |
| First audio at client           |       326 ms |    247 ms |
| First audio generated to client |       122 ms |     48 ms |
| Inter-chunk receipt gaps        |     0–111 ms |  39–41 ms |
| Chunks delivered                |         9/10 |     10/10 |
| Interruption at client          |       719 ms |    649 ms |

ADB found no connected device. Native capture latency, playback start, audible gaps, echo, and the four spoken-language checks remain unmeasured. The English Live gate timed out at 30 seconds before and after. A direct Gemini setup probe received an acknowledgement in 506 ms, and a separate direct synthetic speech probe timed out without audio. These results demonstrate the polling delay and leave the live response timeout unresolved.
