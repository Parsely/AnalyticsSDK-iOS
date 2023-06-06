# frozen_string_literal: true

Pod::Spec.new do |s|
  s.name                   = 'ParselyAnalytics'
  s.version                = '0.2.3-beta2'
  s.swift_versions         = ['4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5']
  s.summary                = 'Parsely analytics integration for iOS'
  s.homepage               = 'https://www.parse.ly/help/integration/ios-sdk/'
  s.license                = 'Apache License, Version 2.0'
  s.author                 = { 'Emmett Butler' => 'emmett@parsely.com' }
  s.ios.deployment_target  = '13.0'
  s.tvos.deployment_target = '13.0'
  s.source                 = { git: 'https://github.com/Parsely/AnalyticsSDK-iOS.git', tag: s.version.to_s }
  s.source_files           = 'Sources'
  s.framework              = 'Foundation'
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests'
    test_spec.dependency 'Nimble'
  end
end
