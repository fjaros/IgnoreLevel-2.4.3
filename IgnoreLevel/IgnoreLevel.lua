-- https://github.com/fjaros/IgnoreLevel-2.4.3

WhiteList = {}
LevelBoundary = 10
IgnoreParty = 1
Debug = 0

local queue = {}
local sendWhoQueue = {}
local currentWhoCheck = {}
local lastWhoCheck = GetTime() -- set as GetTime() to give server time to add a freshly logging in player to who list
local lastWhoTimeout = 5 -- time to label the who request as from us (sec)
local whoCheckCooldown = 10 -- time to wait between /who requests (sec)
local cacheTime = 60 -- time to keep a player's level in cache (sec)

local partyInviteChatWindow

-- HOOKS
-- We cannot use ChatFrame_AddMessageEventFilter API because ElvUI does not pass self/chatframe context to this function
-- When we decide on who response whether or not to allow the message, we will not know which chatframe to send it to.
IgnoreLevel_defaultHandler =
	function(event)
		local args = {}
		if (WIM_MessageEventHandler) then
			args["chat"] = DEFAULT_CHAT_FRAME
		else
			args["chat"] = this
		end
		args["arg3"] = arg3
		args["arg4"] = arg4
		args["arg5"] = arg5
		args["arg6"] = arg6
		args["arg7"] = arg7
		args["arg8"] = arg8
		args["arg9"] = arg9
		IgnoreLevel_handler(event, arg2, arg1, args)
	end
local orig_Chat_handler = ChatFrame_OnEvent
ChatFrame_OnEvent = IgnoreLevel_defaultHandler


local function shouldFilter(name)
        local tbl = queue[name]
        return WhiteList[strlower(name)] == nil and tbl["level"] > 0 and tbl["level"] <= LevelBoundary
end

local function onNewPartyInvite(name)
	local tbl = {}
	tbl["time"] = GetTime()
	tbl["isParty"] = true
	queue[name] = tbl
	table.insert(sendWhoQueue, name)
	-- Actual sending of who command will be handled in timer
end


local orig_UIParent_OnEvent = UIParent_OnEvent
local function showPartyInvite(name)
	arg1 = name
	orig_UIParent_OnEvent("PARTY_INVITE_REQUEST")
	local info = ChatTypeInfo["SYSTEM"]
	partyInviteChatWindow:AddMessage("|Hplayer:" .. name .. "|h[" .. name .. "]|h has invited you to join a group.", info.r, info.g, info.b, info.id)
end

UIParent_OnEvent = function(event)
	if (IgnoreParty == 1 and event == "PARTY_INVITE_REQUEST") then
		name = arg1
		if (WhiteList[strlower(name)]
			or string.len(name) < 4) then
			-- Whitelisted
			showPartyInvite(name)
		elseif (queue[name]) then
			local tbl = queue[name]
			if (tbl["level"]) then
				if (shouldFilter(name)) then
					DeclineGroup()
					if (Debug == 1) then
						DEFAULT_CHAT_FRAME:AddMessage("Ignore Level Debug - Ignoring " .. name .. " - Cached as low level.")
					end
				else
					showPartyInvite(name)
				end
			else
				-- Just ignore if we have don't yet have level but they are spamming us with invites
				DeclineGroup()
				if (Debug == 1) then
					DEFAULT_CHAT_FRAME:AddMessage("Ignore Level Debug - Ignoring " .. name .. " - Party invite spam.")
				end
			end
		else
			onNewPartyInvite(arg1)
		end
	else
		orig_UIParent_OnEvent(event)
	end
end


local function parseWhoMessage(message)
	return string.match(message, "|Hplayer:(%a+)|h%[%a+%]|h: Level (%d+)")
end

local function parsePlayersMessage(message)
	return string.match(message, "(%d+) |4player:player[s]?; total")
end

local function parseGroupInviteMessage(message)
	return string.match(message, "|Hplayer:(%a+)|h%[%a+%]|h has invited you to join a group.")
end

local isHooked
local function IgnoreLevel_tryHook()
	if (isHooked) then
		return
	end

	if (ElvUI) then
		-- found ElvUI
	        local E, L, V, P, G = unpack(ElvUI)
		local CH = E:GetModule("Chat")
		ChatFrame_OnEvent = orig_Chat_handler
		orig_Chat_handler = CH.ChatFrame_MessageEventHandler
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
		isHooked = true
	elseif (WIM_MessageEventHandler) then
		-- found WIM
		ChatFrame_OnEvent = orig_Chat_handler
		orig_Chat_handler = WIM_MessageEventHandler
		WIM_MessageEventHandler = IgnoreLevel_defaultHandler
		local orig_WIM_ChatFrame_MessageEventFilter_SYSTEM = WIM_ChatFrame_MessageEventFilter_SYSTEM
		WIM_ChatFrame_MessageEventFilter_SYSTEM =
			function(message)
				local groupInviter = parseGroupInviteMessage(message)
				if (groupInviter) then
					return true, message
				end

				if (GetTime() - lastWhoCheck < 1) then
					-- need to filter out so doesn't display in default window
					local name, level = parseWhoMessage(message)
					if (name and level) then
						return true, message
					end

					local players = parsePlayersMessage(message)
					if (players) then
						return true, message
					end
				end
				return orig_WIM_ChatFrame_MessageEventFilter_SYSTEM(message)
			end
		isHooked = true
	end
end

FRAME = CreateFrame("FRAME")
FRAME:RegisterEvent("ADDON_LOADED")
FRAME:SetScript("OnEvent", IgnoreLevel_tryHook)

-- Regular callback listener for OnUpdate
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
				local name = table.remove(sendWhoQueue)
				currentWhoCheck[name] = true
				s = s .. name
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


local function onNewUserWhisper(event, name, message, args)
	local tbl = {}
	tbl["time"] = GetTime()
	tbl["messages"] = {}
	local messageTuple = {}
	messageTuple["event"] = event
	messageTuple["message"] = message
	messageTuple["args"] = args
	table.insert(tbl["messages"], messageTuple)
	queue[name] = tbl
	table.insert(sendWhoQueue, name)
	-- Actual sending of who command will be handled in timer
end

local function insertMessage(event, name, message, args)
	if (ElvUI) then
		orig_Chat_handler(args["self"], args["chat"], event, message, name,
			args["arg3"], args["arg4"], args["arg5"], args["arg6"], args["arg7"],
			args["arg8"], args["arg9"], args["arg10"], args["arg11"],
			args["isHistory"], args["historyTime"], args["historyName"]
		)
	else
		this = args["chat"]
		arg1 = message
		arg2 = name
		arg3 = args["arg3"]
		arg4 = args["arg4"]
		arg5 = args["arg5"]
		arg6 = args["arg6"]
		arg7 = args["arg7"]
		arg8 = args["arg8"]
		arg9 = args["arg9"]
		orig_Chat_handler(event)
	end
end

local eventFilterTable = {}
eventFilterTable["CHAT_MSG_EMOTE"] = true
eventFilterTable["CHAT_MSG_SAY"] = true
eventFilterTable["CHAT_MSG_WHISPER"] = true
eventFilterTable["CHAT_MSG_YELL"] = true
function IgnoreLevel_handler(event, name, message, args)
	if (event == "CHAT_MSG_SYSTEM" and type(message) == "string") then
		local name, level = parseWhoMessage(message)
		if (name and level) then
			local isOurRequest = GetTime() - lastWhoCheck < lastWhoTimeout
			if (queue[name] and isOurRequest) then
				currentWhoCheck[name] = nil
				queue[name]["time"] = GetTime()
				queue[name]["level"] = tonumber(level)
				if (shouldFilter(name)) then
					if (queue[name]["isParty"]) then
						DeclineGroup()
					end
					if (Debug == 1) then
						args["chat"]:AddMessage("Ignore Level Debug - Ignoring " .. name .. " - Received who as low level.")
					end
				else
					if (queue[name]["isParty"]) then
						showPartyInvite(name)
					else
						for _, messageTuple in ipairs(queue[name]["messages"]) do
							insertMessage(messageTuple["event"], name, messageTuple["message"], messageTuple["args"])
						end
					end
				end
				queue[name]["messages"] = {}
			else
				-- Not our request, pass through
				insertMessage(event, name, message, args)
			end
		else
			local players = parsePlayersMessage(message)
			if (players) then
				local num = tonumber(players)
				if (GetTime() - lastWhoCheck < lastWhoTimeout) then
					-- script check recently, so should filter it out
					-- remove any offline names for which we didn't get who response
					for k, _ in pairs(currentWhoCheck) do
						if (Debug == 1) then
							args["chat"]:AddMessage("Ignore Level Debug - Ignoring " .. k .. " - Did not receive who response.")
						end
						queue[k] = nil
					end
					currentWhoCheck = {}
				else
					-- Seems last who check wasn't by us, pass through
					insertMessage(event, name, message, args)
				end
				lastWhoCheck = GetTime()
			else
				local groupInviter = parseGroupInviteMessage(message)
				if (groupInviter) then
					-- Save for later
					partyInviteChatWindow = args["chat"]
				else
					-- Irrelevant message, pass through
					insertMessage(event, name, message, args)
				end
			end
		end
	elseif (eventFilterTable[event] and type(name) == "string" and type(message) == "string") then
		-- Just WhiteList ElvUI history. We cannot query level if player is already offline.
		if (name == UnitName("player")
			or WhiteList[strlower(name)]
			or args["isHistory"] == "ElvUI_ChatHistory"
			or string.len(name) < 4) then
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
					onNewUserWhisper(event, name, message, args)
				else
					-- can use cached level
					if (shouldFilter(name)) then
						if (Debug == 1) then
							args["chat"]:AddMessage("Ignore Level Debug - Ignoring " .. name .. " - Cached as low level.")
						end
					else
						insertMessage(event, name, message, args)
					end
				end
			end
		else
			-- New user whisper
			onNewUserWhisper(event, name, message, args)
		end
	else		
		insertMessage(event, name, message, args)
	end
end


SLASH_IGNORELEVEL1 = "/ignorelevel"
SlashCmdList["IGNORELEVEL"] = function(arg)
	if (arg and tonumber(arg)) then
		LevelBoundary = tonumber(arg)
		DEFAULT_CHAT_FRAME:AddMessage("IgnoreLevel - Set new filter to level <= " .. LevelBoundary .. " characters.")
	else
		DEFAULT_CHAT_FRAME:AddMessage("IgnoreLevel - Filtering level <= " .. LevelBoundary .. " characters.")
	end
end

SLASH_IGNOREPARTY1 = "/ignoreparty"
SlashCmdList["IGNOREPARTY"] = function(arg)
	if (arg and tonumber(arg)) then
		if (tonumber(arg) == 1) then
			IgnoreParty = 1
			DEFAULT_CHAT_FRAME:AddMessage("IgnoreLevel - Ignoring party invites from level <= " .. LevelBoundary .. " characters enabled.")
		else
			IgnoreParty = 0
			DEFAULT_CHAT_FRAME:AddMessage("IgnoreLevel - Ignoring party invites disabled.")
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage - /ignoreparty 1/0")
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
