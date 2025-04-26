#include <WiFi.h>
#include <HTTPClient.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// API Gateway configuration
const char* apiEndpoint = "https://your-api-id.execute-api.region.amazonaws.com";
const char* apiKey = "YOUR_API_KEY"; // Get this from Terraform output

// Pin configuration
const int switchPin = 5;    // Power switch
const int testButtonPin = 18;    // Test button
const int nukeButtonPin = 19;    // NUKE button
const int statusLedPin = 21;     // Status LED

bool readyToNuke = false;

void setup() {
  // Initialize serial for debugging
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(switchPin, INPUT_PULLUP);
  pinMode(testButtonPin, INPUT_PULLUP);
  pinMode(nukeButtonPin, INPUT_PULLUP);
  pinMode(statusLedPin, OUTPUT);
  
  // Initialize WiFi
  WiFi.begin(ssid, password);
  
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to WiFi");
}

void loop() {
  // Check if power switch is on
  if (digitalRead(switchPin) == HIGH) {
    // Power is off, do nothing
    digitalWrite(statusLedPin, LOW);
    readyToNuke = false;
    return;
  }
  
  // Check if test button is pressed
  if (digitalRead(testButtonPin) == LOW) {
    Serial.println("Test button pressed, performing dry run...");
    performDryRun();
    delay(500); // Simple debounce
  }
  
  // Check if NUKE button is pressed and we're ready to nuke
  if (readyToNuke && digitalRead(nukeButtonPin) == LOW) {
    Serial.println("🚨 NUKE BUTTON PRESSED! 🚨");
    executeNuke();
    delay(1000); // Simple debounce
    readyToNuke = false;
  }
  
  // Indicate if we're ready to nuke
  digitalWrite(statusLedPin, readyToNuke ? HIGH : LOW);
  
  delay(100);
}

void performDryRun() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected!");
    return;
  }
  
  HTTPClient http;
  
  // Start the request
  http.begin(String(apiEndpoint) + "/dry-run");
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", apiKey);
  
  // Send the request
  int httpCode = http.POST("{}");
  
  // Check the response
  if (httpCode > 0) {
    String payload = http.getString();
    Serial.println("HTTP Response code: " + String(httpCode));
    Serial.println("Response: " + payload);
    
    if (httpCode == 200) {
      Serial.println("Dry run successful! Ready to NUKE!");
      readyToNuke = true;
    } else {
      Serial.println("Dry run failed!");
      readyToNuke = false;
    }
  } else {
    Serial.println("Error on HTTP request");
    readyToNuke = false;
  }
  
  http.end();
}

void executeNuke() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected!");
    return;
  }
  
  HTTPClient http;
  
  // Start the request
  http.begin(String(apiEndpoint) + "/execute");
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", apiKey);
  
  // Send the request
  int httpCode = http.POST("{}");
  
  // Check the response
  if (httpCode > 0) {
    String payload = http.getString();
    Serial.println("HTTP Response code: " + String(httpCode));
    Serial.println("Response: " + payload);
    
    if (httpCode == 200) {
      Serial.println("🔥 NUKE EXECUTED SUCCESSFULLY! 🔥");
      // Blink the LED to indicate success
      for (int i = 0; i < 10; i++) {
        digitalWrite(statusLedPin, HIGH);
        delay(100);
        digitalWrite(statusLedPin, LOW);
        delay(100);
      }
    } else {
      Serial.println("Nuke failed!");
    }
  } else {
    Serial.println("Error on HTTP request");
  }
  
  http.end();
  readyToNuke = false;
}