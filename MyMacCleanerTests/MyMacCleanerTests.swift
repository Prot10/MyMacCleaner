import Testing
@testable import MyMacCleaner

@Suite("MyMacCleaner Tests")
struct MyMacCleanerTests {

    @Test("App launches successfully")
    func appLaunches() async throws {
        // Basic test to verify app compiles
        #expect(true)
    }

    @Test("Navigation sections are defined")
    func navigationSectionsDefined() async throws {
        let sections = NavigationSection.allCases
        #expect(sections.count == 6)
        #expect(sections.contains(.home))
        #expect(sections.contains(.diskCleaner))
        #expect(sections.contains(.performance))
        #expect(sections.contains(.applications))
        #expect(sections.contains(.portManagement))
        #expect(sections.contains(.systemHealth))
    }
}
