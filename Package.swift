// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

var platformDir: String? {
    ProcessInfo.processInfo.environment["PLATFORM_DIR"]
}

var products: [Product] = [
  .library(
    name: "Makeover",
    targets: ["EmacsMakeover"]),
]

var targets: [Target] = [
  .target(
    name: "EmacsMakeover",
    dependencies: [.product(name: "EmacsSwiftModule", package: "emacs-swift-module")])
]

if let platformDir = platformDir {
  products.append(
    .library(
      name: "MakeoverTests",
      type: .dynamic,
      targets: ["MakeoverTests"])
  )
  targets.append(
    .target(
      name: "MakeoverTests",
      dependencies: [
        "EmacsMakeover",
        .product(name: "EmacsSwiftModule", package: "emacs-swift-module")
      ],
      path: "Test/MakeoverTests",
      linkerSettings: [.linkedFramework("XCTest"),
                       .unsafeFlags(
                         ["-Xlinker", "-rpath", "-Xlinker", "\(platformDir)/Developer/usr/lib",
                          "-Xlinker", "-rpath", "-Xlinker", "\(platformDir)/Developer/Library/Frameworks"])]
    )
  )
}

let package = Package(
  name: "emacs-makeover",
  platforms: [.macOS(.v11)],
  products: products,
  dependencies: [
    .package(url: "https://github.com/SavchenkoValeriy/emacs-swift-module.git", from: "1.1.0"),
  ],
  targets: targets
)
