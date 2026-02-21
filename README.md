UUF World Buff Filter

UUF World Buff Filter allows you to hide unwanted world and miscellaneous buffs from the Player frame in Unhalted Unit Frames (UUF) using a fully customizable SpellID blacklist.

It is designed for players who want a clean buff display and prefer to see only relevant combat, class, or raid buffs while hiding temporary world effects, holiday buffs, zone effects, or other clutter.

What It Does

This addon hooks into UUF’s Player Buff container and filters out specific auras based on their SpellID.

If a buff’s SpellID is on your blacklist, it will not be shown in UUF’s Player frame.

Features

SpellID-based blacklist

Scrollable blacklist with individual remove buttons

Dropdown menu to add currently active buffs

"Blacklist all current buffs” button

“Clear blacklist” button

Slash commands

Settings Location

You can access the graphical settings here:

Esc → Options → AddOns → UUF World Buff Filter

Alternatively via command:



/uufwbf options



/uufwbf add <spellID> - Add a SpellID to the blacklist
/uufwbf del <spellID> - Remove a SpellID from the blacklist
/uufwbf list - Show all blacklisted SpellIDs
/uufwbf dump - Print current active buffs and their SpellIDs
/uufwbf refresh - Force refresh of UUF buffs
/uufwbf options - Open addon settings




Important Notes

This addon only affects the Player Buffs in UUF. You can get Unhalted Unit Frames here: https://www.curseforge.com/wow/addons/unhaltedunitframes
