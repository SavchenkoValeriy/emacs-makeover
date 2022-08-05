import EmacsSwiftModule
import Cocoa

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
  } catch {
    return 1
  }
  return 0
}
