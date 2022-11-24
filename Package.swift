// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MQTT-Client",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MQTTClient",
            targets: ["MQTTClient"]
        ),
    ],
    dependencies: [
       .package(url: "https://github.com/qustodio/SocketRocket", branch: "eb9ee252c46bed8e9c05f0bb4610e5fce7a24dbe"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MQTTClient",
            dependencies: [
                "SocketRocket"
            ],
            path: "MQTTClient/MQTTClient"
        )
    ]
)
