Pod::Spec.new do |mqttc|
	mqttc.name         = "MQTTClient"
	mqttc.version      = "0.6.0"
	mqttc.summary      = "iOS, OSX and tvOS native ObjectiveC MQTT Client Framework"
	mqttc.homepage     = "https://github.com/ckrey/MQTT-Client-Framework"
	mqttc.license      = { :type => "EPLv1", :file => "LICENSE" }
	mqttc.author       = { "Christoph Krey" => "krey.christoph@gmail.com" }
	mqttc.source       = {
		:git => "https://github.com/ckrey/MQTT-Client-Framework.git",
		:tag => "0.6.0",
		:submodules => true
	}

	mqttc.requires_arc = true
	mqttc.platform = :ios, "6.1", :osx, "10.10", :tvos, "9.0"
	mqttc.ios.deployment_target = "6.1"
	mqttc.osx.deployment_target = "10.10"
	mqttc.tvos.deployment_target = "9.0"
	mqttc.default_subspec = 'Classic'
	mqttc.compiler_flags = '-DLUMBERJACK'

	mqttc.subspec 'Classic' do |classic|
		classic.dependency 'MQTTClient/Core'
		classic.dependency 'MQTTClient/SSLSecurityPolicy'
		classic.dependency 'MQTTClient/CoreData'
	end

	mqttc.subspec 'Core' do |core|
		core.source_files =	"MQTTClient/MQTTClient",
					"MQTTClient/MQTTClient/*.{h,m}",
					"MQTTClient/MQTTClient/MQTTInMemoryPersistence/*.{h,m}"
		core.dependency 'CocoaLumberjack'
	end

	mqttc.subspec 'CoreData' do |coredata|
		coredata.source_files = "MQTTClient/MQTTClient/MQTTCoreDataPersistence/*.{h,m}"
		coredata.dependency 'MQTTClient/Core'
	end

	mqttc.subspec 'SSLSecurityPolicy' do |secpol|
		secpol.source_files = "MQTTClient/MQTTClient/MQTTSSLSecurityPolicyTransport/*.{h,m}"
		secpol.dependency 'MQTTClient/Core'
	end

	mqttc.subspec 'Websocket' do |ws|
		ws.source_files = "MQTTClient/MQTTClient/MQTTWebsocketTransport/*.{h,m}"
		ws.dependency 'SocketRocket'
		ws.dependency 'MQTTClient/Core'
		ws.requires_arc = true
		ws.libraries = "icucore"
	end
end
