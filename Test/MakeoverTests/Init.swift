import EmacsSwiftModule
import class EmacsSwiftModule.Environment
import XCTest
import SwiftUI

fileprivate func run(_ test: XCTest, with env: Environment) -> Bool {
  var failed = false
  switch test {
  case let suite as XCTestSuite:
    for test in suite.tests {
      failed = failed || run(test, with: env)
    }
  case let envTest as MakeoverTestCase:
    if let testRun = envTest.testRun {
      envTest.perform(testRun, with: env)
      if !testRun.hasSucceeded {
        failed = true
      }
    }
  case _:
    print("Unknown test: \(test)")
  }
  return failed
}

class MakeoverTestsModule: Module {
  let isGPLCompatible = true
  func Init(_ env: Environment) throws {
    try env.defun("makeover:run-swift-tests") {
      (env: Environment) -> Bool in
      run(XCTestSuite.default, with: env)
    }
  }
}

func createModule() -> Module { MakeoverTestsModule() }
