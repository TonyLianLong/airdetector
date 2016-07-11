#include <Wire.h>

#define MONO_DEVICE 0x00
#define MULTI_DEVICE 0x01

#define IDLE 0x00
#define SELECTED 0x01
#define REQUEST_DATA 0x02
#define PREPARE_DATA 0x03

#define SUBSENSOR_NUMBER 4

//#include <EEPROM.h>
#include <avr/sleep.h>
#include <dht11.h>

dht11 DHT11;

#define LED_PIN 9
#define DUST_PIN A1
#define DHT11_PIN 5
#define QS_01_PIN A0
#define DHT11_TRY_MAX_COUNT 10
#define RS_AIR_VALUE 6000
#define ADJUST_VALUE (27+100)
#define QS_01_HEATTIME 300000
#define EEPROM_VERSION_SIGNATURE 0x0001
#define DHT11_TEMP_ADJ_VALUE -3
#define COMMAND_BUFFER_LENGTH 25
#define DEFAULT_VALUE_0 27
char command[COMMAND_BUFFER_LENGTH];
double dustVal;
struct pref {
  uint32_t version_signature;
  double maxnumber[4];
  double minnumber[4];
  double adjust_value[4];
} preferences;
struct pref default_preferences = {
  EEPROM_VERSION_SIGNATURE,
  {150, 1, 30, 70},
  {0, 0.8, 20, 20},
  {ADJUST_VALUE, RS_AIR_VALUE, DHT11_TEMP_ADJ_VALUE, 0}
};
/*void readPref() {
  for (unsigned int i = 0; i < sizeof(struct pref); i++) {
    *((uint8_t *)&preferences + i) = EEPROM.read(i);
    Serial.println(*((uint8_t *)&preferences + i));
  }
}
void writePref() {
  for (unsigned int i = 0; i < sizeof(struct pref); i++) {
    EEPROM.write(i, *((uint8_t *)&preferences + i));
  }
}*/

uint8_t data_array[20];//Start sign
uint16_t data_num[SUBSENSOR_NUMBER] = {25, 1, 25, 25};
uint8_t subsensor = 0;
uint64_t id = 0;
char status = IDLE;
boolean selected = false;//You need to init first.
uint8_t i2c_command;
double getDustVal(bool adjust) {
  double value;
  dustVal = 0;
  // ledPower is any digital pin on the arduino connected to Pin 3 on the sensor
  for (unsigned int i = 0; i < 10; i++) {
    digitalWrite(LED_PIN, LOW);
    delayMicroseconds(280);
    dustVal += analogRead(DUST_PIN);
    delayMicroseconds(40);
    digitalWrite(LED_PIN, HIGH);
    delayMicroseconds(9680);
  }
  if (adjust) {
    value = (double)(dustVal / 10) / 1024 * 5 * 200 - 200 + preferences.adjust_value[0];
    if (value < 0) {
      value = -1;
    }
  } else {
    value = (double)(dustVal / 10) / 1024 * 5 * 200 - 200;
  }
  /*Serial.print("Value:");
  Serial.println(((double)(dustVal / 10) / 1024 * 5 * 200 - 200));*/
  return value;
}
double UT;
int dht_return_value;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(DUST_PIN, INPUT);
  pinMode(QS_01_PIN, INPUT_PULLUP);
  Serial.println("Airdetector Sensor");
  /*readPref();
  if (preferences.version_signature != EEPROM_VERSION_SIGNATURE) {
    preferences = default_preferences;
    Serial.println("Preferences version signature not match.");
    writePref();
  }*/
  Wire.begin(8);
  Wire.onRequest(request);
  Wire.onReceive(receive);
}

void loop() {
  if(status == PREPARE_DATA){
    data_num[0] = getDustVal(true);
        UT = (double)analogRead(QS_01_PIN) / 1023 * 5;
        data_num[1] = ((double)5 - UT) / UT * 1000 / RS_AIR_VALUE;
        if (data_num[1] > 1) {
          data_num[1] = 1;
        }
        //This value is the return value of DHT11
        dht_return_value = DHT11.read(DHT11_PIN);
        if (dht_return_value == DHTLIB_OK) {
          data_num[2] = (double)DHT11.temperature + preferences.adjust_value[2];
          data_num[3] = (double)DHT11.humidity;
        } else {
          Serial.print("DHT11 Error:");
          Serial.println(dht_return_value);
        }
        Serial.println("Data:");
                Serial.println(UT);
        Serial.println(data_num[0]);
        Serial.println(data_num[1]);
        Serial.println(data_num[2]);
        Serial.println(data_num[3]);
        Serial.println("Prepare data for all");
        delay(500);
  }else{
    //sleep_enable();
    //set_sleep_mode(SLEEP_MODE_PWR_DOWN);
    //sleep_cpu();
    //sleep_disable();
  }
}
void request()
{
  Serial.println("Request");
  if (selected) {
    switch (i2c_command) {
      case 0x02:
        if (selected == true) {
          uint8_t i = 1;
          data_array[0] = 0xAA;
          while (i < 17) {
            data_array[i] = (id >> (i << 3)) & 0xFF;
            i++;
            data_array[i] = ~((id >> (i << 3)) & 0xFF);
            i++;
          }
          Wire.write(data_array, 17);
          Serial.println("Data");
          Serial.println((uint32_t)id);
        }
        break;
      case 0x0F://prepare Data for a subsensor - not supported
        Wire.write(0x2);
        break;
      case 0x10://prepare data for all subsensors
        Wire.write(0xAA);
        status = PREPARE_DATA;
        break;
      case 0xF0:
        data_array[0] = 0xAA;
        data_array[1] = data_num[subsensor] >> 8;
        data_array[2] = ~(data_num[subsensor] >> 8);
        data_array[3] = data_num[subsensor] & 0xFF;
        data_array[4] = ~(data_num[subsensor] & 0xFF);
        Wire.write(data_array, 5);
        /*Serial.print("Get data Subsensor:");
        Serial.println(subsensor);
        Serial.println(data_num[subsensor]);
        Serial.println(data_array[0],HEX);*/
        break;
    }
  }else{
    Serial.println("Receive a REQUEST but not selected(for other sensor).");
  }
}
void receive(int n)
{
  Serial.println("Receive");
  Serial.println(n);
  i2c_command = Wire.read();
  Serial.println(i2c_command,HEX);
  switch (i2c_command) {
    case 0x0F:
      //prepare data for a subsensor - not supported
      while (Wire.available() == 0);
      subsensor = Wire.read();
      if (subsensor >= SUBSENSOR_NUMBER) {
        subsensor = 0;
      }
      break;
    case 0x10://prepare data for all subsensors
      break;
    case 0xF0:
      //Request
      status = REQUEST_DATA;
      while (Wire.available() == 0);
      subsensor = Wire.read();
      if (subsensor >= SUBSENSOR_NUMBER) {
        subsensor = 0;
      }
      break;
    case 0x01:
      //Reset
      status = IDLE;
      selected = false;
      break;
    case 0x02:
      //Select
      selected = false;
      status = IDLE;
      while (Wire.available() == 0);
      if (Wire.read() == 0) {
        while (Wire.available() == 0);
        if (Wire.read() == 0) {
          selected = true;
          status = SELECTED;
          Serial.println("Selected");
        }
      }
  }
}
