--brfUtils
local M ={}
--[[
Functions included
AddToTableByIdx
DS18B20ID
ExecuteToPID
Indent
MqttHeader
PrintTable
TblCount
Timestamp

]]
function M.AddToTableByIdx(tbl, idx, value)
	tbl[idx] = value
end

function M.DS18B20ID(numberOfSensors,Seed)
	local output={}

	--See if the parameters are given
	numberOfSensors=numberOfSensors or 1
	Seed=Seed or 234567
	
	--Start seeding
	math.randomseed(Seed)
	
	for SensNum =1,numberOfSensors do
		local id = "28"
		local randnum=0
		local idAdd=""
		for i = 1, 6 do			
			randnum=math.random(0, 255)
			idAdd=string.format("%02X", randnum)
			id = id .. idAdd
			--print (SensNum .. ":" .. i .. ":" ..randnum ..":"..idAdd)
		end		
		id = id .. string.format("%02X", math.random(0, 255)) -- CRC byte		
		--print ("id"..SensNum .. ":"..id)
	M.AddToTableByIdx(output,SensNum,id)

	end
	--M.PrintTable(output)
	return output
end

function M.ExecuteToPID(cmd,PathToPidFile)
	if PathToPidFile then
		cmdEx = "sh -c '".. cmd .." & echo $! > "  .. pidfile .. "'"
	else
		cmdEx = cmd
	endif
	os.execute(cmdEx)
end

function M.Indent(indentlevel,Chars)
	--Set the defaults
	indentlevel=indentlevel or 1
	Chars=Chars or "  "	
	return string.rep(Chars, indentlevel)
end


function M.MqttHeader()
	--Format output as json for mqtt
	Output = "{\n"
	Output = Output ..M.Indent(1)..'"Time": "' ..  M.Timestamp() ..'",\n'	
	return Output
end

function M.PrintTable(tbl)
    for key, value in pairs(tbl) do
        print(key, value)
    end
end

function M.TblCount(tbl)
    local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function M.Timestamp()
	local handle = io.popen("date -Iseconds")
	local timestamp = handle:read("*a"):gsub("\n", "")
	handle:close()
	return timestamp
end




return M