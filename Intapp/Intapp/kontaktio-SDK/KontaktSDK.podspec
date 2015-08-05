Pod::Spec.new do |s|
  s.name                  = "KontaktSDK"
  s.version               = "5.5"
  s.summary               = "Kontakt.io iOS SDK Library"
  s.homepage              = "http://docs.kontakt.io/ios-sdk/quickstart/"
  s.author                = { "Kontakt.io" => "http://kontakt.io" }
  s.platform              = :ios, '7.0'
  s.source                = { :git => "https://github.com/kontaktio/SDK-iOS.git", :tag => s.version.to_s }
  s.source_files          = 'KontaktSDK/Headers/*.h'
  s.preserve_paths        = 'KontaktSDK/libkontakt-ios-sdk.a'
  s.vendored_libraries    = 'KontaktSDK/libkontakt-ios-sdk.a'
  s.ios.deployment_target = '7.0'
  s.requires_arc          = true
  s.frameworks            = 'UIKit', 'Foundation', 'SystemConfiguration', 'MobileCoreServices', 'CoreBluetooth', 'CoreLocation'
  s.xcconfig              =  { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/KontaktSDK"',
                               'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Headers/KontaktSDK"' }
  s.license      = {
    :type => 'Copyright',
    :text => <<-LICENSE
      Copyright (c) 2015 Kontakt.io. All rights reserved.
      LICENSE
  }
end
