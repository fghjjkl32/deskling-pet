import DesklingCore
import Foundation

enum Resources {
    /// `DESKLING_RESOURCES` points at the repository's Resources folder when running with `swift run`.
    static var root: URL {
        if let override = ProcessInfo.processInfo.environment["DESKLING_RESOURCES"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return Bundle.main.resourceURL ?? Bundle.main.bundleURL
    }

    /// The skin used when none is chosen, or when the chosen one cannot be loaded.
    static var defaultSkinDirectory: URL { bundledSkinDirectory("boy") }

    /// The skins that ship with the app, in menu order: the first one is the default.
    static let bundledSkins: [(id: String, name: Text)] = [("boy", .boySkin), ("girl", .girlSkin)]

    static func bundledSkinDirectory(_ id: String) -> URL {
        root.appendingPathComponent("skins/\(id)", isDirectory: true)
    }
}
