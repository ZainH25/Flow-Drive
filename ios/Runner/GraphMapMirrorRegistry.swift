import Foundation

/// Maps mirrored GraphMap cache paths back to the user's original security-scoped folder URLs.
enum GraphMapMirrorRegistry {
  private static let storageKey = "flow_drive_graph_map_mirrors"

  static func register(mirrorRootPath: String, sourceURL: URL) {
    guard !mirrorRootPath.isEmpty else { return }
    guard let bookmark = try? sourceURL.bookmarkData(
      options: .minimalBookmark,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    ) else {
      return
    }

    var mirrors = loadMirrors()
    mirrors[mirrorRootPath] = bookmark.base64EncodedString()
    saveMirrors(mirrors)
  }

  /// Resolves [path] to the original picked URL when it lives under a mirrored GraphMap root.
  static func resolveURL(for path: String) -> URL? {
    let mirrors = loadMirrors()
    let sortedRoots = mirrors.keys.sorted { $0.count > $1.count }

    for mirrorRoot in sortedRoots {
      guard path == mirrorRoot || path.hasPrefix(mirrorRoot + "/") else { continue }
      guard let encoded = mirrors[mirrorRoot],
            let bookmark = Data(base64Encoded: encoded) else {
        continue
      }

      var stale = false
      guard let rootURL = try? URL(
        resolvingBookmarkData: bookmark,
        options: .withoutUI,
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      ) else {
        continue
      }

      guard rootURL.startAccessingSecurityScopedResource() else { continue }

      let relative: String
      if path == mirrorRoot {
        relative = ""
      } else {
        relative = String(path.dropFirst(mirrorRoot.count + 1))
      }

      if relative.isEmpty {
        return rootURL
      }
      return rootURL.appendingPathComponent(relative)
    }

    return nil
  }

  private static func loadMirrors() -> [String: String] {
    UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] ?? [:]
  }

  private static func saveMirrors(_ mirrors: [String: String]) {
    UserDefaults.standard.set(mirrors, forKey: storageKey)
  }
}
