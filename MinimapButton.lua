-- MinimapButton.lua

local function ShowMenu(owner)
  local menu = {
    { text = "Open |cff8080FFUnhalted|rUnitFrames Settings", notCheckable = true, func = function()
        if UUF_WBF and UUF_WBF.ExecSlash then pcall(UUF_WBF.ExecSlash, "/uuf")
        else
          if RunMacroText then pcall(RunMacroText, "/uuf") end
        end
      end
    },
    { text = "Open UUF |cff7fd5ffWorld Buff Filter|r Settings", notCheckable = true, func = function()
        if UUF_WBF and UUF_WBF.OpenOptions then pcall(UUF_WBF.OpenOptions) end
      end
    },
  }

  local dropdown = CreateFrame("Frame", "UUF_WBF_MinimapMenu", UIParent, "UIDropDownMenuTemplate")
  if EasyMenu then
    EasyMenu(menu, dropdown, owner, 0, 0, "MENU")
    return
  end

  UIDropDownMenu_Initialize(dropdown, function(_, level)
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    for _, item in ipairs(menu) do
      info.text = item.text
      info.func = item.func
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
end

-- Initialize LibDataBroker launcher and register it with LibDBIcon if available.

local function InitLibDBIcon()
  local LibStub = _G.LibStub
  if not LibStub then return false end

  local LDB = LibStub("LibDataBroker-1.1", true)
  local LDBIcon = LibStub("LibDBIcon-1.0", true)
  if not LDB or not LDBIcon then return false end

  UUF_WBF_DB = UUF_WBF_DB or {}
  UUF_WBF_DB.minimap = UUF_WBF_DB.minimap or {}

  local ldbObj = LDB:NewDataObject("UUF_WBF", {
    type = "launcher",
    icon = "Interface\\AddOns\\UUFWorldBuffFilter\\uufwbf.tga",
    OnClick = function(self, button)
      if button == "LeftButton" then
        ShowMenu(self)
      else
        if UUF_WBF and UUF_WBF.OpenOptions then pcall(UUF_WBF.OpenOptions) end
      end
    end,
    OnTooltipShow = function(tt)
      if not tt or not tt.AddLine then return end
      tt:AddLine("UUF |cff7fd5ffWorld Buff Filter|r")
      tt:AddLine("Left-click: Open menu")
      tt:AddLine("Right-click: Open addon settings", 0.6, 0.6, 0.6)
    end,
  })

  pcall(function() LDBIcon:Register("UUF_WBF", ldbObj, UUF_WBF_DB.minimap) end)
  return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  InitLibDBIcon()
end)
