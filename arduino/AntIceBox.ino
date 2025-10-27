#include "thingProperties.h"
#include <DHT.h>
#include "ArduinoGraphics.h"
#include <Arduino_LED_Matrix.h>  // Include LED Matrix library

// --- Pins ---
#define DHTPIN 4
#define DHTTYPE DHT11
int fanPin = 8;
int peltierPin = 10;

// --- DHT sensor ---
DHT dht(DHTPIN, DHTTYPE);

// --- LED Matrix ---
ArduinoLEDMatrix matrix;

// --- Timing ---
unsigned long previousMillis = 0;
const long interval = 60000; // 60 seconds
unsigned long fanStopTime = 0;

// --- States ---
bool coolingActive = true;   // true = Peltier running
bool fanCooldown = false;    // true = fan running after Peltier stop
float minTemperature = 17.0;

// --- Cloud variables ---
float temperature;

void setup() {
  pinMode(fanPin, OUTPUT);
  pinMode(peltierPin, OUTPUT);
  Serial.begin(9600);
  delay(1500);

  // Initialize properties for Arduino IoT Cloud
  initProperties();
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  setDebugMessageLevel(2);
  ArduinoCloud.printDebugInfo();

  dht.begin();

  // Initialize LED Matrix
  matrix.begin();
  matrix.clear();
  
  Serial.println("AntIceBox started with Arduino IoT Cloud");
}

void loop() {
  // Update the cloud connection
  ArduinoCloud.update();

  unsigned long currentMillis = millis();

  // Read temperature every interval
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    float t = dht.readTemperature(); // Celsius
    if (isnan(t)) {
      Serial.println("Failed to read from DHT sensor!");
      return;
    }

    temperature = t;
    Serial.print("Temp: ");
    Serial.print(temperature);
    Serial.println(" °C");

    // --- Display temperature on LED Matrix ---
    matrix.beginDraw();
    matrix.clear();
    matrix.textScrollSpeed(50);
    matrix.textFont(Font_5x7);
    matrix.beginText(0, 1, 255);
    matrix.print(String(temperature, 1) + "C");
    matrix.endText();
    matrix.endDraw();

    // --- Cooling logic ---
    if (temperature < minTemperature && coolingActive) {
      coolingActive = false;
      fanCooldown = true;
      fanStopTime = currentMillis + 60000; // 1 minute cooldown
      Serial.println("Temp < minTemperature → stopping Peltier, fan will run for 1 minute.");
    } 
    else if (temperature >= minTemperature && !coolingActive && !fanCooldown) {
      coolingActive = true;
      Serial.println("Temp >= minTemperature → resuming Peltier and fan.");
    }
  }

  // --- Apply control ---
  if (coolingActive) {
    digitalWrite(peltierPin, HIGH);
    digitalWrite(fanPin, HIGH);
  } else if (fanCooldown) {
    digitalWrite(peltierPin, LOW);
    digitalWrite(fanPin, HIGH);

    if (millis() >= fanStopTime) {
      fanCooldown = false;
      digitalWrite(fanPin, LOW);
      Serial.println("Fan cooldown finished → fan off.");
    }
  } else {
    digitalWrite(peltierPin, LOW);
    digitalWrite(fanPin, LOW);
  }
}

// Callback function when temperature changes
void onTemperatureChange() {
  // This function will be called when temperature changes
  // It's defined in thingProperties.h but implemented here
  Serial.print("Temperature changed to: ");
  Serial.print(temperature);
  Serial.println(" °C");
}

// Callback function when minTemperature changes from the cloud
void onMinTemperatureChange() {
  // This function will be called when minTemperature is changed from the cloud
  Serial.print("Min Temperature changed to: ");
  Serial.print(minTemperature);
  Serial.println(" °C");
  
  // Additional logic can be added here if needed when minTemperature changes
}