-- HideBlizzBuffsDebuffs.lua

local function IsEnabled()
  return UUF_WBF_DB and UUF_WBF_DB.hideBlizzBuffs == true
end

local updater

local function IsMouseOverFrameOrContainer(frame)
  if not frame then return false end
  if frame.IsMouseOver and frame:IsMouseOver() then return true end

  if frame.AuraContainer and frame.AuraContainer.IsMouseOver and frame.AuraContainer:IsMouseOver() then
    return true
  end

  return false
end

local function ApplyOne(frame)
  if not frame then return end
  frame:Show()
  if IsEnabled() then
    frame:SetAlpha(0)
  else
    frame:SetAlpha(1)
  end
end

local function ApplyAll()
  ApplyOne(BuffFrame)
  ApplyOne(DebuffFrame)
end

local function EnsureUpdater()
  if updater then return end
  updater = CreateFrame("Frame")
  updater:SetScript("OnUpdate", function()
    local enabled = IsEnabled()

    if BuffFrame then
      local show = (not enabled) or IsMouseOverFrameOrContainer(BuffFrame)
      BuffFrame:SetAlpha(show and 1 or 0)
      BuffFrame:Show()
    end

    if DebuffFrame then
      local show = (not enabled) or IsMouseOverFrameOrContainer(DebuffFrame)
      DebuffFrame:SetAlpha(show and 1 or 0)
      DebuffFrame:Show()
    end
  end)
end

function UUF_WBF_SetHideBlizzAuras(state)
  UUF_WBF_DB = UUF_WBF_DB or {}
  UUF_WBF_DB.hideBlizzBuffs = state and true or false

  C_Timer.After(0, function()
    EnsureUpdater()
    ApplyAll()
  end)
end

-- Apply setting once on login
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
  if not isInitialLogin and not isReloadingUi then return end
  C_Timer.After(1.0, function()
    if UUF_WBF_DB and UUF_WBF_DB.hideBlizzBuffs ~= nil then
      UUF_WBF_SetHideBlizzAuras(UUF_WBF_DB.hideBlizzBuffs)
    end
  end)
end)
