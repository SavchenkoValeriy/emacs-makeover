import EmacsSwiftModule
import Cocoa

extension NSPoint: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.funcall("cons", with: Int(x), Int(y))
  }

  public static func convert(from: EmacsValue, within env: Environment) throws -> CGPoint {
    let x: Int = try env.funcall("car", with: from)
    let y: Int = try env.funcall("cdr", with: from)
    return NSMakePoint(CGFloat(x), CGFloat(y))
  }
}

extension NSRect: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.funcall("list", with: Int(minX), Int(minY), Int(maxX), Int(maxY))
  }

  public static func convert(from: EmacsValue, within env: Environment) throws -> CGRect {
    var points = [CGFloat]()
    var list = from
    for _ in 0..<4 {
      let car: Int = try env.funcall("car", with: list)
      points.append(CGFloat(car))
      list = try env.funcall("cdr", with: list)
    }
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

  public func point(from position: EmacsValue? = nil) throws -> NSPoint {
    let internalPoint: NSPoint = try funcall("window-absolute-pixel-position", with: position)
    guard let screen = try window()?.screen else {
      // Should we return this when we don't have a screen?
      return internalPoint
    }
    return try NSMakePoint(internalPoint.x, screen.frame.size.height - internalPoint.y - lineHeight())
  }

  public func lineHeight() throws -> CGFloat {
    CGFloat(try funcall("line-pixel-height") as Int)
  }

  public func windowRect() throws -> NSRect {
    try funcall("window-absolute-pixel-edges")
  }

  public func window() throws -> NSWindow? {
    let frames: [EmacsValue] = try funcall("vconcat", with: funcall("ns-frame-list-z-order"))
    let selectedId = try frameId(funcall("selected-frame"))
    let frameIds = try frames.map { try frameId($0) }

    if NSApp.orderedWindows.count != frames.count {
      throw EmacsError.customError(message: "Unexpected number of frames")
    }

    return zip(NSApp.orderedWindows, frameIds)
      .first { $0.1 == selectedId }?.0
  }
}
