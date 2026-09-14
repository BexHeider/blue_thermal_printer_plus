// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "blue_thermal_printer_plus",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "blue-thermal-printer-plus", targets: ["blue_thermal_printer_plus"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "blue_thermal_printer_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [.process("Resources")]
        )
    ]
)
