#ifndef THING_PROPERTIES_H
#define THING_PROPERTIES_H

#include <ArduinoIoTCloud.h>
#include <Arduino_ConnectionHandler.h>

// Define your WiFi credentials here
const char SSID[] = "YourWiFiSSID";     // Replace with your WiFi SSID
const char PASS[] = "YourWiFiPass";     // Replace with your WiFi password

// Define your Arduino IoT Cloud Thing ID and credentials
// You need to get these from your Arduino IoT Cloud dashboard
const char THING_ID[] = "your-thing-id";                // Replace with your Thing ID
const char DEVICE_LOGIN_NAME[] = "your-device-login";   // Replace with your device login name
const char DEVICE_KEY[] = "your-device-key";            // Replace with your device key

// Define the connection handler
WiFiConnectionHandler ArduinoIoTPreferredConnection(SSID, PASS);

// Define cloud variables
float temperature;
float minTemperature;

void initProperties() {
  // Initialize the Arduino IoT Cloud properties
  ArduinoCloud.setThingId(THING_ID);
  ArduinoCloud.addProperty(temperature, READ, ON_CHANGE, NULL);
  ArduinoCloud.addProperty(minTemperature, READWRITE, ON_CHANGE, onMinTemperatureChange);
}

// Callback function when minTemperature is changed from the cloud
void onMinTemperatureChange() {
  // This function will be called when minTemperature is changed from the cloud
  Serial.print("Min Temperature changed to: ");
  Serial.println(minTemperature);
}

#endif // THING_PROPERTIES_H