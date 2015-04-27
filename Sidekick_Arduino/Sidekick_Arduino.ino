/******************************************************************************
 * Sidekick - Object recognition robot that follows you                       *
 * Copyright (C) 2015 Gabriel Tan-Chen | www.gabrieltanchen.com               *
 *                                                                            *
 * This program is free software: you can redistribute it and/or modify it    *
 * under the terms of the GNU General Public License as published by the Free *
 * Software Foundation, either version 3 of the License, or any later         *
 * version.                                                                   *
 *                                                                            *
 * This program is distributed in the hope that it will be useful, but        *
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License    *
 * for more details.                                                          *
 *                                                                            *
 * You should have received a copy of the GNU General Public License along    *
 * with this program. If not, see <http://www.gnu.org/licenses/>.             *
 ******************************************************************************/
#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_PWMServoDriver.h"
#include <SPI.h>
#include "Adafruit_BLE_UART.h"

#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2     // This should be an interrupt pin, on Uno thats #2 or #3
#define ADAFRUITBLE_RST 9

Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);

Adafruit_MotorShield AFMS = Adafruit_MotorShield();

Adafruit_DCMotor *frontMotor = AFMS.getMotor(4);
Adafruit_DCMotor *rearMotor = AFMS.getMotor(2);
Adafruit_DCMotor *turnMotor = AFMS.getMotor(3);

String message;
String dir;
int spd;

aci_evt_opcode_t laststatus = ACI_EVT_DISCONNECTED;

void setup()
{
  Serial.begin(9600);
  while(!Serial);
  Serial.println(F("Sidekick"));
  BTLEserial.begin();
  
  AFMS.begin();
}

void loop()
{
  BTLEserial.pollACI();
  
  aci_evt_opcode_t status = BTLEserial.getState();
  
  if (status != laststatus) {
    // print it out!
    if (status == ACI_EVT_DEVICE_STARTED) {
        Serial.println(F("* Advertising started"));
    }
    if (status == ACI_EVT_CONNECTED) {
        Serial.println(F("* Connected!"));
    }
    if (status == ACI_EVT_DISCONNECTED) {
        Serial.println(F("* Disconnected or advertising timed out"));
    }
    // OK set the last status change to this one
    laststatus = status;
  }
  
  if (status == ACI_EVT_CONNECTED) {
    message = "";
    // Check if there is any data.
    while (BTLEserial.available()) {
      char c = BTLEserial.read();
      message += c;
    }
    
    if (message != "") {
      Serial.println(message);
    
      dir = message.substring(0,1);
      spd = message.substring(1,4).toInt();
      Serial.println(dir);
      Serial.println(spd);
      Serial.println("---------");
    
      if (dir == "F") {
        frontMotor->setSpeed(spd);
        frontMotor->run(FORWARD);
        rearMotor->setSpeed(spd);
        rearMotor->run(FORWARD);
      } else if (dir == "B") {
        frontMotor->setSpeed(spd);
        frontMotor->run(BACKWARD);
        rearMotor->setSpeed(spd);
        rearMotor->run(BACKWARD);
      } else if (dir == "S") {
        frontMotor->run(RELEASE);
        rearMotor->run(RELEASE);
        turnMotor->run(RELEASE);
      } else if (dir == "L") {
        turnMotor->setSpeed(255);
        turnMotor->run(FORWARD);
      } else if (dir == "R") {
        turnMotor->setSpeed(255);
        turnMotor->run(BACKWARD);
      } else if (dir == "T") {
        turnMotor->run(RELEASE);
      }
    }
  }
}
