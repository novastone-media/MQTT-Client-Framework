# testing MQTTClient with apollo

* Download from https://activemq.apache.org/apollo/documentation/getting-started.html

* untar archive
* run `bin/apollo create mybroker`

* run `mybroker/bin/apollo-broker run`
* check on `http://localhost:61680`, login as `admin:password`

* **remember default MQTT port is 61613, not 1883**
* **remember doesn't allow anonymous login and uses admin:password**

* run `bin/activemq stop`
