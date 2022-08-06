import EmacsSwiftModule
import Cocoa
import SwiftUI
import class EmacsSwiftModule.Environment

extension NSView: OpaquelyEmacsConvertible {}

struct MyButton: View {
  let callback: () -> Void
  init(_ callback: @escaping () -> Void) {
    self.callback = callback
  }

  var body: some View {
    Button("OK", action: callback)
      .frame(width: 100.0)
  }
}

@_cdecl("plugin_is_GPL_compatible")
public func isGPLCompatible() {}

@_cdecl("emacs_module_init")
public func Init(_ runtimePtr: RuntimePointer) -> Int32 {
  let env = Environment(from: runtimePtr)
  do {
    try env.funcall("message", with: "Hello, Emacs!")
    try env.defun("makeover-numer-of-windows") {
      NSApp.windows.map { $0.windowNumber }
    }
    try env.defun("makeover-current-window") {
      (env: Environment) throws -> Int in
      let window = try env.window()
      return window?.windowNumber ?? 0
    }
    try env.defun("makeover-current-position") {
      (env: Environment) throws in
      try env.funcall("message", with: "%S", env.point())
    }
    let channel = try env.openChannel(name: "UI")
    try env.defun("makeover-add-button") {
      (env: Environment,
       callback: PersistentEmacsValue) throws -> NSView? in
      guard let window = try env.window() else {
        return nil
      }
      let newView = NSHostingView(rootView: MyButton(channel.callback(callback)))
      if let view = window.contentView {
        view.addSubview(newView)
        let point = try window.convertPoint(fromScreen: env.point())
        newView.frame = NSMakeRect(point.x, point.y, 0, 0)
      } else {
        return nil
      }
      return newView
    }
    try env.defun("makeover-remove-button") {
      (button: NSView) in
      button.removeFromSuperview()
    }
  } catch {
    return 1
  }
  return 0
}
