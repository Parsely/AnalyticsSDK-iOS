Pod::Spec.new do |s|
  s.name                   = "ParselyAnalytics"
  s.version                = "0.0.10"
  s.swift_version          = "4.2"
  s.summary                = "Parsely analytics integration for iOS"
  s.homepage               = "https://www.parse.ly/help/integration/ios-sdk/"
  s.license                = "Apache License, Version 2.0"
  s.author                 = { "Emmett Butler" => "emmett@parsely.com" }
  s.ios.deployment_target  = "10.0"
  s.tvos.deployment_target = "10.0"
  s.source                 = { :git => "https://github.com/Parsely/AnalyticsSDK-iOS.git", :tag => "#{s.version}" }
  s.source_files           = "ParselyTracker"
  s.framework              = 'Foundation'
  s.dependency               'SwiftyJSON', '~> 4.2'
  s.dependency               'ReachabilitySwift', '~> 4.3'
end
