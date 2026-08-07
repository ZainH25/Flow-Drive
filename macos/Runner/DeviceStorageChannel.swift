import Cocoa
import FlutterMacOS

final class DeviceStorageChannel {
  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "flow_drive/device_storage",
      binaryMessenger: controller.engine.binaryMessenger
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
    guard
      let values = try? URL(fileURLWithPath: NSHomeDirectory())
        .resourceValues(forKeys: [.volumeTotalCapacityKey]),
      let total = values.volumeTotalCapacity
    else {
      return 0
    }
    return Double(total) / (1024 * 1024)
  }

  private static func freeDiskSpaceInMB() -> Double {
    guard
      let values = try? URL(fileURLWithPath: NSHomeDirectory())
        .resourceValues(forKeys: [.volumeAvailableCapacityKey]),
      let free = values.volumeAvailableCapacity
    else {
      return 0
    }
    return Double(free) / (1024 * 1024)
  }
}
