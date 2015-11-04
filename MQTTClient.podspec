Pod::Spec.new do |s|
  s.name         = "MQTTClient"
  s.version      = "0.3.5"
  s.summary      = "iOS, OSX and tvOS native ObjectiveC MQTT Framework"
  s.homepage     = "https://github.com/ckrey/MQTT-Client-Framework"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Christoph Krey" => "krey.christoph@gmail.com" }
  s.source       = { :git => "https://github.com/ckrey/MQTT-Client-Framework.git", :tag => "0.3.5" }

  s.source_files = "MQTTClient/MQTTClient", "MQTTClient/MQTTClient/**/*.{h,m}"
  s.requires_arc = true

  s.platform = :ios, "6.1", :osx, "10.10", :tvos, "9.0"

  s.ios.deployment_target = "6.1"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"
end
