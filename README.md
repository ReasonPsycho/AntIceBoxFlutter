# AntIceBox Controller

A Flutter application for controlling an Arduino-based cooling system that monitors temperature and allows setting minimum temperature over WiFi or Arduino IoT Cloud.

## Project Overview

This project consists of two main components:

1. **Arduino Sketch**: Controls a cooling system with a Peltier element and fan based on temperature readings from a DHT11 sensor. It can be controlled either through a direct WiFi connection or through Arduino IoT Cloud.

2. **Flutter App**: Provides a user interface for monitoring the current temperature and setting the minimum temperature threshold. The app supports both direct WiFi connection and Arduino IoT Cloud connection.

## Arduino Setup

### Hardware Requirements

- Arduino board with WiFi capability (e.g., Arduino Nano 33 IoT, Arduino MKR WiFi 1010)
- DHT11 temperature sensor
- Peltier cooling element
- Fan
- LED Matrix (for displaying temperature)
- Appropriate power supply

### Pin Configuration

- DHT11 sensor: Pin 4
- Fan control: Pin 8
- Peltier control: Pin 10

### Software Setup

#### Direct WiFi Connection

1. Install the following libraries in Arduino IDE:
   - WiFiNINA
   - DHT sensor library
   - ArduinoGraphics
   - Arduino_LED_Matrix
   - ArduinoHttpServer

2. Update the WiFi credentials in the sketch:
   ```cpp
   const char* ssid = "YourWiFiSSID";     // Replace with your WiFi SSID
   const char* password = "YourWiFiPass";  // Replace with your WiFi password
   ```

3. Upload the sketch to your Arduino board.

4. Note the IP address displayed in the Serial Monitor after the Arduino connects to WiFi.

#### Arduino IoT Cloud Connection

1. Create an account on [Arduino IoT Cloud](https://create.arduino.cc/iot/) if you don't have one.

2. Create a new Thing in the Arduino IoT Cloud dashboard:
   - Click on "Create Thing"
   - Give it a name (e.g., "AntIceBox")
   - Add two variables:
     - `temperature` (float, read-only)
     - `minTemperature` (float, read-write)

3. Configure your device:
   - Select your Arduino board
   - Configure the network credentials

4. Install the following libraries in Arduino IDE:
   - ArduinoIoTCloud
   - Arduino_ConnectionHandler
   - DHT sensor library
   - ArduinoGraphics
   - Arduino_LED_Matrix

5. Download the Arduino IoT Cloud sketch from the dashboard.

6. Merge the downloaded sketch with the AntIceBox.ino sketch, ensuring that:
   - The thingProperties.h file is included
   - The temperature and minTemperature variables are properly defined
   - The cooling logic is preserved

7. Upload the merged sketch to your Arduino board.

8. Note the Thing ID and property IDs from the Arduino IoT Cloud dashboard, as you'll need them for the Flutter app.

## Flutter App Setup

### Requirements

- Flutter SDK
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. For direct WiFi connection, update the default Arduino IP address in `lib/main.dart` if needed:
   ```dart
   const String DEFAULT_ARDUINO_IP = "192.168.1.100"; // Replace with your Arduino's IP
   ```
4. For Arduino IoT Cloud connection, you'll need to obtain the following from your Arduino IoT Cloud dashboard:
   - Client ID and Client Secret: Create these in the "API Keys" section of your Arduino IoT Cloud account
   - Thing ID: Found in the URL when viewing your Thing (e.g., https://create.arduino.cc/iot/things/THING_ID)
   - Property IDs: Found in the Network tab of browser developer tools when viewing your Thing properties
5. Run the app on your device or emulator

## Usage

### Direct WiFi Connection

1. Launch the Flutter app
2. Make sure the connection mode toggle is set to "Direct WiFi"
3. Enter the IP address of your Arduino
4. Tap "Connect to Arduino"
5. Once connected, you'll see:
   - Current temperature reading
   - Current minimum temperature setting
6. To change the minimum temperature:
   - Enter a new value in the "Set New Min Temperature" field
   - Tap "Update Min Temperature"

### Arduino IoT Cloud Connection

1. Launch the Flutter app
2. Switch the connection mode toggle to "Arduino IoT Cloud"
3. Enter your Arduino IoT Cloud credentials:
   - Client ID
   - Client Secret
   - Thing ID
   - Temperature Property ID
   - Min Temperature Property ID
4. Tap "Connect to Arduino"
5. Once connected, you'll see:
   - Current temperature reading
   - Current minimum temperature setting
6. To change the minimum temperature:
   - Enter a new value in the "Set New Min Temperature" field
   - Tap "Update Min Temperature"

## How It Works

### Arduino

#### Direct WiFi Mode

In direct WiFi mode, the Arduino sketch:
- Reads temperature from the DHT11 sensor
- Displays the temperature on the LED Matrix
- Controls the Peltier element and fan based on the temperature and minimum temperature threshold
- Provides a web server with endpoints for:
  - Getting the current temperature and minimum temperature
  - Setting a new minimum temperature

#### Arduino IoT Cloud Mode

In Arduino IoT Cloud mode, the Arduino sketch:
- Reads temperature from the DHT11 sensor
- Displays the temperature on the LED Matrix
- Controls the Peltier element and fan based on the temperature and minimum temperature threshold
- Synchronizes the temperature and minTemperature variables with Arduino IoT Cloud
- Responds to changes in minTemperature made through the cloud

### Flutter App

#### Direct WiFi Mode

In direct WiFi mode, the Flutter app:
- Connects directly to the Arduino using its IP address
- Sends HTTP requests to get temperature data and set minimum temperature
- Periodically refreshes the temperature data
- Provides visual feedback on connection status

#### Arduino IoT Cloud Mode

In Arduino IoT Cloud mode, the Flutter app:
- Authenticates with Arduino IoT Cloud using OAuth 2.0
- Retrieves temperature data from the cloud
- Sets the minimum temperature through the cloud
- Periodically refreshes the data from the cloud
- Provides visual feedback on cloud connection status

## Troubleshooting

### Direct WiFi Connection Issues

- If the app cannot connect to the Arduino, verify:
  - The Arduino is powered on and connected to WiFi
  - The IP address is correct
  - Your mobile device is on the same WiFi network as the Arduino
  - The Arduino's web server is running (check Serial Monitor)

### Arduino IoT Cloud Connection Issues

- If the app cannot connect to Arduino IoT Cloud, verify:
  - Your Arduino IoT Cloud credentials are correct
  - Your Arduino board is online in the Arduino IoT Cloud dashboard
  - Your Thing ID and Property IDs are correct
  - Your Client ID and Client Secret have the correct permissions
  - Your internet connection is stable

- If changes to minTemperature are not taking effect:
  - Check that the property is set to read-write in the Arduino IoT Cloud dashboard
  - Verify that the onMinTemperatureChange callback is properly implemented in the Arduino sketch
  - Check the Serial Monitor for any error messages

### Sensor and Cooling System Issues

- If temperature readings are incorrect:
  - Check the DHT11 sensor connection
  - Ensure the sensor is not placed near heat sources
  - Verify the sensor is properly initialized in the Arduino sketch

- If the cooling system is not responding:
  - Check the connections to the fan and Peltier element
  - Verify the power supply is adequate for the Peltier element
  - Check the Serial Monitor for any error messages related to the cooling system