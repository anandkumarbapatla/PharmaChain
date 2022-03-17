#include "FS.h"
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include "DHTesp.h"
#include <time.h>
#include <TinyGPSPlus.h> // library for GPS module
#include <SoftwareSerial.h>
#include <ArduinoJson.h>
DHTesp dht;

#define AWS_IOT_PUBLISH_TOPIC   "esp32/pub"
#define AWS_IOT_SUBSCRIBE_TOPIC "esp32/sub"

const char* ssid = "LifeEhOkaZindagi";   //Wi-Fi Name
const char* password = "Our213Spect20!";   //Edit this line and put in your Wifi Password
int count = 0;
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

const char* AWS_endpoint = "a19riurxxugbht-ats.iot.us-east-2.amazonaws.com";

TinyGPSPlus gps;  // The TinyGPS++ object
SoftwareSerial ss(4, 5); // The serial connection to the GPS device
float latitude , longitude;
int year , month , date, hour , minute , second;
String date_str , time_str , lat_str , lng_str;
int pm;

void callback(char* topic, byte* payload, unsigned int length) 
{
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) 
  {
    Serial.print((char)payload[i]);
  }
  Serial.println();
}
  
WiFiClientSecure esp8266Client;
PubSubClient pubClient(AWS_endpoint, 8883, callback, esp8266Client); //set MQTT port number to 8883 as per //standard
long lastMsg = 0;

char msg[500];  //buffer to hold the message to be published
int value = 0;
  
void setup_wifi() 
{
  
  delay(10);
  // We start by connecting to a WiFi network
  esp8266Client.setBufferSizes(512, 512);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  
  timeClient.begin();
  while (!timeClient.update()) {
    timeClient.forceUpdate();
  }
  
  esp8266Client.setX509Time(timeClient.getEpochTime());
  
}
  
void reconnect() 
{
  // Loop until we're reconnected
  while (!pubClient.connected()) 
  {
    Serial.print("Attempting MQTT connection...");
    // Attempt to connect
    if (pubClient.connect("PharmaChain_SensingNode")) 
    {
      Serial.println("connected");
      // Once connected, publish an announcement...
      pubClient.publish(AWS_IOT_PUBLISH_TOPIC, "hello world");
      // ... and resubscribe
      pubClient.subscribe(AWS_IOT_SUBSCRIBE_TOPIC);
    } 
    else
    {
      Serial.print("failed, rc=");
      Serial.print(pubClient.state());
      Serial.println(" try again in 5 seconds");
  
      char buf[256];
      esp8266Client.getLastSSLError(buf, 256);
      Serial.print("WiFiClientSecure SSL error: ");
      Serial.println(buf);
  
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}

void updateGPSLocation(){
  while (ss.available() > 0) //while data is available
    if (gps.encode(ss.read())) //read gps data
    {
      if (gps.location.isValid()) //check whether gps location is valid
      {
        latitude = gps.location.lat();
        lat_str = String(latitude , 6); // latitude location is stored in a string
        longitude = gps.location.lng();
        lng_str = String(longitude , 6); //longitude location is stored in a string
      }
      if (gps.date.isValid()) //check whether gps date is valid
      {
        date_str = "";
        date = gps.date.day();
        month = gps.date.month();
        year = gps.date.year();
        if (date < 10)
          date_str = '0';
        date_str += String(date);// values of date,month and year are stored in a string
        date_str += " / ";

        if (month < 10)
          date_str += '0';
        date_str += String(month); // values of date,month and year are stored in a string
        date_str += " / ";
        if (year < 10)
          date_str += '0';
        date_str += String(year); // values of date,month and year are stored in a string
      }
      if (gps.time.isValid())  //check whether gps time is valid
      {
        time_str = "";
        hour = gps.time.hour();
        minute = gps.time.minute();
        second = gps.time.second();
        minute = (minute + 60); // converting to IST
        if (minute > 59)
        {
          minute = minute - 60;
          hour = hour + 1;
        }
        hour = (hour + 5) ;
        if (hour > 23)
          hour = hour - 24;   // converting to IST
        if (hour >= 12)  // checking whether AM or PM
          pm = 1;
        else
          pm = 0;
        hour = hour % 12;
        if (hour < 10)
          time_str = '0';
        time_str += String(hour); //values of hour,minute and time are stored in a string
        time_str += " : ";
        if (minute < 10)
          time_str += '0';
        time_str += String(minute); //values of hour,minute and time are stored in a string
        time_str += " : ";
        if (second < 10)
          time_str += '0';
        time_str += String(second); //values of hour,minute and time are stored in a string
        if (pm == 1)
          time_str += " PM ";
        else
          time_str += " AM ";
      }
    }
}
  
void setup()
{
  Serial.begin(115200);
  ss.begin(9600);
  Serial.setDebugOutput(true);
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  setup_wifi();
  delay(1000);
  if (!SPIFFS.begin()) 
  {
    Serial.println("Failed to mount file system");
    return;
  }
  
  Serial.print("Heap: "); Serial.println(ESP.getFreeHeap());
  
  // Load certificate file
  File cert = SPIFFS.open("/cert.der", "r"); //replace cert.crt with your uploaded file name
  if (!cert) 
  {
    Serial.println("Failed to open cert file");
  }
  else
    Serial.println("Successfully opened cert file");
  
  delay(1000);
  
  if (esp8266Client.loadCertificate(cert)) // add the thing certificate to the pubClient
    Serial.println("cert loaded");
  else
    Serial.println("cert not loaded");
  
  // Load private key file
  File private_key = SPIFFS.open("/private.der", "r"); //replace private with your uploaded file name
  if (!private_key) 
  {
    Serial.println("Failed to open private cert file");
  }
  else
    Serial.println("Successfully opened private cert file");
  
  delay(1000);
  
  if (esp8266Client.loadPrivateKey(private_key))  // add the private key to the pubClient
    Serial.println("private key loaded");
  else
    Serial.println("private key not loaded");
  
  // Load CA file
  File ca = SPIFFS.open("/ca.der", "r"); //replace ca with your uploaded file name
  if (!ca) 
  {
    Serial.println("Failed to open ca ");
  }
  else
    Serial.println("Successfully opened open ca");
  
  delay(1000);
  
  if (esp8266Client.loadCACert(ca))   // add the AWS root certificate to the pubClient
    Serial.println("ca loaded");
  else
    Serial.println("ca failed");
  
  Serial.print("Heap: "); Serial.println(ESP.getFreeHeap());

  dht.setup(14, DHTesp::DHT11);
  //init and get the time
  timeClient.begin();

}
  
void loop() 
{
  if (!pubClient.connected()) 
  {
    reconnect();
  }
  pubClient.loop();
  updateGPSLocation();
  long now = millis();
  if (now-lastMsg > 10000) 
  {
    lastMsg = now;
    count++;
    //create the message to be sent
    float humidity = dht.getHumidity();
    float temperature = dht.getTemperature();
    //Serial.println(lat_str);
    //Serial.println(lng_str);
    char timeStampCharArry[17];
    String timestamp = date_str + " " + time_str; 
    //Serial.println(timestamp);
    StaticJsonBuffer<500> JSONbuffer;
    JsonObject& root = JSONbuffer.createObject();
    root["timestamp"] = timestamp;
    root["latitude"] = latitude;
    root["longitude"] = longitude;
    root["sku"] = 2112101;
    root["lot"] = 547863250;
    root["drugname"] = "Mucinex";
    root["temperature"] = temperature;
    root["humidity"] = humidity;
    root.printTo(msg,sizeof(msg));
    Serial.print("Publish message: ");
    Serial.println(msg);
    // publish messages to the topic "outTopic"
    pubClient.publish(AWS_IOT_PUBLISH_TOPIC, msg);  
    Serial.print("Heap: "); Serial.println(ESP.getFreeHeap()); //Low heap can cause problems
  }
  digitalWrite(LED_BUILTIN, HIGH); // turn the LED on (HIGH is the voltage level)
  delay(100); // wait for a second
  digitalWrite(LED_BUILTIN, LOW); // turn the LED off by making the voltage LOW
  delay(100); // wait for a second
}
