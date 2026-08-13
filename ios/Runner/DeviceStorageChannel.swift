import Flutter
import UIKit
import QuickLook

final class DeviceStorageChannel {
  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "flow_drive/device_storage",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getStorageInfo":
        let totalMb = DeviceStorageChannel.totalDiskSpaceInMB()
        let freeMb = DeviceStorageChannel.freeDiskSpaceInMB()
        result([
          "totalMb": totalMb,
          "freeMb": freeMb,
        ])
      case "revealFolder", "revealPath":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          !path.isEmpty
        else {
          result(
            FlutterError(code: "INVALID", message: "path is required", details: nil)
          )
          return
        }
        revealPath(path: path, host: controller, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Open [path] in Files / the default app (map stays unchanged).
  private static func revealPath(
    path: String,
    host: UIViewController,
    result: @escaping FlutterResult
  ) {
    if let originalURL = GraphMapMirrorRegistry.resolveURL(for: path) {
      openResolvedURL(originalURL, host: host, result: result)
      return
    }

    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else {
      result(
        FlutterError(code: "NOT_FOUND", message: "Path not found", details: nil)
      )
      return
    }

    let fileURL = URL(fileURLWithPath: path, isDirectory: isDir.boolValue)
    openResolvedURL(fileURL, host: host, result: result)
  }

  private static func openResolvedURL(
    _ url: URL,
    host: UIViewController,
    result: @escaping FlutterResult
  ) {
    var isDir: ObjCBool = false
    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

    if isDir.boolValue {
      UIApplication.shared.open(url, options: [:]) { success in
        if success {
          result(true)
          return
        }
        openFilesAppRoot(result: result)
      }
      return
    }

    QuickLookPreview.present(url: url, from: host, result: result)
  }

  private static func openFilesAppRoot(result: @escaping FlutterResult) {
    guard let root = URL(string: "shareddocuments://") else {
      result(
        FlutterError(
          code: "OPEN_FAILED",
          message: "Could not open the Files app for this path.",
          details: nil
        )
      )
      return
    }
    UIApplication.shared.open(root, options: [:]) { success in
      if success {
        result(true)
      } else {
        result(
          FlutterError(
            code: "OPEN_FAILED",
            message: "Could not open the Files app for this path.",
            details: nil
          )
        )
      }
    }
  }

  private static func totalDiskSpaceInMB() -> Double {
    Double(totalDiskSpaceInBytes()) / (1024 * 1024)
  }

  private static func freeDiskSpaceInMB() -> Double {
    Double(freeDiskSpaceInBytes()) / (1024 * 1024)
  }

  private static func totalDiskSpaceInBytes() -> Int64 {
    guard
      let attributes = try? FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      ),
      let size = (attributes[.systemSize] as? NSNumber)?.int64Value
    else {
      return 0
    }
    return size
  }

  private static func freeDiskSpaceInBytes() -> Int64 {
    if #available(iOS 11.0, *) {
      if let space = try? URL(fileURLWithPath: NSHomeDirectory())
        .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        .volumeAvailableCapacityForImportantUsage {
        return space
      }
      return 0
    }

    guard
      let attributes = try? FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      ),
      let free = (attributes[.systemFreeSize] as? NSNumber)?.int64Value
    else {
      return 0
    }
    return free
  }
}

private final class QuickLookPreview: NSObject, QLPreviewControllerDataSource {
  private static var shared = QuickLookPreview()
  private var url: URL?
  private var flutterResult: FlutterResult?

  static func present(url: URL, from host: UIViewController, result: @escaping FlutterResult) {
    shared.url = url
    shared.flutterResult = result
    let preview = QLPreviewController()
    preview.dataSource = shared
    host.present(preview, animated: true) {
      shared.flutterResult?(true)
      shared.flutterResult = nil
    }
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    url == nil ? 0 : 1
  }

  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> QLPreviewItem {
    url! as NSURL
  }
}
