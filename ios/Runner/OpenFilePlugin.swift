import Flutter
import UIKit

/// Receives .srt files opened from outside the app (Files app, Mail, Safari
/// downloads, etc. via the document type declared in Info.plist) and hands
/// their contents to Dart over a MethodChannel.
///
/// Registered manually from AppDelegate rather than through the normal
/// `GeneratedPluginRegistrant` flow, so `register(with:)` below is unused.
class OpenFilePlugin: NSObject, FlutterPlugin {
  static let channelName = "com.vargar.dubsubs/open_file"

  private let channel: FlutterMethodChannel
  private var pendingFile: [String: Any]?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: OpenFilePlugin.channelName, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [self] call, result in
      guard call.method == "getInitialFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(pendingFile)
      pendingFile = nil
    }
  }

  static func register(with registrar: FlutterPluginRegistrar) {}

  // Cold start: the app was launched by opening an .srt file.
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]
  ) -> Bool {
    if let url = launchOptions[.url] as? URL {
      pendingFile = readSrt(at: url)
    }
    return true
  }

  // Warm start: the app was already running when an .srt file was opened.
  func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard let payload = readSrt(at: url) else { return false }
    channel.invokeMethod("onFileOpened", arguments: payload)
    return true
  }

  /// Reads the opened file's bytes and deletes it — files handed to the app
  /// this way (without `LSSupportsOpeningDocumentsInPlace`) are copies left
  /// in `Documents/Inbox/` that iOS expects the app to clean up.
  private func readSrt(at url: URL) -> [String: Any]? {
    guard url.pathExtension.lowercased() == "srt", let data = try? Data(contentsOf: url) else {
      return nil
    }
    defer { try? FileManager.default.removeItem(at: url) }
    return [
      "name": url.lastPathComponent,
      "bytes": FlutterStandardTypedData(bytes: data),
    ]
  }
}
