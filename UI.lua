-- UI.lua

local function SafePrint(msg)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF7fd5ffUUF-WBF UI:|r " .. msg)
  end
end

-- Execute slash command immediately (no "press enter")
local function ExecSlash(cmd)
  if type(cmd) ~= "string" or cmd == "" then return end

  -- Prefer direct slash handler if present (fastest / most reliable)
  if SlashCmdList and SlashCmdList["UUF"] and cmd:lower() == "/uuf" then
    SlashCmdList["UUF"]("")
    return
  end

  -- Fallback: macro execution runs slash immediately
  if RunMacroText then
    RunMacroText(cmd)
    return
  end

  -- Last fallback: put into chat (may require enter on some clients)
  ChatFrame_OpenChat(cmd)
end

local function GetSpellNameSafe(id)
  if C_Spell and C_Spell.GetSpellName then
    return C_Spell.GetSpellName(id)
  end
  if _G.GetSpellInfo then
    local name = _G.GetSpellInfo(id)
    return name
  end
  return nil
end

local UI = {
  frame = nil,
  debug = nil,

  -- row list (scrollable)
  scroll = nil,
  scrollBar = nil,
  scrollOffset = 0,
  rowHeight = 22,

  listParent = nil,
  rows = {},
  maxRows = 12,

  -- dropdown
  dd = nil,
  ddLabel = nil,
  ddSelected = nil, -- spellId
}

local function EnsureDB()
  UUF_WBF_DB = UUF_WBF_DB or {}
  UUF_WBF_DB.blacklist = UUF_WBF_DB.blacklist or {}
end

local function SortedBlacklistIDs()
  EnsureDB()
  local t = {}
  for id, v in pairs(UUF_WBF_DB.blacklist) do
    if v then table.insert(t, tonumber(id)) end
  end
  table.sort(t)
  return t
end

local function RefreshUUF()
  if UUF_WBF and UUF_WBF.Refresh then
    UUF_WBF.Refresh()
  end
end

local function DumpPlayerBuffsToChat()
  DEFAULT_CHAT_FRAME:AddMessage("=== Player Buffs ===")
  for i = 1, 80 do
    local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not a then break end
    DEFAULT_CHAT_FRAME:AddMessage((a.name or "?") .. " SpellID=" .. tostring(a.spellId))
  end
  DEFAULT_CHAT_FRAME:AddMessage("=== end ===")
end

local function BlacklistSpellId(id)
  if not id then return end
  EnsureDB()
  UUF_WBF_DB.blacklist[id] = true
  RefreshUUF()
end

local function UnblacklistSpellId(id)
  if not id then return end
  EnsureDB()
  UUF_WBF_DB.blacklist[id] = nil
  RefreshUUF()
end

local function BlacklistAllCurrentBuffs()
  EnsureDB()
  local added = 0
  for i = 1, 80 do
    local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not a then break end
    if a.spellId and not UUF_WBF_DB.blacklist[a.spellId] then
      UUF_WBF_DB.blacklist[a.spellId] = true
      added = added + 1
    end
  end
  RefreshUUF()
  SafePrint("Blacklisted all current buffs (added " .. added .. ").")
end

local function ClearBlacklist()
  EnsureDB()
  wipe(UUF_WBF_DB.blacklist)
  RefreshUUF()
  SafePrint("Blacklist cleared.")
end

-- ---------- ROW LIST UI (SCROLLABLE) ----------

local function EnsureRows()
  if not UI.listParent then return end

  for i = #UI.rows + 1, UI.maxRows do
    local row = CreateFrame("Frame", nil, UI.listParent)
    row:SetSize(560, UI.rowHeight)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row, "LEFT", 0, 0)

    row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.remove:SetSize(70, 20)
    row.remove:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.remove:SetText("Remove")

    UI.rows[i] = row
  end
end

local function UpdateScrollRange(totalItems)
  if not (UI.scroll and UI.scrollBar and UI.listParent) then return end

  local totalHeight = math.max(totalItems * UI.rowHeight, UI.rowHeight)
  UI.listParent:SetHeight(totalHeight)

  local visibleHeight = UI.rowHeight * UI.maxRows
  local maxScroll = math.max(0, totalHeight - visibleHeight)

  UI.scrollBar:SetMinMaxValues(0, maxScroll)

  local maxOffset = math.max(0, totalItems - UI.maxRows)
  if UI.scrollOffset > maxOffset then UI.scrollOffset = maxOffset end
  if UI.scrollOffset < 0 then UI.scrollOffset = 0 end

  local targetValue = UI.scrollOffset * UI.rowHeight
  UI.scrollBar:SetValue(targetValue)
  UI.scroll:SetVerticalScroll(targetValue)

  if maxScroll > 0 then
    UI.scrollBar:Show()
  else
    UI.scrollBar:Hide()
    UI.scrollOffset = 0
    UI.scroll:SetVerticalScroll(0)
  end
end

local function RenderRowList()
  if not UI.listParent then return end
  EnsureRows()

  local ids = SortedBlacklistIDs()
  if UI.debug then
    UI.debug:SetText("IDs in blacklist: " .. tostring(#ids))
  end

  UpdateScrollRange(#ids)

  for i = 1, UI.maxRows do
    UI.rows[i]:Hide()
  end

  if #ids == 0 then
    local row = UI.rows[1]
    row:Show()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", UI.listParent, "TOPLEFT", 0, 0)
    row.text:SetText("Blacklist is empty.")
    row.remove:Hide()
    return
  end

  local total = #ids
  local maxOffset = math.max(0, total - UI.maxRows)
  if UI.scrollOffset > maxOffset then UI.scrollOffset = maxOffset end
  if UI.scrollOffset < 0 then UI.scrollOffset = 0 end

  local shown = math.min(total - UI.scrollOffset, UI.maxRows)

  for i = 1, shown do
    local id = ids[UI.scrollOffset + i]
    local row = UI.rows[i]

    row:Show()
    row.remove:Show()

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", UI.listParent, "TOPLEFT", 0, -(i - 1) * UI.rowHeight)

    local name = GetSpellNameSafe(id)
    if name then
      row.text:SetText(string.format("%s |cffaaaaaa(ID %d)|r", name, id))
    else
      row.text:SetText(string.format("ID %d", id))
    end

    row.remove:SetScript("OnClick", function()
      UnblacklistSpellId(id)
      RenderRowList()
    end)
  end
end

-- ---------- DROPDOWN (current buffs) ----------

local function GetCurrentBuffChoices()
  local choices = {}
  local seen = {}

  for i = 1, 80 do
    local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
    if not a then break end
    if a.spellId and not seen[a.spellId] then
      seen[a.spellId] = true
      local name = a.name or GetSpellNameSafe(a.spellId) or ("ID " .. tostring(a.spellId))
      table.insert(choices, { spellId = a.spellId, name = name })
    end
  end

  table.sort(choices, function(x, y)
    return (x.name or "") < (y.name or "")
  end)

  return choices
end

local function Dropdown_SetSelected(spellId, displayText)
  UI.ddSelected = spellId
  UIDropDownMenu_SetText(UI.dd, displayText or "Select a buff...")
end

local function Dropdown_Initialize(self, level)
  local info = UIDropDownMenu_CreateInfo()
  info.notCheckable = true

  local choices = GetCurrentBuffChoices()
  if #choices == 0 then
    info.text = "No buffs found"
    info.disabled = true
    info.func = nil
    UIDropDownMenu_AddButton(info, level)
    return
  end

  for _, c in ipairs(choices) do
    local id = c.spellId
    local name = c.name or ("ID " .. tostring(id))
    info.text = string.format("%s (ID %d)", name, id)
    info.disabled = false
    info.func = function()
      Dropdown_SetSelected(id, info.text)
    end
    UIDropDownMenu_AddButton(info, level)
  end
end

-- ---------- CREATE OPTIONS UI ----------

local function CreateOptionsUI()
  if UI.frame then return end

  local frame = CreateFrame("Frame", "UUFWorldBuffFilterOptions", UIParent)
  UI.frame = frame

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
  title:SetText("UUF World Buff Filter")

  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  subtitle:SetText("Manage your SpellID blacklist for Player buffs shown by Unhalted Unit Frames (UUF).")

  local debug = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  UI.debug = debug
  debug:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -6)
  debug:SetText("IDs in blacklist: ?")



  -- Add SpellID
  local addLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  addLabel:SetPoint("TOPLEFT", debug, "BOTTOMLEFT", 0, -12)
  addLabel:SetText("Add SpellID:")

  local addEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  addEdit:SetSize(120, 24)
  addEdit:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -6)
  addEdit:SetAutoFocus(false)
  addEdit:SetNumeric(true)

  local addBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  addBtn:SetSize(80, 24)
  addBtn:SetPoint("LEFT", addEdit, "RIGHT", 8, 0)
  addBtn:SetText("Add")

  -- Remove SpellID
  local remLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  remLabel:SetPoint("LEFT", addBtn, "RIGHT", 18, 0)
  remLabel:SetText("Remove SpellID:")

  local remEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  remEdit:SetSize(120, 24)
  remEdit:SetPoint("LEFT", remLabel, "RIGHT", 8, 0)
  remEdit:SetAutoFocus(false)
  remEdit:SetNumeric(true)

  local remBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  remBtn:SetSize(90, 24)
  remBtn:SetPoint("LEFT", remEdit, "RIGHT", 8, 0)
  remBtn:SetText("Remove")

  addBtn:SetScript("OnClick", function()
    local id = tonumber(addEdit:GetText() or "")
    if not id then return end
    BlacklistSpellId(id)
    addEdit:SetText("")
    RenderRowList()
  end)
  addEdit:SetScript("OnEnterPressed", function() addBtn:Click() end)

  remBtn:SetScript("OnClick", function()
    local id = tonumber(remEdit:GetText() or "")
    if not id then return end
    UnblacklistSpellId(id)
    remEdit:SetText("")
    RenderRowList()
  end)
  remEdit:SetScript("OnEnterPressed", function() remBtn:Click() end)

  -- Buttons row 1
  local dumpBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  dumpBtn:SetSize(200, 24)
  dumpBtn:SetPoint("TOPLEFT", addEdit, "BOTTOMLEFT", 0, -10)
  dumpBtn:SetText("Show current Buffs in Chat")
  dumpBtn:SetScript("OnClick", DumpPlayerBuffsToChat)

  local refreshBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  refreshBtn:SetSize(140, 24)
  refreshBtn:SetPoint("LEFT", dumpBtn, "RIGHT", 10, 0)
  refreshBtn:SetText("Refresh list")
  refreshBtn:SetScript("OnClick", RenderRowList)

  -- Open UUF settings button
  local openUUFBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  openUUFBtn:SetSize(160, 24)
  openUUFBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 10, 0)
  openUUFBtn:SetText("Open /uuf Settings")
  openUUFBtn:SetScript("OnClick", function()
    ExecSlash("/uuf")
  end)

  -- Buttons row 2
  local allBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  allBtn:SetSize(200, 24)
  allBtn:SetPoint("TOPLEFT", dumpBtn, "BOTTOMLEFT", 0, -8)
  allBtn:SetText("Blacklist all current buffs")
  allBtn:SetScript("OnClick", function()
    BlacklistAllCurrentBuffs()
    UI.scrollOffset = 0
    RenderRowList()
  end)

  local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clearBtn:SetSize(140, 24)
  clearBtn:SetPoint("LEFT", allBtn, "RIGHT", 10, 0)
  clearBtn:SetText("Clear blacklist")
  clearBtn:SetScript("OnClick", function()
    ClearBlacklist()
    UI.scrollOffset = 0
    RenderRowList()
  end)

  -- Dropdown row
  local ddLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  UI.ddLabel = ddLabel
  ddLabel:SetPoint("TOPLEFT", allBtn, "BOTTOMLEFT", 0, -12)
  ddLabel:SetText("Add from current buffs:")

  local dd = CreateFrame("Frame", "UUF_WBF_DropDown", frame, "UIDropDownMenuTemplate")
  UI.dd = dd
  dd:SetPoint("TOPLEFT", ddLabel, "BOTTOMLEFT", -14, -2)
  UIDropDownMenu_SetWidth(dd, 360)
  UIDropDownMenu_Initialize(dd, Dropdown_Initialize)
  UIDropDownMenu_SetText(dd, "Select a buff...")

  local ddAddBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ddAddBtn:SetSize(80, 24)
  ddAddBtn:SetPoint("LEFT", dd, "RIGHT", -8, 2)
  ddAddBtn:SetText("Add")
  ddAddBtn:SetScript("OnClick", function()
    if not UI.ddSelected then return end
    BlacklistSpellId(UI.ddSelected)
    RenderRowList()
  end)

  local ddRefreshBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ddRefreshBtn:SetSize(90, 24)
  ddRefreshBtn:SetPoint("LEFT", ddAddBtn, "RIGHT", 8, 0)
  ddRefreshBtn:SetText("Update")
  ddRefreshBtn:SetScript("OnClick", function()
    Dropdown_SetSelected(nil, "Select a buff...")
    UIDropDownMenu_Initialize(UI.dd, Dropdown_Initialize)
  end)

  -- List label
  local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  listLabel:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 14, -12)
  listLabel:SetText("Blacklisted buffs:")

  -- ScrollFrame + content
  local scroll = CreateFrame("ScrollFrame", "UUF_WBF_Scroll", frame, "UIPanelScrollFrameTemplate")
  UI.scroll = scroll
  scroll:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -8)
  scroll:SetSize(580, UI.rowHeight * UI.maxRows)

  local listParent = CreateFrame("Frame", nil, scroll)
  UI.listParent = listParent
  listParent:SetSize(560, UI.rowHeight)
  scroll:SetScrollChild(listParent)

  UI.scrollBar = _G[scroll:GetName() .. "ScrollBar"]

  if UI.scrollBar then
    UI.scrollBar:SetScript("OnValueChanged", function(self, value)
      value = value or 0
      UI.scrollOffset = math.floor((value / UI.rowHeight) + 0.5)
      RenderRowList()
    end)
  end

  -- Initial render
  RenderRowList()
  C_Timer.After(0.3, RenderRowList)

  -- Register in Settings
  if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(frame, "UUF World Buff Filter")
    Settings.RegisterAddOnCategory(category)

    UUF_WBF = UUF_WBF or {}
    if category and category.GetID then
      UUF_WBF.SettingsCategoryID = category:GetID()
    end
  else
    InterfaceOptions_AddCategory(frame)
  end

  -- Footer / credits
local credits = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
credits:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
credits:SetJustifyH("CENTER")

credits:SetText(
  "Made by |cFFFFFFFFFraenky-Blackhand|r, " ..
  "special thanks to |cFFB366FFSurøkoida-Blackhand|r for testing & emotional Support <3"
)

  SafePrint("To configure UUF World Buff Filter type /uufwbf opt")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  CreateOptionsUI()
  C_Timer.After(0.4, RenderRowList)
end)
