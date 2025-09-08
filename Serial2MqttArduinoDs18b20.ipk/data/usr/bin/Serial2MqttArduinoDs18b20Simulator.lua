#!/usr/bin/env eco

local mqtt = require 'eco.mqtt'
local time = require 'eco.time'

local termios = require 'eco.termios'
local file = require 'eco.file'


-- adding to path
-- adding to path
package.path = package.path ..";/usr/lib/lua/?.lua"

local brf =  require 'brfUtils'


--Read config data from config file
local config = brf.Load_config("/etc/Serial2MqttArduinoDs18b20.json")


--INTERNAL "GLOBAL" VARAIABLES SECTION

local serialPortPath=""
local pts1 
local pts2
local clientConnected=false 
local startTime = os.time()
local sensorId={}
local temp={}
local SleepTime=config.PollTime/2

--\INTERNAL "GLOBAL" VARAIABLES SECTION

--functions section

function verbose(level)	
	return level<= config.sim_data.verbose 
end

function setSerial()
	--configure the serial port

	local SerSetCmd="stty -F ".. serialPortPath .. " "  .. config.Serial.baudRate .. " "  .. config.Serial.settings
	if verbose(2) then
		print (SerSetCmd)
	end
	os.execute(SerSetCmd)
end

function randomFix(tempin)
	local NextToAddMin=0
	local NextToAddMax=5
	local NextToAdd=(math.random(NextToAddMin,NextToAddMax))
	local tempout
	if (NextToAdd % 2 == 0) then
		tempout=tempin+NextToAdd
	else
		tempout=tempin-NextToAdd
	end
	if tempout<config.sim_data.temperature_Min then
		tempout=config.sim_data.temperature_Min+NextToAdd
	end
	if tempout>config.sim_data.temperature_Max then
		tempout=config.sim_data.temperature_Max-NextToAdd
	end			
	return tempout
end				


function ShapeAndSendData(StartSensor)
	local Output =""
	local nrOfSensors=0
	local NextToAddMin=0
	local NextToAddMax=0
	local NextToAdd=0
	
	if StartSensor then
		nrOfSensors=StartSensor
	else
		StartSensor=1
		nrOfSensors=config.NumberOfSensors
	end
	--for all simulated sensors
	
	for idx=StartSensor,nrOfSensors do
		--Make sure the array exists
		if not temp[idx] then
			temp[idx]=0
		end
		--Make the temperature go up slowly
		if os.time()< startTime+30 then
			if verbose(2) and idx==1 then
				print ("still Early")
			end		
			NextToAddMin=2
			NextToAddMax=math.floor(2*config.sim_data.temperature_Min/(config.sim_data.temperature_from_zero_to_min_time/SleepTime))
			NextToAdd=(math.random(NextToAddMin,NextToAddMax))					
			temp[idx]=temp[idx]+NextToAdd
			
			if temp[idx]>config.sim_data.temperature_Max then
				temp[idx]=randomFix(temp[idx])
			end
		else
			if verbose(2) and idx==1  then
				print ("late")
			end
			temp[idx]=randomFix(temp[idx])
		end
		if verbose(5) then
			print ("SensorTemp".. idx ..": " .. temp[idx])
			print ("sensorId".. idx ..": "..sensorId[idx])
		end
		
		local serielAnsw=('"DS18B20-'
			..idx.. 
			'": { "Id": "'
			.. sensorId[idx].. 
			'","Temperature": '
			..temp[idx] .. '}'.."\n")
		if verbose(2) then print("serielAnsw: "..serielAnsw) end
		
		--open the port for write				
		VirtualSerialPort, err = io.open(serialPortPath, "w")
		if not VirtualSerialPort then
			print("Error opening "..serialPortPath.. ":", err)
			return
		end
		VirtualSerialPort:write(serielAnsw)	
		
		VirtualSerialPort:close()
	end
end


--\functions section


--Set the sensorID

sensorId=brf.DS18B20ID(config.NumberOfSensors,config.sim_data.RandomSensorIdSeed)

--Make sure the serial port is present

if not arg[1] then
	print ("not able to send simulated serial")
else
	--configure the serial port 
	serialPortPath="/dev/pts/".. arg[1]
	setSerial()
		
	eco.run(function(name)		
		while true do 		
			local serial = io.open(serialPortPath, "r")			
			-- Read one line (blocks until newline is received)
			local line = serial:read("*line")
			if verbose(1) then 
				-- Print the received line
				print("Received:", line)
			end
			if line=="-1" then
				ShapeAndSendData()
			else
				if verbose(2) then  
					print("linenumber", tonumber(line) )
				end
					ShapeAndSendData(tonumber(line) )				
			end
			time.sleep(1)
		end
	end,'eco1')
end
