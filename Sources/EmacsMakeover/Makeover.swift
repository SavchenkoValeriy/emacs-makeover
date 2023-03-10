import EmacsSwiftModule
import Cocoa
import SwiftUI
import class EmacsSwiftModule.Environment

extension NSView: OpaquelyEmacsConvertible {}

public class MakeoverView: OpaquelyEmacsConvertible {
  public let view: NSView
  var removed = false
  public var message: (String) -> () = { x in }
  var bottom: NSLayoutConstraint? = nil
  var leading: NSLayoutConstraint? = nil

  public func remove() {
    _ = Unmanaged.passRetained(view)
    view.removeFromSuperview()
    removed = true
  }

  fileprivate func position(at point: NSPoint) throws {
    guard !removed else {
      throw EmacsError.customError(message: "Trying to reposition a removed component")
    }

    let parent = view.superview!

    // Customize positioning
    view.translatesAutoresizingMaskIntoConstraints = false
    view.wantsLayer = true

    if view.constraints.count == 0 {
      bottom = view.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -point.y)
      bottom!.isActive = true
      leading = view.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: point.x)
      leading!.isActive = true
    } else {
      bottom?.constant  = -point.y
      leading?.constant = point.x
      view.needsUpdateConstraints = true
    }
    // parent.layoutSubtreeIfNeeded()
    // parent.layout()
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

class MakeoverBufferView: MakeoverView {
  public let point: PersistentEmacsValue
  private var onRemove: () -> ()

  fileprivate init(view: NSView,
                   point: EmacsValue,
                   within env: Environment,
                   channel: Channel) throws {
    self.point = try env.preserve(point)
    onRemove = {}
    super.init(view: view)

    let buffer: PersistentEmacsValue = try env.funcall("current-buffer")

    let onScroll = try env.preserve(
      env.defun {
        (env: Environment, emacsWindow: EmacsValue, _: EmacsValue) throws in
        // Emacs window is not an actual window, we need to get a frame from it.
        let frame = try env.funcall("window-frame", with: emacsWindow)
        guard let window = try env.window(frame) else {
          return
        }

        guard let screenPoint = try env.position(from: self.point) else {
          view.isHidden = true
          return
        }

        let point = window.convertPoint(fromScreen: screenPoint)
        view.isHidden = false
        try self.position(at: point)
      })
    let windowScrollFunctions: PersistentEmacsValue = try env.funcall("make-local-variable",
                                                with: Symbol(name: "window-scroll-functions"))
    try env.funcall("add-to-list", with: windowScrollFunctions, onScroll)

    onRemove = channel.callback {
      env throws in
      let currentBuffer = try env.funcall("current-buffer")
      try env.funcall("set-buffer", with: buffer)
      defer {
        try! env.funcall("set-buffer", with: currentBuffer)
      }

      let scrollFunctions = try env.funcall("symbol-value", with: windowScrollFunctions)
      let newScrollFunctions = try env.funcall("remq", with: onScroll, scrollFunctions)
      try env.funcall("set", with: windowScrollFunctions, newScrollFunctions)
    }
  }

  override public func remove() {
    super.remove()
    onRemove()
  }
}

public class MakeoverController {
  private let channel: Channel

  public init(_ env: Environment) throws {
    channel = try env.openChannel(name: "MakeoverController")
  }

  public func addViewAtPoint<T: View>(_ toAdd: T, within env: Environment,
                                      `where` location: EmacsValue? = nil,
                                      adaptive: Bool = false) throws -> MakeoverView? {
    let bufferPoint = try location ?? env.point()

    guard let window = try env.window(),
          let screenPoint = try env.position(from: bufferPoint),
          let view = window.contentView else {
      return nil
    }

    let point = window.convertPoint(fromScreen: screenPoint)
    let actualView = NSHostingView(rootView: toAdd)

    view.addSubview(actualView)

    let result = try MakeoverBufferView(view: actualView,
                                        point: bufferPoint,
                                        within: env,
                                        channel: channel)
    // Temporary debugging solution
    result.message = channel.callback {
      env, message in try! env.funcall("message", with: message)
    }
    try result.position(at: point)

    if adaptive {
    }
    return result
  }
  public func removeView(_ view: MakeoverView) {
    view.remove()
  }
}
