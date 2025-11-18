import Testing
@testable import ARCIntelligence

struct ARCIntelligenceTests {
    @Test
    func testHelloFunction() {
        #expect(ARCIntelligence.hello() == "Hello from ARCIntelligence!")
    }
}
