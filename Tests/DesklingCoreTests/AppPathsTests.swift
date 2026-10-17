import XCTest
@testable import DesklingCore

final class AppPathsTests: XCTestCase {
    private let home = URL(fileURLWithPath: "/Users/me")

    func testDirectories() {
        XCTAssertEqual(AppPaths.supportDirectory(home: home).path, "/Users/me/Library/Application Support/Deskling Pet")
        XCTAssertEqual(AppPaths.skinsDirectory(home: home).path, "/Users/me/Library/Application Support/Deskling Pet/skins")
    }
}
