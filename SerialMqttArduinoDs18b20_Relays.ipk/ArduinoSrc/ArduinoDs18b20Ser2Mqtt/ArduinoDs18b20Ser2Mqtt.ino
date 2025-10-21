/*
 * i used this as a starting point
 * Rui Santos
 * Complete Project Details https://randomnerdtutorials.com
*
*----------------------------------------------------------
* Then i added som output control
* and made it so that the serial port has to be polled from whatever controls it 
* \Browsem
*----------------------------------------------------------
*/

#include <OneWire.h>
#include <DallasTemperature.h>
#include <avr/wdt.h>

// Data wire is plugged into port 4 on the Arduino
#define ONE_WIRE_BUS 11
// Setup the beetle for controlling relays
const int relayPins[] = { 0, 10, 9, 14, 15 };  // Example pin numbers
const int relayPinsLimit = 4;
int verbose = 0;
// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);


// Pass our oneWire reference to Dallas Temperature.
DallasTemperature sensors(&oneWire);

int numberOfDevices;  // Number of temperature devices found

DeviceAddress tempDeviceAddress;  // We'll use this variable to store a found device address

void setup(void) {
  for (int i = 1; i <= relayPinsLimit; i++) {
    pinMode(relayPins[i], OUTPUT);
  }

  // Start up the library
  sensors.begin();

  // start serial port
  Serial.begin(9600);

  //wait for the serial port
  while (!Serial && (millis() < 5000))
    ;  // Wait up to 5 secs for Serial to be ready
  if (!Serial) {
    for (;;) {}  // failed, loop forever
  } else
    Serial.println("Serial READY");
  // Grab a count of devices on the wire
  numberOfDevices = sensors.getDeviceCount();
  /*
  // locate devices on the bus
  Serial.print("Locating devices...");
  Serial.print("Found ");
  Serial.print(numberOfDevices, DEC);
  Serial.println(" devices.");
  
  // Loop through each device, print out address
  for (int i = 0; i < numberOfDevices; i++) {
    // Search the wire for address
    if (sensors.getAddress(tempDeviceAddress, i)) {
      Serial.print("Found device ");
      Serial.print(i, DEC);
      Serial.print(" with address: ");
      printAddress(tempDeviceAddress);
      Serial.println();
    } else {
      Serial.print("Found ghost device at ");
      Serial.print(i, DEC);
      Serial.print(" but could not detect address. Check power and cabling");
    }
  }
  */
}

void loop(void) {
  if (Serial.available()) {
    String StrInput = Serial.readStringUntil('\n');
    //Serial.print("1: ");
    //Serial.println(StrInput);
    if (StrInput.equals("Reset")) {
      ResetInSeconds(3);
    } else {
      char CmdChar = StrInput[0];
      //Serial.print("2: ");
      //Serial.println(CmdChar);
      if (CmdChar == 'S') {
        //Serial.print("3: ");
        PrintSensorTempsToSerial(StrInput.substring(1));
      } else if (CmdChar == 'R') {
        //Serial.print("4: ");
        FlipRelay(StrInput.substring(1));
      } else if (CmdChar == 'V') {
        Serial.print("Verbose: ");
        if (verbose == 1) {
          verbose = 0;
        } else {
          verbose = 1;
        }
        Serial.println(verbose);
      }
    }
  }
}


void FlipRelay(String RelayString) {
  if (verbose != 0) {
    Serial.print("40: ");
    Serial.println(RelayString);
  }
  int underscoreIndex = RelayString.indexOf('_');
  int numberPart = RelayString.substring(0, underscoreIndex).toInt();  // "RelayNumber"
  byte CurrentRelayPin = relayPins[numberPart];
  // Extract the state after underscore
  String statePart = RelayString.substring(underscoreIndex + 1);  // "Cmd"
  if (verbose != 0) {
    Serial.print("41: RelayNumber: ");
    Serial.println(numberPart);
    Serial.print("underscore idx: ");
    Serial.println(underscoreIndex);
  }
  if (numberPart > 0 && numberPart <= relayPinsLimit) {
    if (verbose != 0) {
      Serial.print("RelayPinNr : ");
      Serial.println(CurrentRelayPin);
    }
    if (underscoreIndex > 0) {
      //actuate the relay
      if (verbose != 0) {
        Serial.print("42: statePart: ");
        Serial.println(statePart);
      }
      if (statePart == "2" || statePart == "flip") {
        digitalToggle(CurrentRelayPin);
      } else if (statePart == "1" || statePart == "On") {
        digitalWrite(CurrentRelayPin, HIGH);
      } else if (statePart == "0" || statePart == "Off") {
        digitalWrite(CurrentRelayPin, LOW);
      } else {
        if (verbose != 0) {
          Serial.println("48: no Relays were harmed");
        }
      }
      PrintRelayState(numberPart);
    } else {
      //return the current value
      PrintRelayState(numberPart);
    }
  }
}

void PrintRelayState(int RelayNr) {
  byte CurrentRelayPin = relayPins[RelayNr];
  if (verbose != 0) {
    Serial.print("RelayNr: ");
    Serial.println(RelayNr);
    Serial.print("CurrentRelayPin nr,val: ");
    Serial.print(CurrentRelayPin);
    Serial.print(" , ");
    Serial.println(digitalRead(CurrentRelayPin));
  }
  Serial.print("\"POWER");
  Serial.print(RelayNr);
  Serial.print("\": \"");
  if (digitalRead(CurrentRelayPin) == 1) {
    Serial.print("ON");
  } else {
    Serial.print("OFF");
  }
  Serial.println("\"");
}

inline void digitalToggle(byte pin) {
  digitalWrite(pin, !digitalRead(pin));
}

void ResetInSeconds(int TimeTillReset) {
  Serial.print("Resetting in ");
  Serial.print(TimeTillReset);
  Serial.println(" seconds...");
  delay(TimeTillReset * 1000);

  // Enable the watchdog timer with a short timeout
  wdt_enable(WDTO_15MS);
}

void PrintSensorTempsToSerial(String SensorNumberStr) {
  if (verbose != 0) {
    Serial.print("30: ");
    Serial.println(SensorNumberStr);
  }
  if (isSignedNumber(SensorNumberStr)) {
    //Serial.println("31: ");
    int SensorNum = SensorNumberStr.toInt();

    sensors.requestTemperatures();  // Send the command to get temperatures
    int startIdx = 0;
    int endIdx = numberOfDevices;
    if (SensorNum != -1) {
      endIdx = SensorNum;
      startIdx = endIdx - 1;
    }

    // Loop through wanted devices, and return temperature data
    for (int i = startIdx; i < endIdx; i++) {
      // Search the wire for address
      if (sensors.getAddress(tempDeviceAddress, i)) {
        //Build and print the string
        Serial.print("\"DS18B20-");
        Serial.print(i + 1);
        Serial.print("\": { \"Id\": \"");
        printAddress(tempDeviceAddress);
        Serial.print("\",\"Temperature\": ");
        float tempC = sensors.getTempC(tempDeviceAddress);
        Serial.print(tempC);
        Serial.println("}");
        //output format
        //"DS18B20-1": { "Id": "284AF5A7FDC3278D","Temperature": 52}
      }
    }
  }
}

// function to print a device address
void printAddress(DeviceAddress deviceAddress) {
  for (uint8_t i = 0; i < 8; i++) {
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
  }
}

bool isSignedNumber(String str) {
  int start = 0;
  if (str.charAt(0) == '-') {
    start = 1;
  }
  for (unsigned int i = start; i < str.length(); i++) {
    if (!isDigit(str.charAt(i))) {
      return false;
    }
  }
  return str.length() > start;
}
