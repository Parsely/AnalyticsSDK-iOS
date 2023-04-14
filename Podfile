# frozen_string_literal: true

APP_IOS_DEPLOYMENT_TARGET = Gem::Version.new('13.0')

platform :ios, APP_IOS_DEPLOYMENT_TARGET

target 'ParselyDemo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftyJSON', '~> 4.2'
end

target 'ParselyTracker' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ParselyTracker
  pod 'SwiftyJSON', '~> 4.2'
  target 'ParselyTrackerTests' do
    inherit! :search_paths
    # Pods for testing
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
