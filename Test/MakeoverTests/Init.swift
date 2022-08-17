import EmacsSwiftModule
import class EmacsSwiftModule.Environment
import XCTest
import SwiftUI

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() {}

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

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
  let env = Environment(from: runtimePtr)
  do {
    try env.defun("makeover:run-swift-tests") {
      (env: Environment) -> Bool in
      try env.funcall("message", with: "Hello from Swift tests!")
      return run(XCTestSuite.default, with: env)
    }
  } catch {
    return 1
  }
  return 0
}
