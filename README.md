# IgnoreLevel-2.4.3
AddOn for World of Warcraft 2.4.3 to filter out messages by character level.
It works on emote, say, whisper, and yell message types. **However it does not support channels.**

**After downloading, extract ONLY the IgnoreLevel folder into your AddOns folder.**

**So that you have: \<Root WoW Folder\>\\Interface\\AddOns\\IgnoreLevel\\IgnoreLevel.lua**

It works with ElvUI, WIM, Prat, and default Blizzard frames. If there is some addon which is incompatible, let me know.
Caveat: On ElvUI, chat history will not be filtered and therefore some old ignored messages may appear back in the chat box.

**Known issues:**
* Due to how the addon tries to block party invitations, using items which "Bind on use" does not work. Addon can be disabled and then re-enabled after you bind the item.

Usage:
* /ignorelevel 10 - Will filter out messages from characters that are level 10 or below.
* /ignoreparty 0 or 1 to turn on/off party invites that are below set level boundary (enabled by default).
* /ignorewhitelist
  * /ignorewhitelist add \<name\> - adds name to white list (will never filter out messages)
  * /ignorewhitelist del \<name\> - removes name from white list
  * /ignorewhitelist - prints whitelist
* /ignoredebug 0 or 1 to turn on/off filter debug messages.

