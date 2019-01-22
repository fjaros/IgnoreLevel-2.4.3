# IgnoreLevel-2.4.3
AddOn for World of Warcraft 2.4.3 to filter out whispers by character level.

**After downloading, extract ONLY the IgnoreLevel folder into your AddOns folder.**

**So that you have: \<Root WoW Folder\>\\Interface\\AddOns\\IgnoreLevel\\IgnoreLevel.lua**

It works with ElvUI and default Blizzard frames. If there is a more elegant way to handle the ElvUI hackery in the script, please let me know!

Usage:
* /ignorelevel 10 - Will filter out messages from characters that are level 10 or below.
* /ignorewhitelist
  * /ignorewhitelist add \<name\> - adds name to white list (will never filter out messages)
  * /ignorewhitelist del \<name\> - removes name from white list
  * /ignorewhitelist - prints whitelist
* /ignoredebug 0 or 1 to turn on/off filter debug messages.

