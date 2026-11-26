package ai.anuvach.anuvach_mobile

import android.app.KeyguardManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var localFeatures: LocalFeatures? = null
    override fun onPause() { localFeatures?.stopMic(); localFeatures?.stopPlayback(); super.onPause() }
    override fun onDestroy() { localFeatures?.dispose(); super.onDestroy() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        localFeatures?.onPermission(requestCode, grantResults)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        localFeatures = LocalFeatures(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ai.anuvach/local_features"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ai.anuvach/device_review")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "checkSecureLock" -> {
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                                result.error("UNAVAILABLE", "Requires Android API 23", null)
                            } else {
                                val manager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                                result.success(manager.isDeviceSecure)
                            }
                        }
                        "openSettings" -> {
                            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName")))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("DEVICE_REVIEW_FAILED", error.message, null)
                }
            }
    }
}
