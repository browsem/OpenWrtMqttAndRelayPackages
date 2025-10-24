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
#include <limits.h>

// Data wire is plugged into port 4 on the Arduino
#define ONE_WIRE_BUS 11
const int ledPin = 13;

unsigned long currentMillis = 0;
unsigned long BlinkLastTime = 0;
long BlinkTnterval = 1250;  // milliseconds
int Serial1CmdExcecuted = 0;

// Setup the beetle for controlling relays
const int relayPins[] = { 0, 10, 9, 14, 15 };  // Example pin numbers
const int relayPinsLimit = 4;
int Verbose = 0;
int Echo = 0;


// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);


// Pass our oneWire reference to Dallas Temperature.
DallasTemperature sensors(&oneWire);

int numberOfDevices;  // Number of temperature devices found

DeviceAddress tempDeviceAddress;  // We'll use this variable to store a found device address

void setup(void) {


  //Start the Blink timer
  BlinkLastTime = millis();
  digitalWrite(ledPin, HIGH);
  for (int i = 1; i <= relayPinsLimit; i++) {
    pinMode(relayPins[i], OUTPUT);
  }

  long startTime = millis();
  // start serial ports
  Serial.begin(9600);
  //wait for the serial port
  while (!Serial && millis() < (startTime + 5000)) {
    // Wait up to 5 secs for Serial to be ready
  }
  if (!Serial) {
    for (;;) {}  // failed, loop forever
  }
  Serial.print("Serial READY\n");

  startTime = millis();
  // start serial ports
  Serial1.begin(9600);
  //wait for the serial port
  while (!Serial1 && millis() < (startTime + 5000)) {
    // Wait up to 5 secs for Serial to be ready
  }
  if (!Serial1) {
    for (;;) {}  // failed, loop forever
  }
  Serial1.println("Booting");
  PrintSerial1Cmds();


  // Start up the library
  sensors.begin();


  // Grab a count of devices on the wire
  numberOfDevices = sensors.getDeviceCount();

  // locate devices on the bus
  Serial.print("Locating devices...");
  Serial.print("Found ");
  Serial.print(numberOfDevices, DEC);
  Serial.print(" devices.\n");

  // Loop through each device, print out address
  for (int i = 0; i < numberOfDevices; i++) {
    // Search the wire for address
    if (sensors.getAddress(tempDeviceAddress, i)) {
      Serial.print("Found device ");
      Serial.print(i, DEC);
      Serial.print(" with address: ");
      printAddress(tempDeviceAddress, Serial);
      Serial.print("\n");
    } else {
      Serial.print("Found ghost device at ");
      Serial.print(i, DEC);
      Serial.print(" but could not detect address. Check power and cabling");
    }
  }
}


void PrintSerial1Cmds() {
  if (Serial1CmdExcecuted == 0) {
    Serial1.println("Commands are:");
    Serial1.println("V for verbose+1");
    Serial1.println("v for verbose-1");
    Serial1.println("Vxx or vxx for verbose=xx");
    Serial1.println("E for Echo on usbSerial to serial1");
    Serial1.println("e for Echo off usbSerial to serial1");
    Serial1CmdExcecuted = -10;
  }
}



void ifVerbose(int VerboseLevelMin, int VerboseLevelMax, Stream& serialPort, String str, int Num = INT_MIN, bool Rev = false) {

  if (VerboseLevelMin <= Verbose && Verbose < VerboseLevelMax && Verbose != 0) {

    if (Rev) {
      if (Num > INT_MIN) {
        serialPort.print(Num);
        serialPort.print(": ");
      }
      serialPort.println(str);
    } else {
      serialPort.print(str);
      serialPort.print(": ");
      serialPort.println(Num);
    }
  }
}

void Blink() {

  if (currentMillis > BlinkLastTime + BlinkTnterval) {
    BlinkLastTime = currentMillis;
    digitalToggle(ledPin);
  }
}





void ChangeVerbose(int i, int Cmd = 1) {
  Verbose = Verbose + i;
  Serial1.print("Cmd: ");
  Serial1.println(Cmd);
  if (Cmd == 1) {
    if (i > 0) {
      Serial1.print("Increasing Verbose to: ");
    } else if (i != 0) {
      Serial1.print("Decreasing Verbose to: ");
    }
  } else if (Cmd == 2) {
    Serial1.print("Setting Verbose to: ");
    Verbose = i;
  } else {
    Serial1.print("Current Verbose value is: ");
  }

  Serial1.println(Verbose);
}

void SerialCmdExcecuted(int CalledFromSerialNum, int callnum) {
  if (CalledFromSerialNum == 1) {    
    Serial1CmdExcecuted = callnum;
  }
}

void ReactToSerialStrings(int CalledFromSerialNum, char CmdChar, String StrInput) {
  if (CmdChar == 'V' || CmdChar == 'v') {
    if (StrInput.length() > 1) {
      SerialCmdExcecuted(CalledFromSerialNum, 10);
      ChangeVerbose(StrInput.toInt(), 2);
    } else if (CmdChar == 'V') {
      ChangeVerbose(+1);
      SerialCmdExcecuted(CalledFromSerialNum, 20);
    } else if (CmdChar == 'v') {
      ChangeVerbose(-1);
    }
  } else if (CmdChar == 'E') {
    Echo = 1;
    ifVerbose(1, 1000, Serial1, "Value of Echo", Echo);
    SerialCmdExcecuted(CalledFromSerialNum, 30);
  } else if (CmdChar == 'e') {
    Echo = 0;
    ifVerbose(1, 1000, Serial1, "Value of Echo", Echo);
    SerialCmdExcecuted(CalledFromSerialNum, 40);
  }
}



void FlipRelay(String RelayString) {

  if (40 <= Verbose && Verbose < 50) {
    Serial1.print("40: ");
    Serial1.println(RelayString);
  }
  int underscoreIndex = RelayString.indexOf('_');
  int numberPart = RelayString.substring(0, underscoreIndex).toInt();  // "RelayNumber"
  byte CurrentRelayPin = relayPins[numberPart];
  // Extract the state after underscore
  String statePart = RelayString.substring(underscoreIndex + 1);  // "Cmd"

  ifVerbose(40, 50, Serial1, "41: RelayNumber: ", numberPart);
  ifVerbose(40, 50, Serial1, "41: Underscore idx: ", underscoreIndex);

  if (numberPart > 0 && numberPart <= relayPinsLimit) {

    ifVerbose(40, 50, Serial1, "RelayPinNr: ", CurrentRelayPin);

    if (underscoreIndex > 0) {
      //actuate the relay
      if (40 <= Verbose && Verbose < 50) {
        Serial1.print("42: statePart: ");
        Serial1.println(statePart);
      }
      if (statePart == "2" || statePart == "flip") {
        digitalToggle(CurrentRelayPin);
      } else if (statePart == "1" || statePart == "on") {
        digitalWrite(CurrentRelayPin, HIGH);
      } else if (statePart == "0" || statePart == "off") {
        digitalWrite(CurrentRelayPin, LOW);
      } else {
        if (40 <= Verbose && Verbose < 50) {
          Serial1.println("48: no Relays were harmed");
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
  if (40 <= Verbose && Verbose < 50) {
    Serial1.print("RelayNr: ");
    Serial1.println(RelayNr);
    Serial1.print("CurrentRelayPin nr");
    Serial1.print(CurrentRelayPin);
    Serial1.print(",val: , ");
    Serial1.println(digitalRead(CurrentRelayPin));
  }
  Serial.print("\"POWER");
  Serial.print(RelayNr);
  Serial.print("\": \"");
  if (digitalRead(CurrentRelayPin) == 1) {
    Serial.print("ON");
  } else {
    Serial.print("OFF");
  }
  Serial.print("\"\n");
}

inline void digitalToggle(byte pin) {
  digitalWrite(pin, !digitalRead(pin));
}

void ResetInSeconds(int TimeTillReset) {
  Serial.print("Resetting in ");
  Serial.print(TimeTillReset);
  Serial.print(" seconds...\n");
  delay(TimeTillReset * 1000);

  // Enable the watchdog timer with a short timeout
  wdt_enable(WDTO_15MS);
}

void PrintSensorTempsToSerial(String SensorNumberStr) {

  if (31 <= Verbose && Verbose < 40) {
    Serial1.print("30: ");
    Serial1.println(SensorNumberStr);
    Serial1.print("isSignedNumber: ");
    Serial1.println(isSignedNumber(SensorNumberStr));
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
    if (30 <= Verbose && Verbose < 40) {
      Serial1.print("31 startIdx: ");
      Serial1.println(startIdx);
      Serial1.print("31 endIdx: ");
      Serial1.println(endIdx);
    }
    // Loop through wanted devices, and return temperature data
    for (int i = startIdx; i < endIdx; i++) {
      // Search the wire for address
      if (30 <= Verbose && Verbose < 40) {
        Serial1.print("32 Search the wire for sensor nr: ");
        Serial1.println(i);
      }
      if (sensors.getAddress(tempDeviceAddress, i)) {

        float tempC = sensors.getTempC(tempDeviceAddress);
        BuildAndPrintString(i, tempC, tempDeviceAddress, Serial);
        if (30 <= Verbose && Verbose < 40) {
          BuildAndPrintString(i, tempC, tempDeviceAddress, Serial1);
        }
      }
    }
  }
}


void  //function to print a formatted temperature string to the selected serial port
BuildAndPrintString(int i, float tempC, DeviceAddress tempDeviceAddress, Stream& serialPort) {
  //Build and print the string
  serialPort.print("\"DS18B20-");
  serialPort.print(i + 1);
  serialPort.print("\": { \"Id\": \"");
  printAddress(tempDeviceAddress, serialPort);
  serialPort.print("\",\"Temperature\": ");
  serialPort.print(tempC);
  serialPort.print("}\n");
  //output format
  //"DS18B20-1": { "Id": "284AF5A7FDC3278D","Temperature": 52}
}

// function to print a device address
void printAddress(DeviceAddress deviceAddress, Stream& serialPort) {
  for (uint8_t i = 0; i < 8; i++) {
    if (deviceAddress[i] < 16) serialPort.print("0");
    serialPort.print(deviceAddress[i], HEX);
  }
}

bool isSignedNumber(String str) {
  int start = 0;
  str.trim();
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

//--loop--------------------------------------------------------------------------------------------------------------------------
void loop(void) {
  currentMillis = millis();
  Blink();
  PrintSerial1Cmds();
  if (Serial.available()) {
    String StrInput = Serial.readStringUntil('\n');
    if (Echo >= 1) {
      Serial1.print("Usb cmd recieved: ");
      Serial1.println(StrInput);
    }

    if (StrInput.equals("Reset")) {
      ResetInSeconds(3);
    } else {
      char CmdChar = StrInput[0];

      ifVerbose(980, 1000, Serial1, String(CmdChar), 2, true);

      if (CmdChar == 'S') {
        ifVerbose(980, 1000, Serial1, String(CmdChar), 3, true);
        PrintSensorTempsToSerial(StrInput.substring(1));
      } else if (CmdChar == 'R') {
        ifVerbose(900, 1000, Serial1, String(CmdChar), 4, true);
        FlipRelay(StrInput.substring(1));
      } else {
        ifVerbose(900, 1000, Serial1, String(CmdChar), 5, true);
        ReactToSerialStrings(0, CmdChar, StrInput.substring(1));
      }
    }
  }
  Serial1CmdExcecuted = -1;
  if (Serial1.available()) {
    Serial1CmdExcecuted = 0;
    String StrInput1 = Serial1.readStringUntil('\n');
    if (Verbose >= 1) {
      Serial1.print("Serial cmd recieved: ");
      Serial1.println(StrInput1);
    }

    if (StrInput1.equals("Reset")) {
      SerialCmdExcecuted(1, 1);
      ResetInSeconds(3);      
    } else {
      char CmdChar1 = StrInput1[0];
      ReactToSerialStrings(1, CmdChar1, StrInput1.substring(1));
    }
  }
}
