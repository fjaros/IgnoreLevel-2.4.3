-- https://github.com/fjaros/IgnoreLevel-2.4.3

WhiteList = {}
LevelBoundary = 10
Debug = 0

local queue = {}
local sendWhoQueue = {}
local lastWhoCheck = 0
local lastWhoTimeout = 5 -- time to label the who request as from us (sec)
local whoCheckCooldown = 10 -- time to wait between /who requests (sec)
local cacheTime = 60 -- time to keep a player's level in cache (sec)


-- HOOKS
-- Regular callback listener for OnUpdate
FRAME = CreateFrame("FRAME")
FRAME:SetScript("OnUpdate",
        function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		local time = GetTime()
		if (time - lastWhoCheck >= whoCheckCooldown and next(sendWhoQueue)) then
			lastWhoCheck = time
			local s = ""
			for i = 1, 2 do
				if (next(sendWhoQueue) == nil) then
					break
				end
				s = s .. table.remove(sendWhoQueue)
				if (i < 2) then
					s = s .. " "
				end
			end
			SetWhoToUI(0)
			SendWho(s)
		end
		-- sanity check in case some queue'd names never dequeued
		if (self.elapsed >= 10) then
			self.elapsed = 0

			for name, tbl in pairs(queue) do
				if (time - tbl["time"] > lastWhoTimeout and tbl["level"] == nil) then
					-- never dequeued, requeue to sendWho
					tbl["time"] = time
					queue[name] = tbl
					table.insert(sendWhoQueue, name)
				end
			end
		end
	end
)

-- Need to override ElvUI and default Blizzard frame functions
-- If there is a better way to do this, that would be great...
local orig_ChatFrame_OnEvent
local CH
if (ElvUI) then
        local E, L, V, P, G = unpack(ElvUI)
	CH = E:GetModule("Chat")
	orig_ChatFrame_OnEvent = CH.ChatFrame_MessageEventHandler
	CH.ChatFrame_MessageEventHandler = 
		function(self, chat, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, isHistory, historyTime, historyName)
			local args = {}
			args["self"] = self
			args["chat"] = chat
			args["arg3"] = arg3
			args["arg4"] = arg4
			args["arg5"] = arg5
			args["arg6"] = arg6
			args["arg7"] = arg7
			args["arg8"] = arg8
			args["arg9"] = arg9
			args["arg10"] = arg10
			args["arg11"] = arg11
			args["isHistory"] = isHistory
			args["historyTime"] = historyTime
			args["historyName"] = historyName
			IgnoreLevel_handler(event, arg2, arg1, args)
		end
else
	orig_ChatFrame_OnEvent = ChatFrame_OnEvent
	ChatFrame_OnEvent = 
		function(event)
			IgnoreLevel_handler(event, arg2, arg1)
		end
end


local function shouldFilter(name)
        local tbl = queue[name]
        return WhiteList[strlower(name)] == nil and tbl["level"] > 0 and tbl["level"] <= LevelBoundary
end

local function onNewUserWhisper(name, message, args)
	local tbl = {}
	tbl["time"] = GetTime()
	tbl["messages"] = {}
	local messageTuple = {}
	messageTuple["message"] = message
	messageTuple["args"] = args
	table.insert(tbl["messages"], messageTuple)
	queue[name] = tbl
	table.insert(sendWhoQueue, name)
	-- Actual sending of who command will be handled in timer
end

local function insertMessage(event, name, message, args)
	if (ElvUI) then
		orig_ChatFrame_OnEvent(args["self"], args["chat"], event, message, name,
			args["arg3"], args["arg4"], args["arg5"], args["arg6"], args["arg7"],
			args["arg8"], args["arg9"], args["arg10"], args["arg11"],
			args["isHistory"], args["historyTime"], args["historyName"]
		)
	else
		arg1 = message
		arg2 = name
		orig_ChatFrame_OnEvent(event)
	end
end

function IgnoreLevel_handler(event, name, message, args)
	if (event == "CHAT_MSG_SYSTEM" and type(message) == "string") then
		local name, level = string.match(message, "|Hplayer:(%a+)|h%[%a+%]|h: Level (%d+)")
		if (name and level) then
			local isOurRequest = GetTime() - lastWhoCheck < lastWhoTimeout
			if (queue[name] and isOurRequest) then
				queue[name]["level"] = tonumber(level)
				if (shouldFilter(name)) then
					if (Debug == 1) then
						DEFAULT_CHAT_FRAME:AddMessage("Ignore Level Debug - Ignoring " .. name .. " - Received who as low level.")
					end
				else

					for _, messageTuple in ipairs(queue[name]["messages"]) do
						insertMessage("CHAT_MSG_WHISPER", name, messageTuple["message"], messageTuple["args"])
					end
				end
				queue[name]["messages"] = {}
			else
				-- Not our request, pass through
				insertMessage(event, name, message, args)
			end
		else
			local players = string.match(message, "(%d+) |4player:player[s]?; total")
			if (players) then
				local num = tonumber(players)
				if (GetTime() - lastWhoCheck < lastWhoTimeout) then
					-- script check recently, so should filter it out
				else
					-- Seems last who check wasn't by us, pass through
					insertMessage(event, name, message, args)
				end
				lastWhoCheck = GetTime()
			else
				-- Irrelevant message, pass through
				insertMessage(event, name, message, args)
			end
		end
	elseif (event == "CHAT_MSG_WHISPER" and type(name) == "string" and type(message) == "string") then
		if (name == UnitName("player") or WhiteList[strlower(name)]) then
			-- Whitelisted
			insertMessage(event, name, message, args)
		elseif (queue[name]) then
			-- Already has user information
			local tbl = queue[name]
			if (tbl["level"] == nil) then
				-- Already fired /who but haven't gotten response, add to list
				local messageTuple = {}
				messageTuple["message"] = message
				messageTuple["args"] = args
				table.insert(tbl["messages"], messageTuple)
			else
				-- Has level, check if stale
				if (GetTime() - tbl["time"] > cacheTime) then
					-- stale level
					onNewUserWhisper(name, message, args)
				else
					-- can use cached level
					if (shouldFilter(name)) then
						if (Debug == 1) then
							DEFAULT_CHAT_FRAME:AddMessage("Ignore Level Debug - Ignoring " .. name .. " - Cached as low level.")
						end
					else
						insertMessage(event, name, message, args)
					end
				end
			end
		else
			-- New user whisper
			onNewUserWhisper(name, message, args)
		end
	else		
		insertMessage(event, name, message, args)
	end
end

SLASH_IGNORELEVEL1 = "/ignorelevel"
SlashCmdList["IGNORELEVEL"] = function(arg)
	if (arg and tonumber(arg)) then
		LevelBoundary = tonumber(arg)
		DEFAULT_CHAT_FRAME:AddMessage("IgnoreLevel - Set new filter to <= " .. LevelBoundary .. " characters.") 
	else
		DEFAULT_CHAT_FRAME:AddMessage("IgnoreLevel - Filtering Level <= " .. LevelBoundary .. " characters.")
	end
end

SLASH_IGNOREWHITELIST1 = "/ignorewhitelist"
SlashCmdList["IGNOREWHITELIST"] = function(arg)
	if (arg and arg ~= "") then
		local cmd, name = strsplit(" ", arg, 2)
		local lowerCmd = strlower(cmd)
		local lowerName = strlower(name)
		if (lowerCmd == "add") then
			WhiteList[lowerName] = true
		elseif (lowerCmd == "del") then
			WhiteList[lowerName] = nil
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage - /ignorewhitelist add <name> or /ignorewhitelist del <name>")
		end
	else
		if (next(WhiteList)) then
			local s = ""
			for name, _ in pairs(WhiteList) do
				s = s .. name .. ", "
			end
			DEFAULT_CHAT_FRAME:AddMessage("Ignore Whitelist: " .. string.sub(s, 1, -3))
		else
			DEFAULT_CHAT_FRAME:AddMessage("Your ignore whitelist is empty. Usage - /ignorewhitelist add <name> or /ignorewhitelist del <name>")
		end
	end
end

SLASH_IGNOREDEBUG1 = "/ignoredebug"
SlashCmdList["IGNOREDEBUG"] = function(arg)
	if (arg and tonumber(arg)) then
		if (tonumber(arg) == 1) then
			Debug = 1
			DEFAULT_CHAT_FRAME:AddMessage("Ignore Level Debugging Enabled")
		else
			Debug = 0
			DEFAULT_CHAT_FRAME:AddMessage("Ignore Level Debugging Disabled")
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage - /ignoredebug 1/0")
	end
end
