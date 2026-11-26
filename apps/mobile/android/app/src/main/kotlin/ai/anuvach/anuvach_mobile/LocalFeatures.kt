package ai.anuvach.anuvach_mobile

import android.Manifest
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.media.AudioFormat
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

/** Local features only; no audio or inventory leaves the device. */
class LocalFeatures(private val activity: FlutterActivity, private val channel: MethodChannel) {
    private val executor = Executors.newSingleThreadExecutor()
    @Volatile private var recorder: AudioRecord? = null
    private var streamMic = false
    private var player: AudioTrack? = null
    private var playerRate = 0
    private var permissionReply: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMic" -> startMic(result, call.argument<String>("language") ?: "en", false)
                "startVoice" -> startMic(result, call.argument<String>("language") ?: "en", true)
                "playVoice" -> {
                    try {
                        val bytes = call.argument<ByteArray>("pcm") ?: error("Missing PCM")
                        val rate = call.argument<Int>("rate") ?: 24000
                        require(rate in 8000..48000 && bytes.size % 2 == 0)
                        if (player == null || playerRate != rate) {
                            stopPlayback()
                            val min = AudioTrack.getMinBufferSize(rate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
                            check(min > 0)
                            @Suppress("DEPRECATION")
                            val audio = AudioTrack(AudioManager.STREAM_MUSIC, rate, AudioFormat.CHANNEL_OUT_MONO,
                                AudioFormat.ENCODING_PCM_16BIT, maxOf(min, rate / 2), AudioTrack.MODE_STREAM)
                            if (audio.state != AudioTrack.STATE_INITIALIZED) { audio.release(); error("Audio output unavailable") }
                            player = audio
                            playerRate = rate
                            audio.play()
                        }
                        result.success(player!!.write(bytes, 0, bytes.size, AudioTrack.WRITE_NON_BLOCKING))
                    } catch (_: Exception) { result.error("PLAYBACK_FAILED", "Audio playback unavailable", null) }
                }
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
            val size = AudioRecord.getMinBufferSize(16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
            if (size <= 0) throw IllegalStateException("Microphone format unavailable")
            @Suppress("MissingPermission")
            val audio = AudioRecord(if (streamMic) MediaRecorder.AudioSource.VOICE_COMMUNICATION else MediaRecorder.AudioSource.MIC, 16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, size)
            if (audio.state != AudioRecord.STATE_INITIALIZED) { audio.release(); throw IllegalStateException("Microphone unavailable") }
            try { audio.startRecording() } catch (error: Exception) { audio.release(); throw error }
            recorder = audio
            if (streamMic) Thread {
                val buffer = ByteArray(3200)
                try {
                    while (recorder === audio) {
                        val count = audio.read(buffer, 0, buffer.size)
                        if (count <= 0) break
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
        } catch (error: Exception) { result.error("MIC_FAILED", error.message, null) }
    }
    fun stopPlayback() {
        player?.let { audio ->
            try { audio.pause(); audio.flush() } catch (_: IllegalStateException) {}
            audio.release()
        }
        player = null
    }

    fun stopMic() {
        val audio = recorder
        recorder = null
        if (audio != null) {
            try { audio.stop() } catch (_: IllegalStateException) {}
            audio.release()
            if (streamMic) channel.invokeMethod("voiceMicStopped", null)
        }
    }
    fun dispose() { stopMic(); stopPlayback(); executor.shutdownNow() }
}
