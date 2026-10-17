import Foundation

public enum AppPaths {
    public static func supportDirectory(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        home.appendingPathComponent("Library/Application Support/Deskling Pet", isDirectory: true)
    }

    public static func skinsDirectory(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        supportDirectory(home: home).appendingPathComponent("skins", isDirectory: true)
    }
}
