local Serialization = {}

function SerializeUserData(UserData)
	local base = tostring(typeof(UserData))
	return base..".new("..tostring(UserData)..")"
end

function Serialization.SerializeTable(t)
	local totalString = "{\n"

	for i,v in pairs(t) do
		if typeof(v) == "Instance" then continue end

		local keyString = ""
		local valueString = ""

		if type(i) == "number" then
			keyString = "["..tostring(i).."]"
		else
			keyString = "['"..tostring(i).."']"
		end

		if type(v) == "userdata" then
			valueString = SerializeUserData(v)
		elseif type(v) == "table" then
			valueString = Serialization.SerializeTable(v)
		elseif type(v) == "number" or type(v) == "boolean" then
			valueString = tostring(v)
		elseif type(v) == "string" then
			valueString = "'"..tostring(v).."'"
		end

		totalString = totalString..keyString.." = "..valueString..",\n"
	end

	return totalString.."}\n"
end

return Serialization