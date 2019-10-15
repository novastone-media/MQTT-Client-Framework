xcodebuild -destination generic/platform=iOS -workspace Example/Example.xcworkspace -scheme "Example" -derivedDataPath "build" CODE_SIGNING_ALLOWED=NO
#mkdir Payload
#cp -r build/Build/Products/Debug-iphoneos/Example.app Payload/
#zip -r Payload.zip Payload
#mv Payload.zip Example.ipa

curl -X POST "https://api-cloud.browserstack.com/app-automate/xcuitest/build" -d "{\"devices\": [\"iPhone XS-13\"], \"app\": \"bs://3d81b39af4a0bb7fb6d57800538043ca650d51a0\", \"deviceLogs\" : \"true\", \"testSuite\": \"bs://8b98463cc546241e0a39545d09081f609c852716\", \"project\": \"MQTTClient\"}" -H "Content-Type: application/json"
