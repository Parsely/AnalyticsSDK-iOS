Pod::Spec.new do |s|
  s.name                   = "ParselyAnalytics"
  s.version                = "0.1.0"
  s.swift_versions         = ["4.2", "5.0", "5.1", "5.2", "5.3", "5.4", "5.5"]
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
end
