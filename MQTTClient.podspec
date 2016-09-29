Pod::Spec.new do |mqttc|
	mqttc.name         = "MQTTClient"
	mqttc.version      = "0.8.5"
	mqttc.summary      = "iOS, OSX and tvOS native ObjectiveC MQTT Client Framework"
	mqttc.homepage     = "https://github.com/ckrey/MQTT-Client-Framework"
	mqttc.license      = { :type => "EPLv1", :file => "LICENSE" }
	mqttc.author       = { "Christoph Krey" => "krey.christoph@gmail.com" }
	mqttc.source       = {
		:git => "https://github.com/ckrey/MQTT-Client-Framework.git",
		:tag => "0.8.5",
		:submodules => true
	}

	mqttc.requires_arc = true
	mqttc.platform = :ios, "6.1", :osx, "10.10", :tvos, "9.0"
	mqttc.ios.deployment_target = "6.1"
	mqttc.osx.deployment_target = "10.10"
	mqttc.tvos.deployment_target = "9.0"
	mqttc.default_subspec = 'Core'

	mqttc.subspec 'Core' do |core|
		core.dependency 'MQTTClient/Min'
		core.dependency 'MQTTClient/Manager'
	end

	mqttc.subspec 'Min' do |min|
		min.source_files =	"MQTTClient/MQTTClient/MQTTCFSocketDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTCFSocketEncoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTCFSocketTransport.{h,m}",
					"MQTTClient/MQTTClient/MQTTCoreDataPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTInMemoryPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTLog.h",
					"MQTTClient/MQTTClient/MQTTClient.h",
					"MQTTClient/MQTTClient/MQTTMessage.{h,m}",
					"MQTTClient/MQTTClient/MQTTPersistence.h",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicy.{h,m}",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicyDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicyEncoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicyTransport.{h,m}",
					"MQTTClient/MQTTClient/MQTTSession.{h,m}",
					"MQTTClient/MQTTClient/MQTTSessionLegacy.{h,m}",
					"MQTTClient/MQTTClient/MQTTSessionSynchron.{h,m}",
					"MQTTClient/MQTTClient/MQTTTransport.{h,m}"
	end

	mqttc.subspec 'MinL' do |minl|
		minl.dependency 'CocoaLumberjack', '~> 2.3.0'
		minl.source_files =	"MQTTClient/MQTTClient/MQTTCFSocketDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTCFSocketEncoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTCFSocketTransport.{h,m}",
					"MQTTClient/MQTTClient/MQTTCoreDataPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTInMemoryPersistence.{h,m}",
					"MQTTClient/MQTTClient/MQTTLog.h",
					"MQTTClient/MQTTClient/MQTTClient.h",
					"MQTTClient/MQTTClient/MQTTMessage.{h,m}",
					"MQTTClient/MQTTClient/MQTTPersistence.h",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicy.{h,m}",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicyDecoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicyEncoder.{h,m}",
					"MQTTClient/MQTTClient/MQTTSSLSecurityPolicyTransport.{h,m}",
					"MQTTClient/MQTTClient/MQTTSession.{h,m}",
					"MQTTClient/MQTTClient/MQTTSessionLegacy.{h,m}",
					"MQTTClient/MQTTClient/MQTTSessionSynchron.{h,m}",
					"MQTTClient/MQTTClient/MQTTTransport.{h,m}"
		minl.compiler_flags = '-DLUMBERJACK=1'
	end

	mqttc.subspec 'Manager' do |manager|
		manager.source_files =	"MQTTClient/MQTTClient/MQTTSessionManager.{h,m}"
		manager.dependency 'MQTTClient/Min'
	end

	mqttc.subspec 'ManagerL' do |managerl|
		managerl.source_files =	"MQTTClient/MQTTClient/MQTTSessionManager.{h,m}"
		managerl.dependency 'MQTTClient/MinL'
		managerl.compiler_flags = '-DLUMBERJACK=1'
	end

	mqttc.subspec 'Websocket' do |ws|
		ws.source_files = "MQTTClient/MQTTClient/MQTTWebsocketTransport/*.{h,m}"
		ws.dependency 'SocketRocket'
		ws.dependency 'MQTTClient/Min'
		ws.requires_arc = true
		ws.libraries = "icucore"
	end

	mqttc.subspec 'WebsocketL' do |wsl|
		wsl.source_files = "MQTTClient/MQTTClient/MQTTWebsocketTransport/*.{h,m}"
		wsl.dependency 'SocketRocket'
		wsl.dependency 'MQTTClient/MinL'
		wsl.requires_arc = true
		wsl.libraries = "icucore"
		wsl.compiler_flags = '-DLUMBERJACK=1'
	end
end
