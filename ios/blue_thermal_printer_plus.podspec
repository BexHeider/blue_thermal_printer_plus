#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint blue_thermal_printer_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'blue_thermal_printer_plus'
  s.version          = '0.2.0'
  s.summary          = 'Impresión Bluetooth en impresoras térmicas (ESC/POS, ZPL, CPCL).'
  s.description      = <<-DESC
Plugin de Flutter para imprimir texto, imágenes, QR y códigos de barras en impresoras térmicas Bluetooth.
                       DESC
  s.homepage         = 'https://github.com/BexHeider/blue_thermal_printer_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Bex Soluciones' => 'heider.zapa@bexsoluciones.com' }
  s.source           = { :path => '.' }
  s.source_files = 'blue_thermal_printer_plus/Sources/blue_thermal_printer_plus/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'blue_thermal_printer_plus_privacy' => ['blue_thermal_printer_plus/Sources/blue_thermal_printer_plus/Resources/PrivacyInfo.xcprivacy']}
end
