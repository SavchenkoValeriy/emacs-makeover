import EmacsMakeover
import EmacsSwiftModule
import class EmacsSwiftModule.Environment
import SwiftUI

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
  }
}

class PlaygroundModule: Module {
  let isGPLCompatible = true
  func Init(_ env: Environment) throws {
    let channel = try env.openChannel(name: "UI")

    try env.defun("makeover:add-button-at-point") {
      (env: Environment) -> MakeoverView? in
      let controller = try MakeoverController(env)

      return try controller.addViewAtPoint(
        TrivialButton(channel.callback {
                        (env: Environment) in
                        try env.funcall("message", with: "Button clicked!")
                      }, width: 50, height: try env.lineHeight()),
        within: env,
        adaptive: true)
    }

    try env.defun("makeover:remove-button") {
      (view: MakeoverView) in view.remove()
    }
  }
}

func createModule() -> Module { PlaygroundModule() }
