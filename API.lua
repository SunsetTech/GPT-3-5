local https = require "ssl.https"
local ltn12 = require "ltn12"
local dkjson = require "dkjson"
local Posix = require"Moonrise.Tools.Posix"
local posix = require"posix"

---@alias API.Message.Role '"system"' | '"user"' | '"assistant"'
---@class API.Message
---@field role API.Message.Role
---@field content string

---@class API.Usage
---@field completion_tokens integer
---@field prompt_tokens integer
---@field total_tokens integer

local API={}

---@param Content string
---@return number?
function API.CountContentTokens(Content)
	local _, In, Out = Posix.BidirectionalOpen"/bin/GPT-3-5_TokenCount"
	posix.write(In, Content) --In:close()
	posix.close(In)
	local Count = Posix.ReadAll(Out)
	posix.close(Out)
	return tonumber(Count)
end

---@param Message API.Message
---@return number
function API.CountMessageTokens(Message)
	return API.CountContentTokens(Message.content) + 5
end

---@param History API.Message[]
function API.CountChatTokens(History)
	local Total = 0
	for _,Message in pairs(History) do
		local Count = API.CountMessageTokens(Message)
		Total = Total + Count
	end
	return Total + 3
end

---@param Content string
---@param Role API.Message.Role
---@return API.Message
function API.Message(Content, Role)
	return {role = Role or "user", content = Content}
end

---@param Key string
---@param Messages API.Message[]
---@param MaxTokens integer|nil
function API.GetResponse(Key, Messages, MaxTokens)
	local Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. Key
	}

	local Payload = {
		model = "gpt-3.5-turbo";
		messages = Messages;
		temperature = 0.7;
		max_tokens = MaxTokens;
	}

	local ResponseBody = {}
	local _, ResponseCode = https.request {
		url = "https://api.openai.com/v1/chat/completions",
		method = "POST",
		headers = Headers,
		source = ltn12.source.string(dkjson.encode(Payload)),
		sink = ltn12.sink.table(ResponseBody)
	}
	
	local Response = dkjson.decode(table.concat(ResponseBody))
	
	if ResponseCode == 200 then
		local GPT_Reply = Response.choices[1].message
		return true, GPT_Reply, Response.usage
	else
		print(table.concat(ResponseBody))
		return false, ResponseCode, Response
	end
end

return API
