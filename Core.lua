-- Core.lua

UUF_WBF_DB = UUF_WBF_DB or {}
UUF_WBF_DB.blacklist = UUF_WBF_DB.blacklist or {}

local DEFAULT_BLACKLIST = {
  [97341]   = true,
  [1227147] = true,
  [335150]  = true,
  [1214848] = true,
  [404464]  = true,
}

-- seed defaults
local function SeedDefaultsIfEmpty()
  local hasAny = false
  for _ in pairs(UUF_WBF_DB.blacklist) do
    hasAny = true
    break
  end
  if hasAny then return end

  for id, v in pairs(DEFAULT_BLACKLIST) do
    if v then UUF_WBF_DB.blacklist[id] = true end
  end
end

SeedDefaultsIfEmpty()

UUF_WBF = UUF_WBF or {} -- global table for UI access
UUF_WBF.ADDON_TITLE = "UUF World Buff Filter"

local hooked = false
local originalFilter = nil
local buffsFrame = nil

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cFF7fd5ffUUF-WBF:|r " .. msg)
end

local function EnsureDB()
  UUF_WBF_DB = UUF_WBF_DB or {}
  UUF_WBF_DB.blacklist = UUF_WBF_DB.blacklist or {}
end

local function IsBlacklisted(spellID)
  EnsureDB()
  return spellID and UUF_WBF_DB.blacklist[spellID] == true
end

function UUF_WBF.Refresh()
  if hooked and buffsFrame then
    buffsFrame.needFullUpdate = true
    if buffsFrame.ForceUpdate then
      buffsFrame:ForceUpdate()
    end
  end
end

function UUF_WBF.Add(id)
  EnsureDB()
  id = tonumber(id)
  if not id then return false, "SpellID must be numeric." end
  UUF_WBF_DB.blacklist[id] = true
  UUF_WBF.Refresh()
  return true
end

function UUF_WBF.Remove(id)
  EnsureDB()
  id = tonumber(id)
  if not id then return false, "SpellID must be numeric." end
  UUF_WBF_DB.blacklist[id] = nil
  UUF_WBF.Refresh()
  return true
end

function UUF_WBF.GetBlacklistSorted()
  EnsureDB()
  local t = {}
  for id, v in pairs(UUF_WBF_DB.blacklist) do
    if v then table.insert(t, tonumber(id)) end
  end
  table.sort(t)
  return t
end

-- spell name lookup 
function UUF_WBF.GetSpellName(id)
  id = tonumber(id)
  if not id then return "Invalid ID" end

  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id) or ("ID " .. tostring(id))
  end

  if _G.GetSpellInfo then
    local name = _G.GetSpellInfo(id)
    return name or ("ID " .. tostring(id))
  end

  return "ID " .. tostring(id)
end

function UUF_WBF.DumpPlayerBuffsToChat()
  DEFAULT_CHAT_FRAME:AddMessage("=== Player Buffs (HELPFUL) ===")
  for i = 1, 80 do
    local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not a then break end
    DEFAULT_CHAT_FRAME:AddMessage((a.name or "?") .. " ID=" .. tostring(a.spellId))
  end
  DEFAULT_CHAT_FRAME:AddMessage("=== end ===")
end

local function HookUUF()
  buffsFrame = _G["UUF_Player_BuffsContainer"]
  if not buffsFrame then
    return false
  end
  if hooked then
    return true
  end

  originalFilter = buffsFrame.FilterAura

  buffsFrame.FilterAura = function(self, unit, data, filter)
    if data and IsBlacklisted(data.spellId) then
      return false
    end
    if originalFilter then
      return originalFilter(self, unit, data, filter)
    end
    return true
  end

  hooked = true
  Print("FilterAura hooked (blacklist active).")
  UUF_WBF.Refresh()
  return true
end

-- Bootstrap: hook after UUF has created frames
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  local tries = 0
  local function TryHook()
    tries = tries + 1
    if HookUUF() then return end
    if tries < 40 then
      C_Timer.After(0.25, TryHook)
    else
      Print("Could not hook UUF. Is Unhalted Unit Frames enabled?")
    end
  end
  TryHook()
end)

-- Slash commands
SLASH_UUFWBF1 = "/uufwbf"
SlashCmdList["UUFWBF"] = function(msg)
  local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""

  if cmd == "add" then
    local ok, err = UUF_WBF.Add(rest)
    if ok then
      local id = tonumber(rest)
      Print("Added: " .. tostring(id) .. " (" .. UUF_WBF.GetSpellName(id) .. ")")
    else
      Print(err)
    end

  elseif cmd == "del" then
    local ok, err = UUF_WBF.Remove(rest)
    if ok then Print("Removed: " .. rest) else Print(err) end

  elseif cmd == "list" then
    Print("Blacklisted spellIDs:")
    local ids = UUF_WBF.GetBlacklistSorted()
    if #ids == 0 then Print(" (none)") return end
    for _, id in ipairs(ids) do
      Print(" - " .. tostring(id) .. " (" .. UUF_WBF.GetSpellName(id) .. ")")
    end

  elseif cmd == "dump" then
    UUF_WBF.DumpPlayerBuffsToChat()

  elseif cmd == "refresh" then
    UUF_WBF.Refresh()
    Print("Refreshed.")
	
elseif cmd == "options" or cmd == "opt" then
  -- Open WBF options
  if Settings and Settings.OpenToCategory and UUF_WBF and type(UUF_WBF.SettingsCategoryID) == "number" then
    Settings.OpenToCategory(UUF_WBF.SettingsCategoryID)
  else
    local frame = _G["UUFWorldBuffFilterOptions"]
    if frame and InterfaceOptionsFrame_OpenToCategory then
      InterfaceOptionsFrame_OpenToCategory(frame)
      InterfaceOptionsFrame_OpenToCategory(frame)
    end
  end

  else
    Print("Commands: /uufwbf options | add <spellID> | del <spellID> | list | dump | refresh")
    Print("GUI: Esc -> Options -> AddOns -> " .. UUF_WBF.ADDON_TITLE)
  end
end