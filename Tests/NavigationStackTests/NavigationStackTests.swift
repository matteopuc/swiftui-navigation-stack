import XCTest
@testable import NavigationStack

final class NavigationStackTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NavigationStack().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
