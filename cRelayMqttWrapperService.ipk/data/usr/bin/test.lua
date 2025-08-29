#!/usr/bin/env lua

-- adding to path

package.path = package.path ..";/usr/lib/lua/?.lua"
local json = require "dkjson"

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


--read the config file
local config = load_config("/etc/cRelayMqttWrapperService.json")



local relayPath = ""
if config.Simulated==1 then
	relayPath = "/root/Packages/cRelayMqttWrapperService.ipk/data/usr/bin/cRelaySimulator.sh "
else	
	relayPath = "/usr/bin/crelay "
end


-- -- Create MQTT client
-- local client = mqtt.new({
--     ipaddr = '192.168.40.136',      -- Replace with your broker IP
--     port = 1883,               -- Or 8883 for TLS
-- 	username = 'Thing01',
-- 	password = 'nulle',
--     clean_session = true
-- })

function printTable(tbl, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(spacing .. tostring(key) .. ":")
            printTable(value, indent + 1)
        else
            print(spacing .. tostring(key) .. ": " .. tostring(value))
        end
    end
end

local function readnPublishRelayStates()		
	print ("sh ".. relayPath.. "-i")			
	local handle = io.popen("sh ".. relayPath.. "-i")			
	local result = handle:read("*a")
	handle:close()			
	--print (result)		
	-- Parse the output into a Lua table
	local relays = {}
	for line in result:gmatch("[^\r\n]+") do		
		local relay,state = line:match("(Relay%s%d+):%s*(%a+)")		
		if relay and state then		
			relays[relay] = state	
		end

	end	
	
	print (relays)
	-- Convert to JSON
	local result = json.encode({relays = relays}, {indent = true})
	print(result)

end

readnPublishRelayStates()