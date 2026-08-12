import Flutter
import UIKit

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
      case "revealFolder":
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
        DeviceStorageChannel.revealFolder(path: path, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Open [path] in the Files app when possible (map stays unchanged).
  private static func revealFolder(path: String, result: @escaping FlutterResult) {
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
      result(
        FlutterError(code: "NOT_FOUND", message: "Folder not found", details: nil)
      )
      return
    }

    let fileURL = URL(fileURLWithPath: path)

    // Deep-link into Files (same idea as Finder on macOS).
    var components = URLComponents()
    components.scheme = "shareddocuments"
    components.path = fileURL.path

    if let filesURL = components.url {
      UIApplication.shared.open(filesURL, options: [:]) { success in
        if success {
          result(true)
          return
        }
        openFilesAppRoot(result: result)
      }
      return
    }

    openFilesAppRoot(result: result)
  }

  private static func openFilesAppRoot(result: @escaping FlutterResult) {
    guard let root = URL(string: "shareddocuments://") else {
      result(
        FlutterError(
          code: "OPEN_FAILED",
          message: "Could not open the Files app for this folder.",
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
            message: "Could not open the Files app for this folder.",
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
