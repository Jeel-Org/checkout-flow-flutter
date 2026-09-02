#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint checkout_flow_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'checkout_flow_flutter'
  s.version          = '0.3.1'
  s.summary          = 'Flutter integration for Checkout.com Flow and direct wallet payments.'
  s.description      = <<-DESC
Provides native Checkout.com Flow components and direct wallet payment APIs to Flutter applications.
                       DESC
  s.homepage         = 'https://github.com/Jeel-Org/checkout-flow-flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Jeel' => 'engineering@jeel.co' }
  s.source           = {
    :git => 'https://github.com/Jeel-Org/checkout-flow-flutter.git',
    :tag => "v#{s.version}"
  }
  s.source_files = 'checkout_flow_flutter/Sources/checkout_flow_flutter/**/*.swift'
  s.vendored_frameworks = 'Frameworks/CheckoutComponentsSDK.xcframework'
  s.dependency 'Flutter'
  s.dependency 'Risk', '~> 4.0.1'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'checkout_flow_flutter_privacy' => [
      'checkout_flow_flutter/Sources/checkout_flow_flutter/Resources/PrivacyInfo.xcprivacy'
    ]
  }
end
