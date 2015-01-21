Pod::Spec.new do |s|
  s.name         = "MQTTClient"
  s.version      = "0.0.1"
  s.summary      = "IOS native ObjectiveC MQTT Framework"
  s.homepage     = "https://github.com/ckrey/MQTT-Client-Framework"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Christoph Krey" => "krey.christoph@gmail.com" }
  s.source       = { :git => "https://github.com/ckrey/MQTT-Client-Framework.git", :tag => "0.0.1" }

  s.source_files = "MQTTClient/MQTTClient", "MQTTClient/MQTTClient/**/*.{h,m}"
  s.requires_arc = true

  s.ios.deployment_target = "7.0"
end
