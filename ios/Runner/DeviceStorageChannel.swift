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
      default:
        result(FlutterMethodNotImplemented)
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
