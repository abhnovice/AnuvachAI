import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioEngine: AVAudioEngine?
  private func stopMicrophone() { audioEngine?.stop(); audioEngine?.inputNode.removeTap(onBus: 0); audioEngine = nil }
  override func applicationWillResignActive(_ application: UIApplication) { stopMicrophone(); super.applicationWillResignActive(application) }
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let local = FlutterMethodChannel(name: "ai.anuvach/local_features", binaryMessenger: controller.binaryMessenger)
      local.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        if call.method == "openLink" {
          guard let arguments = call.arguments as? [String: Any],
                let value = arguments["url"] as? String,
                let url = URL(string: value), url.scheme == "https", url.host != nil else {
            result(FlutterError(code: "INVALID", message: "Expected an HTTPS link", details: nil))
            return
          }
          UIApplication.shared.open(url, options: [:]) { opened in
            if opened { result(nil) }
            else { result(FlutterError(code: "UNAVAILABLE", message: "Could not open the link", details: nil)) }
          }
          return
        }
        if call.method == "stopMic" { self.stopMicrophone(); result(nil); return }
        if call.method == "listApps" || call.method == "openApp" {
          result(FlutterError(code: "UNAVAILABLE", message: "iOS does not expose other apps’ permissions.", details: nil)); return
        }
        guard call.method == "startMic" else { result(FlutterMethodNotImplemented); return }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
          DispatchQueue.main.async {
            guard granted else { result(false); return }
            do {
              self.stopMicrophone()
              let session = AVAudioSession.sharedInstance()
              try session.setCategory(.record, mode: .measurement)
              try session.setActive(true)
              let engine = AVAudioEngine()
              let input = engine.inputNode
              let format = input.outputFormat(forBus: 0)
              input.installTap(onBus: 0, bufferSize: 1024, format: format) { _, _ in }
              try engine.start()
              self.audioEngine = engine
              result(true)
            } catch { self.stopMicrophone(); result(FlutterError(code: "MIC_FAILED", message: error.localizedDescription, details: nil)) }
          }
        }
      }
      let channel = FlutterMethodChannel(name: "ai.anuvach/device_review", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        if call.method == "openSettings", let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:]) { opened in
            if opened { result(nil) }
            else { result(FlutterError(code: "UNAVAILABLE", message: "Open Settings manually.", details: nil)) }
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
