import Flutter
import UIKit
import UniformTypeIdentifiers

/// Picks a folder via the Files app, keeps security-scoped access long enough
/// to mirror its contents into the app sandbox, then returns a local path
/// Dart can browse with normal Directory APIs (same as Android).
final class IosFolderAccessChannel: NSObject, UIDocumentPickerDelegate {
  private static let channelName = "flow_drive/ios_folder_access"
  private static let maxFolders = 220
  private static let maxFiles = 800
  private static let maxDepth = 10

  private var pendingResult: FlutterResult?
  private weak var presenter: UIViewController?
  private var methodChannel: FlutterMethodChannel?

  func register(with controller: FlutterViewController) {
    presenter = controller
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: controller.binaryMessenger
    )
    methodChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "gone", message: "Channel disposed", details: nil))
        return
      }
      switch call.method {
      case "pickFolder":
        self.pickFolder(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func pickFolder(result: @escaping FlutterResult) {
    if pendingResult != nil {
      result(FlutterError(code: "busy", message: "A folder picker is already open", details: nil))
      return
    }
    pendingResult = result

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    picker.modalPresentationStyle = .formSheet

    guard let host = presenter ?? topViewController() else {
      finish(FlutterError(code: "no_ui", message: "No view controller to present picker", details: nil))
      return
    }
    host.present(picker, animated: true)
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let sourceURL = urls.first else {
      finish(nil)
      return
    }

    let accessing = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let mirrored = try mirrorFolder(from: sourceURL)
      GraphMapMirrorRegistry.register(mirrorRootPath: mirrored.path, sourceURL: sourceURL)
      finish([
        "path": mirrored.path,
        "name": sourceURL.lastPathComponent,
      ])
    } catch {
      finish(
        FlutterError(
          code: "mirror_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func mirrorFolder(from sourceURL: URL) throws -> URL {
    let fm = FileManager.default
    let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
      .appendingPathComponent("GraphMap", isDirectory: true)
    try fm.createDirectory(at: base, withIntermediateDirectories: true)

    if let existing = try? fm.contentsOfDirectory(at: base, includingPropertiesForKeys: nil) {
      for url in existing {
        try? fm.removeItem(at: url)
      }
    }

    let destRoot = base
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
      .appendingPathComponent(sourceURL.lastPathComponent, isDirectory: true)
    try fm.createDirectory(at: destRoot, withIntermediateDirectories: true)

    var folderCount = 0
    var fileCount = 0
    try copyContents(
      from: sourceURL,
      to: destRoot,
      depth: 0,
      folderCount: &folderCount,
      fileCount: &fileCount
    )
    return destRoot
  }

  private func copyContents(
    from sourceDir: URL,
    to destDir: URL,
    depth: Int,
    folderCount: inout Int,
    fileCount: inout Int
  ) throws {
    if depth > Self.maxDepth { return }
    if folderCount >= Self.maxFolders { return }

    let fm = FileManager.default
    let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .nameKey]
    guard let entries = try? fm.contentsOfDirectory(
      at: sourceDir,
      includingPropertiesForKeys: keys,
      options: [.skipsHiddenFiles]
    ) else {
      return
    }

    for entry in entries {
      if folderCount >= Self.maxFolders { break }
      if fileCount >= Self.maxFiles { break }

      let values = try? entry.resourceValues(forKeys: Set(keys))
      let name = values?.name ?? entry.lastPathComponent
      if name.hasPrefix(".") { continue }

      if values?.isDirectory == true {
        folderCount += 1
        let childDest = destDir.appendingPathComponent(name, isDirectory: true)
        try fm.createDirectory(at: childDest, withIntermediateDirectories: true)
        try copyContents(
          from: entry,
          to: childDest,
          depth: depth + 1,
          folderCount: &folderCount,
          fileCount: &fileCount
        )
      } else if values?.isRegularFile == true {
        fileCount += 1
        let childDest = destDir.appendingPathComponent(name, isDirectory: false)
        if fm.fileExists(atPath: childDest.path) {
          try fm.removeItem(at: childDest)
        }
        try fm.copyItem(at: entry, to: childDest)
      }
    }
  }

  private func finish(_ value: Any?) {
    pendingResult?(value)
    pendingResult = nil
  }
}
