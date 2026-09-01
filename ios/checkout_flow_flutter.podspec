#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint checkout_flow_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'checkout_flow_flutter'
  s.version          = '0.2.0'
  s.summary          = 'Flutter integration for Checkout.com Flow and direct wallet payments.'
  s.description      = <<-DESC
Flutter integration for Checkout.com Flow and direct wallet payments.
                       DESC
  s.homepage         = 'https://github.com/Jeel-Org/checkout-flow-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jeel' => 'engineering@jeel.co' }
  s.source           = { :path => '.' }
  s.source_files = 'checkout_flow_flutter/Sources/checkout_flow_flutter/**/*'
  s.vendored_frameworks = 'Frameworks/CheckoutComponentsSDK.xcframework'
  s.dependency 'Flutter'
  s.dependency 'Risk', '~> 4.0.1'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'checkout_flow_flutter_privacy' => ['checkout_flow_flutter/Sources/checkout_flow_flutter/PrivacyInfo.xcprivacy']}
end
