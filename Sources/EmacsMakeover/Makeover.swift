import EmacsSwiftModule
import Cocoa
import SwiftUI
import class EmacsSwiftModule.Environment

extension NSView: OpaquelyEmacsConvertible {}

class MakeoverView: OpaquelyEmacsConvertible {
  public let view: NSView
  var removed = false

  public func remove() {
    _ = Unmanaged.passRetained(view)
    view.removeFromSuperview()
    removed = true
  }

  fileprivate init(view: NSView) {
    self.view = view
  }

  deinit {
    if removed {
      Unmanaged.passUnretained(view).release()
    }
  }
}

class MakeoverController {
  func addViewAtPoint<T: View>(_ toAdd: T, within env: Environment, `where` location: EmacsValue? = nil) throws -> MakeoverView? {
    guard let window = try env.window(),
          let screenPoint = try env.point(from: location),
          let view = window.contentView else {
      return nil
    }

    let point = window.convertPoint(fromScreen: screenPoint)
    let result = NSHostingView(rootView: toAdd)

    view.addSubview(result)

    // Customize positioning
    result.translatesAutoresizingMaskIntoConstraints = false
    result.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -point.y).isActive = true
    result.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: point.x).isActive = true

    return MakeoverView(view: result)
  }
  func removeView(_ view: MakeoverView) {
    view.remove()
  }
}
