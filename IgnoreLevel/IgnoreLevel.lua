-- https://github.com/fjaros/IgnoreLevel-2.4.3

WhiteList = {}
LevelBoundary = 10
Debug = 0
Quotes = 0

local queue = {}
local sendWhoQueue = {}
local lastWhoCheck = 0
local lastWhoTimeout = 5 -- time to label the who request as from us (sec)
local whoCheckCooldown = 10 -- time to wait between /who requests (sec)
local cacheTime = 60 -- time to keep a player's level in cache (sec)

local quotes = {"Life isn’t about getting and having, it’s about giving and being. - Kevin Kruse", "Whatever the mind of man can conceive and believe, it can achieve. - Napoleon Hill", "Strive not to be a success, but rather to be of value. - Albert Einstein", "Two roads diverged in a wood, and I—I took the one less traveled by, And that has made all the difference. - Robert Frost", "I attribute my success to this: I never gave or took any excuse. - Florence Nightingale", "You miss 100% of the shots you don’t take. - Wayne Gretzky", "I’ve missed more than 9000 shots in my career. I’ve lost almost 300 games. 26 times I’ve been trusted to take the game winning shot and missed. I’ve failed over and over and over again in my life. And that is why I succeed. - Michael Jordan", "The most difficult thing is the decision to act, the rest is merely tenacity. - Amelia Earhart", "Every strike brings me closer to the next home run. - Babe Ruth", "Definiteness of purpose is the starting point of all achievement. - W. Clement Stone", "We must balance conspicuous consumption with conscious capitalism. - Kevin Kruse", "Life is what happens to you while you’re busy making other plans. - John Lennon", "We become what we think about. - Earl Nightingale", "Twenty years from now you will be more disappointed by the things that you didn’t do than by the ones you did do, so throw off the bowlines, sail away from safe harbor, catch the trade winds in your sails.  Explore, Dream, Discover. - Mark Twain", "Life is 10% what happens to me and 90% of how I react to it. - Charles Swindoll", "The most common way people give up their power is by thinking they don’t have any. - Alice Walker", "The mind is everything. What you think you become. - Buddha", "The best time to plant a tree was 20 years ago. The second best time is now. - Chinese Proverb", "An unexamined life is not worth living. - Socrates", "Eighty percent of success is showing up. - Woody Allen", "Your time is limited, so don’t waste it living someone else’s life. - Steve Jobs", "Winning isn’t everything, but wanting to win is. - Vince Lombardi", "I am not a product of my circumstances. I am a product of my decisions. - Stephen Covey", "Every child is an artist.  The problem is how to remain an artist once he grows up. - Pablo Picasso", "You can never cross the ocean until you have the courage to lose sight of the shore. - Christopher Columbus", "I’ve learned that people will forget what you said, people will forget what you did, but people will never forget how you made them feel. - Maya Angelou", "Either you run the day, or the day runs you. - Jim Rohn", "Whether you think you can or you think you can’t, you’re right. - Henry Ford", "The two most important days in your life are the day you are born and the day you find out why. - Mark Twain", "Whatever you can do, or dream you can, begin it.  Boldness has genius, power and magic in it. - Johann Wolfgang von Goethe", "The best revenge is massive success. - Frank Sinatra", "People often say that motivation doesn’t last. Well, neither does bathing.  That’s why we recommend it daily. - Zig Ziglar", "Life shrinks or expands in proportion to one’s courage. - Anais Nin", "If you hear a voice within you say “you cannot paint,” then by all means paint and that voice will be silenced. - Vincent Van Gogh", "There is only one way to avoid criticism: do nothing, say nothing, and be nothing. - Aristotle", "Ask and it will be given to you; search, and you will find; knock and the door will be opened for you. - Jesus", "The only person you are destined to become is the person you decide to be. - Ralph Waldo Emerson", "Go confidently in the direction of your dreams.  Live the life you have imagined. - Henry David Thoreau", "When I stand before God at the end of my life, I would hope that I would not have a single bit of talent left and could say, I used everything you gave me. - Erma Bombeck", "Few things can help an individual more than to place responsibility on him, and to let him know that you trust him. - Booker T. Washington", "Certain things catch your eye, but pursue only those that capture the heart. -  Ancient Indian Proverb", "Believe you can and you’re halfway there. - Theodore Roosevelt", "Everything you’ve ever wanted is on the other side of fear. - George Addair", "We can easily forgive a child who is afraid of the dark; the real tragedy of life is when men are afraid of the light. - Plato", "Teach thy tongue to say, “I do not know,” and thous shalt progress. - Maimonides", "Start where you are. Use what you have.  Do what you can. - Arthur Ashe", "When I was 5 years old, my mother always told me that happiness was the key to life.  When I went to school, they asked me what I wanted to be when I grew up.  I wrote down ‘happy’.  They told me I didn’t understand the assignment, and I told them they didn’t understand life. - John Lennon", "Fall seven times and stand up eight. - Japanese Proverb", "When one door of happiness closes, another opens, but often we look so long at the closed door that we do not see the one that has been opened for us. - Helen Keller", "Everything has beauty, but not everyone can see. - Confucius", "How wonderful it is that nobody need wait a single moment before starting to improve the world. - Anne Frank", "When I let go of what I am, I become what I might be. - Lao Tzu", "Life is not measured by the number of breaths we take, but by the moments that take our breath away. - Maya Angelou", "Happiness is not something readymade.  It comes from your own actions. - Dalai Lama", "If you’re offered a seat on a rocket ship, don’t ask what seat! Just get on. - Sheryl Sandberg", "First, have a definite, clear practical ideal; a goal, an objective. Second, have the necessary means to achieve your ends; wisdom, money, materials, and methods. Third, adjust all your means to that end. - Aristotle", "If the wind will not serve, take to the oars. - Latin Proverb", "You can’t fall if you don’t climb.  But there’s no joy in living your whole life on the ground. - Unknown", "We must believe that we are gifted for something, and that this thing, at whatever cost, must be attained. - Marie Curie", "Too many of us are not living our dreams because we are living our fears. - Les Brown", "Challenges are what make life interesting and overcoming them is what makes life meaningful. - Joshua J. Marine", "If you want to lift yourself up, lift up someone else. - Booker T. Washington", "I have been impressed with the urgency of doing. Knowing is not enough; we must apply. Being willing is not enough; we must do. - Leonardo da Vinci", "Limitations live only in our minds.  But if we use our imaginations, our possibilities become limitless. - Jamie Paolinetti", "You take your life in your own hands, and what happens? A terrible thing, no one to blame. - Erica Jong", "What’s money? A man is a success if he gets up in the morning and goes to bed at night and in between does what he wants to do. - Bob Dylan", "I didn’t fail the test. I just found 100 ways to do it wrong. - Benjamin Franklin", "In order to succeed, your desire for success should be greater than your fear of failure. - Bill Cosby", "A person who never made a mistake never tried anything new. -  Albert Einstein", "The person who says it cannot be done should not interrupt the person who is doing it. - Chinese Proverb", "There are no traffic jams along the extra mile. - Roger Staubach", "It is never too late to be what you might have been. - George Eliot", "You become what you believe. - Oprah Winfrey", "I would rather die of passion than of boredom. - Vincent van Gogh", "A truly rich man is one whose children run into his arms when his hands are empty. - Unknown", "It is not what you do for your children, but what you have taught them to do for themselves, that will make them successful human beings. - Ann Landers", "If you want your children to turn out well, spend twice as much time with them, and half as much money. - Abigail Van Buren", "Build your own dreams, or someone else will hire you to build theirs. - Farrah Gray", "The battles that count aren’t the ones for gold medals. The struggles within yourself–the invisible battles inside all of us–that’s where it’s at. - Jesse Owens", "Education costs money.  But then so does ignorance. - Sir Claus Moser", "I have learned over the years that when one’s mind is made up, this diminishes fear. - Rosa Parks", "It does not matter how slowly you go as long as you do not stop. - Confucius", "If you look at what you have in life, you’ll always have more. If you look at what you don’t have in life, you’ll never have enough. - Oprah Winfrey", "Remember that not getting what you want is sometimes a wonderful stroke of luck. - Dalai Lama", "You can’t use up creativity.  The more you use, the more you have. - Maya Angelou", "Dream big and dare to fail. - Norman Vaughan", "Our lives begin to end the day we become silent about things that matter. - Martin Luther King Jr.", "Do what you can, where you are, with what you have. - Teddy Roosevelt", "If you do what you’ve always done, you’ll get what you’ve always gotten. - Tony Robbins", "Dreaming, after all, is a form of planning. - Gloria Steinem", "It’s your place in the world; it’s your life. Go on and do all you can with it, and make it the life you want to live. - Mae Jemison", "You may be disappointed if you fail, but you are doomed if you don’t try. - Beverly Sills", "Remember no one can make you feel inferior without your consent. - Eleanor Roosevelt", "Life is what we make it, always has been, always will be. - Grandma Moses", "The question isn’t who is going to let me; it’s who is going to stop me. - Ayn Rand", "When everything seems to be going against you, remember that the airplane takes off against the wind, not with it. - Henry Ford", "It’s not the years in your life that count. It’s the life in your years. - Abraham Lincoln", "Change your thoughts and you change your world. - Norman Vincent Peale", "Either write something worth reading or do something worth writing. - Benjamin Franklin", "Nothing is impossible, the word itself says, “I’m possible!” - Audrey Hepburn", "The only way to do great work is to love what you do. - Steve Jobs", "If you can dream it, you can achieve it. - Zig Ziglar"}

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
					elseif (Quotes == 1) then
						DEFAULT_CHAT_FRAME:AddMessage(quotes[math.random(table.getn(quotes)])
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
						elseif (Quotes == 1) then
							DEFAULT_CHAT_FRAME:AddMessage(quotes[math.random(table.getn(quotes)])
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

SLASH_IGNOREQUOTES1 = "/ignorequotes"
SlashCmdList["IGNOREQUOTES"] = function(arg)
	DEFAULT_CHAT_FRAME:AddMessage(_G["CHAT_MSG_SAY"] ~= nil)
	if (arg and tonumber(arg)) then
		if (tonumber(arg) == 1) then
			Quotes = 1
			DEFAULT_CHAT_FRAME:AddMessage("Quotes Enabled")
		else
			Quotes = 0
			DEFAULT_CHAT_FRAME:AddMessage("Quotes Disabled")
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage - /ignorequotes 1/0")
	end
end