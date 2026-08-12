import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var folderAccessChannel: IosFolderAccessChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerNativeChannels(retry: 0)
    return didFinish
  }

  /// `window` can still be nil right after launch on newer iOS — retry briefly.
  private func registerNativeChannels(retry: Int) {
    let controller =
      window?.rootViewController as? FlutterViewController
      ?? topFlutterViewController()

    guard let controller else {
      if retry < 20 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
          self?.registerNativeChannels(retry: retry + 1)
        }
      }
      return
    }

    DeviceStorageChannel.register(with: controller)

    let folderChannel = IosFolderAccessChannel()
    folderChannel.register(with: controller)
    folderAccessChannel = folderChannel
  }

  private func topFlutterViewController() -> FlutterViewController? {
    if let flutter = window?.rootViewController as? FlutterViewController {
      return flutter
    }
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        if let flutter = window.rootViewController as? FlutterViewController {
          return flutter
        }
      }
    }
    return nil
  }
}
