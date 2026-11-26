package ai.anuvach.anuvach_mobile

import android.Manifest
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.audiofx.AcousticEchoCanceler
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.AudioManager
import android.media.MediaRecorder
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.Locale
import android.content.res.Configuration

/** Android audio I/O and local device features exposed to Flutter. */
class LocalFeatures(private val activity: FlutterActivity, private val channel: MethodChannel) {
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var recorder: AudioRecord? = null
    private var streamMic = false
    private var player: AudioTrack? = null
    private var playerRate = 0
    private val audioManager = activity.getSystemService(AudioManager::class.java)
    private val handler = Handler(Looper.getMainLooper())
    private val voiceAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private var focusRequest: AudioFocusRequest? = null
    private var previousMode: Int? = null
    private var echoCanceler: AcousticEchoCanceler? = null
    private var trace = false
    private var playbackStart: Runnable? = null
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change < 0) {
            stopVoiceSession()
            channel.invokeMethod("voiceFocusLost", null)
        }
    }
    private var permissionReply: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMic" -> startMic(result, call.argument<String>("language") ?: "en", false)
                "startVoice" -> {
                    trace = call.argument<Boolean>("trace") == true
                    startMic(result, call.argument<String>("language") ?: "en", true)
                }
                "playVoice" -> {
                    try {
                        val bytes = call.argument<ByteArray>("pcm") ?: error("Missing PCM")
                        val rate = call.argument<Int>("rate") ?: 24000
                        require(rate in 8000..48000 && bytes.size % 2 == 0)
                        if (player == null || playerRate != rate) {
                            stopPlayback()
                            val min = AudioTrack.getMinBufferSize(rate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
                            check(min > 0)
                            val audio = AudioTrack.Builder()
                                .setAudioAttributes(voiceAttributes)
                                .setAudioFormat(AudioFormat.Builder().setSampleRate(rate)
                                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                                .setBufferSizeInBytes(maxOf(min, rate * 2 * 120 / 1000))
                                .setTransferMode(AudioTrack.MODE_STREAM)
                                .build()
                            if (audio.state != AudioTrack.STATE_INITIALIZED) {
                                audio.release()
                                error("Audio output unavailable")
                            }
                            if (Build.VERSION.SDK_INT >= 31) {
                                audio.setStartThresholdInFrames(minOf(audio.bufferSizeInFrames, rate * 20 / 1000))
                            }
                            player = audio
                            playerRate = rate
                            audio.play()
                            if (trace) watchPlaybackStart(audio)
                        }
                        result.success(player!!.write(bytes, 0, bytes.size, AudioTrack.WRITE_NON_BLOCKING))
                    } catch (_: Exception) { result.error("PLAYBACK_FAILED", "Audio playback unavailable", null) }
                }
                "releaseVoice" -> { stopVoiceSession(); result.success(null) }
                "clearVoice" -> { stopPlayback(); result.success(null) }
                "stopMic" -> { stopMic(); result.success(null) }
                "listApps" -> executor.execute {
                    try {
                        val pm = activity.packageManager
                        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                        @Suppress("DEPRECATION")
                        val apps = pm.queryIntentActivities(intent, 0).mapNotNull { resolved ->
                            try {
                                @Suppress("DEPRECATION")
                                val info = pm.getPackageInfo(resolved.activityInfo.packageName, PackageManager.GET_PERMISSIONS)
                                val requests = info.requestedPermissions ?: emptyArray()
                                val flags = info.requestedPermissionsFlags
                                mapOf(
                                    "name" to info.applicationInfo?.loadLabel(pm).toString(),
                                    "package" to info.packageName,
                                    "version" to (info.versionName ?: ""),
                                    "permissions" to requests.mapIndexed { i, permission ->
                                        mapOf("name" to permission, "granted" to
                                            (if (flags != null && i < flags.size) flags[i] and PackageInfo.REQUESTED_PERMISSION_GRANTED != 0 else null))
                                    }
                                )
                            } catch (_: PackageManager.NameNotFoundException) { null }
                        }.distinctBy { it["package"] }.sortedBy { (it["name"] as String).lowercase() }
                        activity.runOnUiThread { result.success(apps) }
                    } catch (error: Exception) {
                        activity.runOnUiThread { result.error("INVENTORY_FAILED", error.message, null) }
                    }
                }
                "openApp" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg == null) result.error("INVALID", "Missing package", null)
                    else try {
                        activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg")))
                        result.success(null)
                    } catch (error: Exception) { result.error("UNAVAILABLE", error.message, null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startMic(result: MethodChannel.Result, language: String, stream: Boolean) {
        if (recorder != null) { result.success(streamMic == stream); return }
        if (permissionReply != null) { result.error("BUSY", "Permission request already in progress", null); return }
        streamMic = stream
        if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            openMic(result)
        } else if (activity.shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO)) {
            AlertDialog.Builder(activity)
                .setMessage(activity.createConfigurationContext(Configuration(activity.resources.configuration).apply {
                    setLocale(Locale.forLanguageTag(language))
                }).getString(R.string.microphone_rationale))
                .setNegativeButton(android.R.string.cancel) { _, _ -> result.success(false) }
                .setPositiveButton(android.R.string.ok) { _, _ -> requestMic(result) }
                .setOnCancelListener { result.success(false) }
                .show()
        } else requestMic(result)
    }
    private fun requestMic(result: MethodChannel.Result) {
        permissionReply = result
        activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 7401)
    }
    fun onPermission(requestCode: Int, grants: IntArray) {
        if (requestCode != 7401) return
        val reply = permissionReply ?: return
        permissionReply = null
        if (grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED) openMic(reply)
        else reply.success(false)
    }
    private fun openMic(result: MethodChannel.Result) {
        try {
            if (streamMic) acquireFocus()
            val size = AudioRecord.getMinBufferSize(16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
            if (size <= 0) throw IllegalStateException("Microphone format unavailable")
            @Suppress("MissingPermission")
            val audio = AudioRecord(if (streamMic) MediaRecorder.AudioSource.VOICE_COMMUNICATION else MediaRecorder.AudioSource.MIC, 16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, size)
            if (audio.state != AudioRecord.STATE_INITIALIZED) { audio.release(); throw IllegalStateException("Microphone unavailable") }
            if (streamMic && AcousticEchoCanceler.isAvailable()) {
                echoCanceler = runCatching {
                    AcousticEchoCanceler.create(audio.audioSessionId)?.apply { enabled = true }
                }.getOrNull()
            }
            try { audio.startRecording() } catch (error: Exception) { audio.release(); throw error }
            val traceCapture = streamMic && trace
            val started = SystemClock.elapsedRealtime()
            if (traceCapture) Log.i("VoicePreview", "capture_open_ms=$started aec_enabled=${echoCanceler?.enabled == true}")
            recorder = audio
            if (streamMic) Thread {
                val buffer = ByteArray(640)
                var first = true
                try {
                    while (recorder === audio) {
                        val count = audio.read(buffer, 0, buffer.size)
                        if (count <= 0) break
                        if (first && traceCapture) {
                            Log.i("VoicePreview", "first_pcm_ms=${SystemClock.elapsedRealtime()} capture_read_ms=${SystemClock.elapsedRealtime() - started} bytes=$count")
                        }
                        first = false
                        val packet = buffer.copyOf(count)
                        activity.runOnUiThread {
                            if (recorder === audio) channel.invokeMethod("voicePcm", packet)
                        }
                    }
                } catch (_: Exception) {
                    // The recorder can be released during a blocking read.
                }
                activity.runOnUiThread {
                    if (recorder === audio) stopMic()
                }
            }.start()
            result.success(true)
        } catch (error: Exception) {
            if (streamMic) stopVoiceSession()
            result.error("MIC_FAILED", error.message, null)
        }
    }
    @Suppress("DEPRECATION")
    private fun acquireFocus() {
        if (previousMode != null) return
        val grant = if (Build.VERSION.SDK_INT >= 26) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(voiceAttributes)
                .setOnAudioFocusChangeListener(focusListener, handler)
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            audioManager.requestAudioFocus(focusListener, AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
        check(grant == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        previousMode = audioManager.mode
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
    }

    private fun watchPlaybackStart(audio: AudioTrack) {
        val start = SystemClock.elapsedRealtime()
        val sample = object : Runnable {
            override fun run() {
                if (player !== audio) return
                if (audio.playbackHeadPosition > 0) {
                    Log.i("VoicePreview", "playback_started_ms=${SystemClock.elapsedRealtime()} track_start_delay_ms=${SystemClock.elapsedRealtime() - start}")
                } else handler.postDelayed(this, 10)
            }
        }
        playbackStart = sample
        handler.post(sample)
    }

    fun stopPlayback() {
        playbackStart?.let(handler::removeCallbacks)
        playbackStart = null
        player?.let { audio ->
            if (trace && Build.VERSION.SDK_INT >= 24) {
                Log.i("VoicePreview", "playback_underruns=${audio.underrunCount}")
            }
            try { audio.pause(); audio.flush() } catch (_: IllegalStateException) {}
            audio.release()
        }
        player = null
    }

    fun stopMic() {
        val audio = recorder
        recorder = null
        echoCanceler?.release()
        echoCanceler = null
        if (audio != null) {
            try { audio.stop() } catch (_: IllegalStateException) {}
            audio.release()
            if (streamMic) channel.invokeMethod("voiceMicStopped", null)
        }
    }
    @Suppress("DEPRECATION")
    fun stopVoiceSession() {
        stopMic()
        stopPlayback()
        previousMode?.let { audioManager.mode = it }
        if (Build.VERSION.SDK_INT >= 26) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else if (previousMode != null) {
            audioManager.abandonAudioFocus(focusListener)
        }
        focusRequest = null
        previousMode = null
    }

    fun dispose() { stopVoiceSession(); executor.shutdownNow() }
}
