import XCTest
import EmacsSwiftModule
import Cocoa
import SwiftUI
import class EmacsSwiftModule.Environment

@testable import EmacsMakeover
import CoreGraphics

struct TrivialButton: View {
  let callback: () -> Void
  let width: CGFloat
  let height: CGFloat
  init(_ callback: @escaping () -> Void, width: CGFloat, height: CGFloat) {
    self.callback = callback
    self.width = width
    self.height = height
  }

  var body: some View {
    Button("OK", action: callback)
      .frame(width: width, height: height, alignment: .bottomLeading)
      .border(.blue)
      .allowsHitTesting(true)
  }
}

final class ButtonTest: XCTestCase, MakeoverTestCase {
  var env: Environment! = nil

  @MainActor
  public func testButtonAddition() throws {
    let controller = MakeoverController()

    let channel = try env.openChannel(name: "UI")
    let callback = try env.preserve(env.defun { XCTAssert(false) })

    let button = TrivialButton(channel.callback(callback), width: 30, height: try env.lineHeight())
    let buttonView: MakeoverView! = try controller.addViewAtPoint(button, within: env)
    XCTAssert(buttonView != nil)

    guard let window = try env.window(),
          let cursor = try env.point() else {
      XCTAssert(false)
      return
    }

    let point = window.convertPoint(fromScreen: cursor)
    let expectation = XCTestExpectation(description: "UI modifications")

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
      XCTAssertNotEqual(buttonView.view.window, nil)
      XCTAssertNotEqual(buttonView.view.hitTest(point.applying(CGAffineTransform(translationX: 1, y: 1))), nil)
      controller.removeView(buttonView!)

      XCTAssertEqual(buttonView.view.window, nil)
      XCTAssertEqual(buttonView.view.hitTest(point.applying(CGAffineTransform(translationX: 1, y: 1))), nil)

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)
  }
}
