package ai.anuvach.anuvach_mobile

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.util.Log
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicInteger

/** Owns the PCM queue and AudioTrack on a dedicated audio thread. */
internal class VoicePlayback(
    private val attributes: AudioAttributes,
    private val onPlaying: (Boolean) -> Unit,
    private val onError: () -> Unit,
) {
    private val rate = 24000
    private val bytesPerMs = rate * 2 / 1000
    private val thread = HandlerThread("Anuvach playback", Process.THREAD_PRIORITY_AUDIO).apply { start() }
    private val worker = Handler(thread.looper)
    private val main = Handler(Looper.getMainLooper())
    private val generation = AtomicInteger()
    private val queue = ArrayDeque<ByteArray>()
    private var track: AudioTrack? = null
    private var offset = 0
    private var pendingBytes = 0
    private var writtenFrames = 0
    private var primeUntil = 0L
    private var started = false
    private var playing = false
    private var trace = false
    private var firstWriteAt = 0L
    private var lastEnqueueAt = 0L
    private var lastProgressAt = 0L
    private var lastHead = 0

    private val pump = object : Runnable {
        override fun run() {
            try {
                pumpAudio()
            } catch (error: Exception) {
                fail(error.message ?: error.javaClass.simpleName)
            }
        }
    }

    fun enqueue(pcm: ByteArray, traceEnabled: Boolean) {
        val epoch = generation.get()
        worker.post {
            if (generation.get() != epoch) return@post
            // Gemini can send several seconds of PCM before the phone can play it.
            if (pendingBytes + pcm.size > 20000 * bytesPerMs) {
                fail("reply buffer exceeded")
                return@post
            }
            if (track == null) primeUntil = SystemClock.elapsedRealtime() + 100
            lastEnqueueAt = SystemClock.elapsedRealtime()
            trace = traceEnabled
            queue.addLast(pcm)
            pendingBytes += pcm.size
            worker.removeCallbacks(pump)
            worker.post(pump)
        }
    }

    private fun pumpAudio() {
        val audio = track ?: buildTrack().also { track = it }
        while (queue.isNotEmpty()) {
            val chunk = queue.first
            val count = audio.write(chunk, offset, chunk.size - offset, AudioTrack.WRITE_NON_BLOCKING)
            check(count >= 0 && count % 2 == 0) { "AudioTrack write returned $count" }
            if (count == 0) break
            if (writtenFrames == 0) firstWriteAt = SystemClock.elapsedRealtime()
            writtenFrames += count / 2
            pendingBytes -= count
            offset += count
            if (offset == chunk.size) {
                queue.removeFirst()
                offset = 0
            }
        }
        if (!started && (writtenFrames >= rate * 80 / 1000 ||
                    SystemClock.elapsedRealtime() >= primeUntil || queue.isNotEmpty())) {
            if (Build.VERSION.SDK_INT < 31 && queue.isEmpty() && writtenFrames < audio.bufferSizeInFrames) {
                val silence = ByteArray((audio.bufferSizeInFrames - writtenFrames) * 2)
                val padding = audio.write(silence, 0, silence.size, AudioTrack.WRITE_NON_BLOCKING)
                check(padding >= 0)
                writtenFrames += padding / 2
            }
            audio.play()
            lastProgressAt = SystemClock.elapsedRealtime()
            started = true
        }
        val head = audio.playbackHeadPosition
        val now = SystemClock.elapsedRealtime()
        if (head != lastHead) {
            lastHead = head
            lastProgressAt = now
        }
        check(!started || head >= writtenFrames || now - lastProgressAt < 3000) { "playback head stalled" }
        if (started && head > 0 && !playing) {
            if (trace) Log.i("VoicePreview", "playback_started_ms=${SystemClock.elapsedRealtime()} track_start_delay_ms=${SystemClock.elapsedRealtime() - firstWriteAt}")
            setPlaying(true)
        }
        if (queue.isNotEmpty() || head < writtenFrames || now - lastEnqueueAt < 200) {
            worker.postDelayed(pump, 10)
        } else {
            resetTrack()
        }
    }

    private fun buildTrack(): AudioTrack {
        val min = AudioTrack.getMinBufferSize(rate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        check(min > 0)
        val audio = AudioTrack.Builder()
            .setAudioAttributes(attributes)
            .setAudioFormat(AudioFormat.Builder().setSampleRate(rate)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setBufferSizeInBytes(maxOf(min, 200 * bytesPerMs))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
        if (audio.state != AudioTrack.STATE_INITIALIZED) {
            audio.release()
            error("Audio output unavailable")
        }
        if (Build.VERSION.SDK_INT >= 31) {
            // Startup is primed in the worker. A short final chunk can play in full.
            audio.setStartThresholdInFrames(1)
        }
        return audio
    }

    private fun postCurrent(callback: () -> Unit) {
        val epoch = generation.get()
        main.post { if (generation.get() == epoch) callback() }
    }

    private fun setPlaying(value: Boolean) {
        if (playing == value) return
        playing = value
        postCurrent { onPlaying(value) }
    }

    private fun fail(reason: String) {
        Log.w("VoicePreview", reason)
        resetTrack()
        postCurrent(onError)
    }

    fun clear() {
        generation.incrementAndGet()
        worker.post { resetTrack() }
    }

    fun dispose() {
        clear()
        thread.quitSafely()
    }

    private fun resetTrack() {
        worker.removeCallbacks(pump)
        queue.clear()
        offset = 0
        pendingBytes = 0
        writtenFrames = 0
        lastHead = 0
        started = false
        track?.let { audio ->
            if (trace && Build.VERSION.SDK_INT >= 24) {
                Log.i("VoicePreview", "playback_underruns=${audio.underrunCount}")
            }
            try {
                audio.pause()
                audio.flush()
            } catch (_: IllegalStateException) {
                // The route can disappear during playback.
            }
            audio.release()
        }
        track = null
        setPlaying(false)
    }
}
