// swift-tools-version:5.3

//   /\/\__/\/\
//   \/\/..\/\/
//      (oo)
//  MooseFactory
//    Software

import PackageDescription

let package = Package(
    name: "MFRemotes",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MFRemotes",
            targets: ["MFRemotes"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MFRemotes"),
        .testTarget(
            name: "MFRemotesTests",
            dependencies: ["MFRemotes"]
        ),
    ]
)
