#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pos_printer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pos_printer'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for POS thermal printers.'
  s.description      = <<-DESC
A Flutter plugin for connecting and printing to POS thermal printers via Bluetooth, USB, or Network.
                       DESC
  s.homepage         = 'https://github.com/example/pos_printer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
