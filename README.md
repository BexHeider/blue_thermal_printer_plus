# blue_thermal_printer_plus

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS build system

This plugin supports both CocoaPods and Swift Package Manager (SPM) on iOS.
CocoaPods works out of the box, no setup needed.

To use SPM instead (requires Flutter 3.24+):

```sh
flutter config --enable-swift-package-manager
```

Then run `flutter clean` in your app and rebuild. Flutter picks up
`ios/blue_thermal_printer_plus/Package.swift` automatically — no extra
pubspec configuration needed on the consumer side.

