local API = require"GPT-3-5.API"
local OOP = require"Moonrise.OOP"

---@class API.Bot
---@operator call:API.Bot
---@field Key string
---@field History API.Message[]
---@field MinResponseTokens integer
---@field MaxTokens integer
local Bot = OOP.Declarator.Shortcuts"API.Bot"

---@param Instance API.Bot
---@param Key string
---@param History API.Message[]
---@param MinResponseTokens integer|nil
---@param MaxTokens integer|nil
function Bot:Initialize(Instance, Key, History, MinResponseTokens, MaxTokens)
	Instance.Key = Key
	Instance.History = History or {}
	Instance.MinResponseTokens = MinResponseTokens or 1000
	Instance.MaxTokens = MaxTokens or 4097
end

---@param Content string
---@param Role API.Message.Role
---@return boolean
---@return string
---@return API.Usage
---@return integer | nil
---@return integer | nil
function Bot:Send(Content, Role)
	table.insert(self.History, API.Message(Content, Role))
	
	local PrunedHistory = {}
	local TotalTokens=3
	for Index = #self.History, 1, -1 do
		local Message = self.History[Index]
		
		local TokenCount = API.CountMessageTokens(Message)
		local NextTotal = TotalTokens + TokenCount
		local NextTokensLeft = self.MaxTokens - NextTotal
		
		if NextTokensLeft < self.MinResponseTokens then
			print"Pruned something"
			break
		else
			table.insert(PrunedHistory, 1, Message)
			TotalTokens = NextTotal
		end
	end
	
	local Success, Response, Usage = API.GetResponse(self.Key, PrunedHistory)
	
	if Success then
		local CompletionTokenCount = API.CountContentTokens(Response.content)
		local PromptTokenCount = API.CountChatTokens(self.History)
		table.insert(self.History, Response)
		return true, Response.content, Usage, PromptTokenCount, CompletionTokenCount
	else
		return false, Response, Usage
	end
end

return Bot
-- Test the function with a sample prompt
--[[]]
