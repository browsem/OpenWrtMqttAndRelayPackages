#!/usr/bin/env eco

local time = require 'eco.time'
local mqtt = require 'eco.mqtt'


-- adding to path
package.path = package.path ..";/usr/lib/lua/?.lua"
local brfUtils =  require 'brfUtils'
local json = require "dkjson"

Serial = 1
Mqtt = 2

function sleep(seconds)
  local start = os.clock()
  while os.clock() - start < seconds do end
end

function script_path()  
  --local script = arg[0]
  local cwd = io.popen("pwd"):read("*l") -- for Unix-like systems
  --print (cwd)
  return cwd .."/"
end

-- Function to read file contents
local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        error("Could not open file: " .. path)
    end
    local content = file:read("*a")	
    file:close()	
    return content
end

-- Load and parse JSON config
local function load_config(path)	
    local content = read_file(path)		
    local config, pos, err = json.decode(content, 1, nil)
	if err then
        error("JSON decode error: " .. err)
    end
    return config
end	


temp={}
NextToAddMin=0
NextToAddMax=0
NextToAdd=0


--read the config file
config = load_config("/etc/Serial2MqttArduinoDs18b20.json")


function randomFix(jdx,idx)
	NextToAddMin=0
	NextToAddMax=5
	NextToAdd=(math.random(NextToAddMin,NextToAddMax))
	if (NextToAdd % 2 == 0) then
		temp[jdx][idx]=temp[jdx][idx]+NextToAdd
	else
		temp[jdx][idx]=temp[jdx][idx]-NextToAdd
	end
	if temp[jdx][idx]<config.sim_data[jdx].temperature_Min then
		temp[jdx][idx]=config.sim_data[jdx].temperature_Min+NextToAdd
	end
	if temp[jdx][idx]>config.sim_data[jdx].temperature_Max then
		temp[jdx][idx]=config.sim_data[jdx].temperature_Max-NextToAdd
	end				
end				


--Sensor 0: 23.56
--Sensor 1: 24.12
local startTime = os.time()
local CurrTime = os.time()
local runtime=CurrTime-startTime


local SleepTime=config.PollTime/2
local LastTimeSerial=runtime-SleepTime
local LastTimeMqtt = runtime-config.PollTime
--print (config)
--print (config.sim_data)
--print (config.sim_data[jdx].temperature_Min)
local VirtualSerialPort


if config.sim_data[Mqtt].Simulated==1 then
	
	-- Create MQTT client
	client = mqtt.new({
		ipaddr = config.ipaddr,      -- Replace with your broker IP
		port = config.port,               -- Or 8883 for TLS
		username = config.username,
		password = config.password,
		clean_session = true
	})

	-- Define MQTT event handlers

	client:on({	
		conack = function(ack, client)
			--This is what we do when first connected
			print('Connected to broker:', ack.rc)		
			--readnPublishTemperatures(client)	
			--define what we want to subscribe to
			
			client:subscribe('cmnd'.. config.sim_data[Mqtt].Topic_String, mqtt.QOS0)	
			print ("subscribed to: "..'cmnd'.. config.sim_data[Mqtt].Topic_String)
		end,
		
		publish  = function(pkt, client)
		--this is what we do, when we recieve a meassage
			print('Received message on topic:', pkt.topic)
			--return read and publish sensors
			ShapeAndSendData(client,Mqtt,false)
			--print("food")
		end,

		error = function(err)
			print('MQTT error:', err)
		end
})
end


function ShapeAndSendData(client,jdx)

	--Make sure the array exists
	if not temp[jdx] then
		temp[jdx]={}
	end		
	
	if (jdx==Serial and config.sim_data[Serial].Simulated==1 and not arg[1]) then
		print ("not able to send simulated serial")
	elseif (jdx==Serial and config.sim_data[Serial].Simulated==1 and arg[1]) or 
		   (jdx==Mqtt and config.sim_data[Mqtt].Simulated==1) then
		--print (jdx)
		local Output =""
		local nrOfSensors=0
		if jdx==Serial then			
			nrOfSensors=config.NumberOfSensors
			--open the port for write				
			VirtualSerialPort, err = io.open("/dev/pts/".. arg[1], "w")
			if not VirtualSerialPort then
				print("Error opening /dev/pts/".. arg[1].. ":", err)
				return
			end
		elseif jdx==Mqtt then
			nrOfSensors=config.sim_data[Mqtt].NumberOfSensors	
			--Start the mqtt header
			Output = brfUtils.MqttHeader()	
		end
		for idx=1,nrOfSensors do
			--Make sure the sub array is exists
			if not temp[jdx][idx] then
				temp[jdx][idx]=0
			end
			--Make the temperature go up slowly
			if CurrTime< startTime+30 then
				--print ("still Early")
				NextToAddMin=2
				NextToAddMax=math.floor(2*config.sim_data[jdx].temperature_Min/(config.sim_data[jdx].temperature_from_zero_to_min_time/SleepTime))
				NextToAdd=(math.random(NextToAddMin,NextToAddMax))
				temp[jdx][idx]=temp[jdx][idx]+NextToAdd
				if temp[jdx][idx]>config.sim_data[jdx].temperature_Max then
					randomFix(jdx,idx)
				end
			else
				--print ("late")
				randomFix(jdx,idx)		
			end
			--print (NextToAddMin)
			--print (NextToAddMax)				
			
			--print  (config.sim_data[jdx].ConnectionType .. " sensor" .. idx.."  :".. temp[jdx][idx])		
			--print(NextToAdd)
		
			if jdx==Serial then
				--Serial data				
				--print ("serial sim /dev/pts/" .. arg[1] )
				--print  (idx)
				--print  (temp[jdx][idx]) 
				Output ="sensor " .. idx .. " :" .. temp[jdx][idx]
				-- print ("serial" .. Output)
				VirtualSerialPort:write(Output .. "\n")
				
				
			elseif jdx==Mqtt then 
				--mqtt data								

				Output = Output .. brfUtils.Indent(1) .. '"DS18B20-' .. idx ..'": {\n'

				Output = Output .. brfUtils.Indent(2) ..'"Temperature": ' .. temp[jdx][idx] .. '\n'		
				Output = Output .. brfUtils.Indent(1) .. '}'
				if idx < nrOfSensors then
					Output = Output ..',\n'
				else
					Output = Output ..'\n'
				end					
				--print ('"DS18B20-' .. idx ..':  ' .. temp[jdx][idx]  ) 
				
				
				--print ("mqtt" .. Output)
				--client:publish('stat'.. config.sim_data[Mqtt].Topic_String , Output, mqtt.QOS0)
				LastTimeMqtt = runtime				
			end
		end
		if jdx==Serial and VirtualSerialPort then
			--close the serial port 
			VirtualSerialPort:flush()
			VirtualSerialPort:close()
		elseif jdx==Mqtt then 
			--now we close the json string
			Output=Output.."}"
			print ("mqtt Output: " .. Output)
			client:publish('stat'.. config.sim_data[Mqtt].Topic_String , Output, mqtt.QOS0)
		end	
	
	end
	--time ticks
	if jdx==Serial then
		LastTimeSerial=runtime
	elseif jdx==Mqtt then 
		LastTimeMqtt = runtime
	end
		
end





--start the mqtt client, restart if it chrashes
eco.run(function(name)		
	while true do 
		client:run()
		time.sleep(5)
	end
end,'eco1')


--resend every polltime/2 sec
eco.run(function(name)	
	while true do	
		CurrTime = os.time()
		runtime=CurrTime-startTime
		--print  ("runtime " .. runtime)
		--For both sensors
		for jdx=1,2 do
			--See if we need to run this now
			if (jdx==Serial and  LastTimeSerial+SleepTime<=runtime) or
			(jdx==Mqtt and  LastTimeMqtt+config.PollTime<=runtime) then
				ShapeAndSendData(client,jdx)
			end
		end
		--print(arg[1])
	  time.sleep(1)
  end
end,eco2)

