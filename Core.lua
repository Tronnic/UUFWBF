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

local function SafeGetSpellId(data)
  if not data then return nil end
  local ok, sid = pcall(function() return data.spellId end)
  if ok then return sid end
  return nil
end

local function IsBlacklisted(spellID)
  EnsureDB()
  if not spellID then return false end
  local ok, isBl = pcall(function()
    return UUF_WBF_DB.blacklist[spellID] == true
  end)
  if not ok then
    return false
  end
  return isBl
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
  if not id then
    Print("Usage: /uufwbf add <spellID>")
    return
  end
  UUF_WBF_DB.blacklist[id] = true
  Print("Added to blacklist: " .. id)
  UUF_WBF.Refresh()
end

function UUF_WBF.Remove(id)
  EnsureDB()
  id = tonumber(id)
  if not id then
    Print("Usage: /uufwbf remove <spellID>")
    return
  end
  UUF_WBF_DB.blacklist[id] = nil
  Print("Removed from blacklist: " .. id)
  UUF_WBF.Refresh()
end

function UUF_WBF.List()
  EnsureDB()
  Print("Blacklist:")
  DEFAULT_CHAT_FRAME:AddMessage("=== start ===")
  for id in pairs(UUF_WBF_DB.blacklist) do
    DEFAULT_CHAT_FRAME:AddMessage(tostring(id))
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
    local spellID = SafeGetSpellId(data)
    if spellID and IsBlacklisted(spellID) then
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

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(_, event, addonName)
  if event == "ADDON_LOADED" and addonName == "UUFWorldBuffFilter" then
    EnsureDB()
    SeedDefaultsIfEmpty()
  end

  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "ADDON_LOADED" then
    HookUUF()
  end
end)
