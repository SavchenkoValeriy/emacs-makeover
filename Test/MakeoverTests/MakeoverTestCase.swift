import EmacsSwiftModule
import XCTest

protocol MakeoverTestCase: XCTest {
  var env: Environment! { get set }
  func perform(_ run: XCTestRun, with env: Environment)
}

extension MakeoverTestCase {
  func perform(_ run: XCTestRun, with env: Environment) {
    self.env = env
    self.perform(run)
  }
}
