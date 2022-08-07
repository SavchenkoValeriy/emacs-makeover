// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "emacs-makeover",
  platforms: [.macOS(.v11)],
  products: [
    .library(
      name: "Makeover",
      type: .dynamic,
      targets: ["EmacsMakeover"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SavchenkoValeriy/emacs-swift-module.git", from: "1.1.0"),
  ],
  targets: [
    .target(
      name: "EmacsMakeover",
      dependencies: [.product(name: "EmacsSwiftModule", package: "emacs-swift-module")]),
    .testTarget(
      name: "MakeoverTests",
      dependencies: [
        "EmacsMakeover",
        .product(name: "EmacsSwiftModule", package: "emacs-swift-module")
      ]),
  ]
)
