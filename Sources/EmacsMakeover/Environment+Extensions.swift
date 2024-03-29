import EmacsSwiftModule
import Cocoa

extension NSPoint: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try ConsCell(car: Int(x), cdr: Int(y)).convert(within: env)
  }

  public static func convert(from value: EmacsValue, within env: Environment) throws -> CGPoint {
    let cons = try ConsCell<Int, Int>.convert(from: value, within: env)
    return NSMakePoint(CGFloat(cons.car), CGFloat(cons.cdr))
  }
}

extension NSRect: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.funcall("list", with: Int(minX), Int(minY), Int(maxX), Int(maxY))
  }

  public static func convert(from value: EmacsValue, within env: Environment) throws -> CGRect {
    let points = try List<Int>.convert(from: value, within: env).map { CGFloat($0) }
    return NSRect(x: points[0], y: points[1], width: points[2] - points[0], height: points[3] - points[1])
  }
}

extension Environment {
  public func frameId(_ frame: EmacsValue) throws -> Int {
    let raw: String = try funcall("frame-parameter", with: frame, intern("window-id"))
    if let result = Int(raw) {
      return result
    }
    throw EmacsError.customError(message: "window-id should be a number")
  }

  public func point() throws -> EmacsValue {
    try funcall("point")
  }

  public func position(from position: EmacsValue? = nil) throws -> NSPoint? {
    let internalPoint: NSPoint? = try funcall("window-absolute-pixel-position", with: position)
    guard let screen = try window()?.screen else {
      // Should we return this when we don't have a screen?
      return internalPoint
    }
    guard let point = internalPoint else {
      return nil
    }
    return try NSMakePoint(point.x, screen.frame.size.height - point.y - lineHeight())
  }

  public func lineHeight() throws -> CGFloat {
    CGFloat(try funcall("line-pixel-height") as Int)
  }

  public func windowRect() throws -> NSRect {
    try funcall("window-absolute-pixel-edges")
  }

  public func window(_ frame: EmacsValue? = nil) throws -> NSWindow? {
    let frame = try frame ?? funcall("selected-frame")
    let frames: [EmacsValue] = try funcall("vconcat", with: funcall("ns-frame-list-z-order"))
    let selectedId = try frameId(frame)
    let frameIds = try frames.map { try frameId($0) }

    let windows = NSApp.orderedWindows.filter {
      win in
      win.delegate.map { String(describing: $0).contains("EmacsView") } ?? false
    }

    if windows.count != frames.count {
      throw EmacsError.customError(message: "Unexpected number of frames")
    }

    return zip(NSApp.orderedWindows, frameIds)
      .first { $0.1 == selectedId }?.0
  }
}
