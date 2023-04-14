# frozen_string_literal: true

APP_IOS_DEPLOYMENT_TARGET = Gem::Version.new('13.0')

platform :ios, APP_IOS_DEPLOYMENT_TARGET

abstract_target 'Parsely' do
  use_frameworks!

  pod 'SwiftyJSON', '~> 4.2'

  target 'ParselyDemo'

  target 'ParselyTracker' do
    target 'ParselyTrackerTests' do
      inherit! :search_paths
    end
  end
end

def make_pods_adopt_app_deployment_target(installer:, app_deployment_target:)
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      delopyment_key = 'IPHONEOS_DEPLOYMENT_TARGET'
      pod_deployment_target = Gem::Version.new(configuration.build_settings[delopyment_key])
      configuration.build_settings.delete(delopyment_key) if pod_deployment_target <= app_deployment_target
    end
  end
end

post_install do |installer|
  make_pods_adopt_app_deployment_target(installer: installer, app_deployment_target: APP_IOS_DEPLOYMENT_TARGET)
end
