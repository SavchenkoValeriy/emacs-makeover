import EmacsSwiftModule
import Cocoa

extension Environment {
  public func frameId(_ frame: EmacsValue) throws -> Int {
    let raw: String = try funcall("frame-parameter", with: frame, intern("window-id"))
    if let result = Int(raw) {
      return result
    }
    throw EmacsError.customError(message: "window-id should be a number")
  }

  public func window() throws -> NSWindow? {
    let frames: [EmacsValue] = try funcall("vconcat", with: funcall("ns-frame-list-z-order"))
    let selectedId = try frameId(funcall("selected-frame"))
    let frameIds = try frames.map { try frameId($0) }
    for (window, frameId) in zip(NSApp.orderedWindows.reversed(), frameIds) {
      if frameId == selectedId {
        return window
      }
    }
    return nil
  }
}
