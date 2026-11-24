-- Name Hider: hides unit names in major cities by temporarily turning off the
-- game's own name CVars, and restores them when leaving a city or logging out.
local ADDON_NAME = ...
local TITLE = "Name Hider"
local PREFIX = "|cff33ff99" .. TITLE .. "|r: "
local HIDDEN = "0"

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local VERSION = (GetMetadata and GetMetadata(ADDON_NAME, "Version")) or "dev"
if VERSION:find("@", 1, true) then VERSION = "dev" end

local GROUPS = {
    players = {
        "UnitNameFriendlyPlayerName",
        "UnitNameEnemyPlayerName",
    },
    pets = {
        "UnitNameFriendlyPetName",
        "UnitNameEnemyPetName",
        "UnitNameFriendlyGuardianName",
        "UnitNameEnemyGuardianName",
        "UnitNameFriendlyTotemName",
        "UnitNameEnemyTotemName",
        "UnitNameFriendlyMinionName",
        "UnitNameEnemyMinionName",
    },
    npcs = {
        "UnitNameNPC",
        "UnitNameFriendlySpecialNPCName",
        "UnitNameHostleNPC", -- sic, Blizzard's spelling
        "UnitNameInteractiveNPC",
        "UnitNameNonCombatCreatureName",
    },
}
local GROUP_OPTION = { players = "hidePlayers", pets = "hidePets", npcs = "hideNPCs" }

local LABELS = {
    UnitNameFriendlyPlayerName = "friendly player names",
    UnitNameEnemyPlayerName = "enemy player names",
    UnitNameFriendlyMinionName = "friendly minion names",
    UnitNameEnemyMinionName = "enemy minion names",
    UnitNameNPC = "NPC names",
    UnitNameFriendlySpecialNPCName = "special NPC names",
    UnitNameHostleNPC = "hostile NPC names",
    UnitNameInteractiveNPC = "interactive NPC names",
    UnitNameNonCombatCreatureName = "critter names",
}

local DEFAULTS = {
    enabled = true,
    hidePlayers = true,
    hidePets = true,
    hideNPCs = false,
}

-- Zone names are English only; sanctuaries are detected in any locale.
local CITIES = {
    ["stormwind city"] = true, ["stormwind"] = true,
    ["ironforge"] = true,
    ["darnassus"] = true,
    ["the exodar"] = true, ["exodar"] = true,
    ["orgrimmar"] = true,
    ["thunder bluff"] = true,
    ["undercity"] = true,
    ["silvermoon city"] = true, ["silvermoon"] = true,
    ["shattrath city"] = true, ["shattrath"] = true,
    ["dalaran"] = true,
}

BINDING_NAME_NAMEHIDER_TOGGLE = "Toggle Name Hider"

local DB
local released = {} -- CVars the user changed while in a city; left alone until the next city visit
local ready = false
local applyPending = false
local panel

local function Print(msg) print(PREFIX .. msg) end

local function GetValue(cvar)
    local v
    if C_CVar and C_CVar.GetCVar then v = C_CVar.GetCVar(cvar) elseif GetCVar then v = GetCVar(cvar) end
    if v ~= nil then return tostring(v) end
end

local function GetDefault(cvar)
    local v
    if C_CVar and C_CVar.GetCVarDefault then v = C_CVar.GetCVarDefault(cvar)
    elseif GetCVarDefault then v = GetCVarDefault(cvar) end
    if v ~= nil then return tostring(v) end
end

local function SetValue(cvar, value)
    local setter = (C_CVar and C_CVar.SetCVar) or SetCVar
    local ok, result = pcall(setter, cvar, value)
    return ok and result ~= false
end

local function IsInCity()
    local pvpType
    if C_PvP and C_PvP.GetZonePVPInfo then
        pvpType = C_PvP.GetZonePVPInfo()
    elseif GetZonePVPInfo then
        pvpType = GetZonePVPInfo()
    end
    if pvpType == "sanctuary" then return true end
    for _, name in ipairs({ GetRealZoneText and GetRealZoneText(), GetZoneText and GetZoneText() }) do
        if name and CITIES[name:lower()] then return true end
    end
    return false
end

local function ShouldHide()
    return DB.enabled and IsInCity()
end

local function Desired()
    local set = {}
    if not ShouldHide() then return set end
    for group, cvars in pairs(GROUPS) do
        if DB[GROUP_OPTION[group]] then
            for _, cvar in ipairs(cvars) do set[cvar] = true end
        end
    end
    return set
end

-- Puts back a CVar we hid, unless something else changed it since.
local function Restore(cvar)
    local original = DB.saved[cvar]
    if original == nil then return true end
    DB.saved[cvar] = nil
    if GetValue(cvar) == HIDDEN and not SetValue(cvar, original) then
        DB.saved[cvar] = original
        return false
    end
    return true
end

local function RestoreAll()
    for cvar in pairs(DB.saved) do Restore(cvar) end
end

-- A hidden CVar that is no longer "0" was changed by the user (or another addon):
-- keep their value and stop managing it until the next city visit.
local function DetectUserChanges(silent)
    for cvar in pairs(DB.saved) do
        local current = GetValue(cvar)
        if current ~= HIDDEN then
            DB.saved[cvar] = nil
            released[cvar] = true
            if not silent and LABELS[cvar] then
                Print("keeping your change to " .. LABELS[cvar] ..
                    ". It won't be hidden again until you next enter a city.")
            end
        end
    end
end

local function UpdatePanel()
    if not panel or not panel:IsVisible() then return end
    for key, check in pairs(panel.checks) do check:SetChecked(DB[key]) end
    local status
    if not DB.enabled then
        status = "|cffaaaaaaTurned off. Your normal name settings are active.|r"
    elseif next(DB.saved) then
        status = "|cffff7777In a city: names are hidden.|r"
    elseif IsInCity() then
        status = "|cffffd100In a city: nothing to hide with the current options.|r"
    else
        status = "|cff77ff77Not in a city: your normal name settings are active.|r"
    end
    panel.status:SetText(status)
end

local function Apply()
    if not ready then return end
    if InCombatLockdown and InCombatLockdown() then
        applyPending = true
        return
    end
    applyPending = false

    DetectUserChanges(false)
    if not ShouldHide() then wipe(released) end

    local desired = Desired()
    for cvar in pairs(DB.saved) do
        if not desired[cvar] then Restore(cvar) end
    end
    for cvar in pairs(desired) do
        if DB.saved[cvar] == nil and not released[cvar] then
            local current = GetValue(cvar)
            if current ~= nil and current ~= HIDDEN then
                DB.saved[cvar] = current
                if not SetValue(cvar, HIDDEN) then DB.saved[cvar] = nil end
            end
        end
    end
    UpdatePanel()
end

local applyQueued = false
local function QueueApply()
    if applyQueued then return end
    applyQueued = true
    C_Timer.After(0.5, function()
        applyQueued = false
        Apply()
    end)
end

function NameHider_Toggle()
    DB.enabled = not DB.enabled
    Apply()
    Print(DB.enabled and "on. Names will be hidden in cities." or "off. Your normal name settings are active.")
end

local function ResetToDefaults()
    if InCombatLockdown and InCombatLockdown() then
        Print("can't reset during combat.")
        return
    end
    wipe(DB.saved)
    wipe(released)
    for _, cvars in pairs(GROUPS) do
        for _, cvar in ipairs(cvars) do
            local default = GetDefault(cvar)
            if default ~= nil and GetValue(cvar) ~= default then SetValue(cvar, default) end
        end
    end
    Print("all name settings Name Hider manages were reset to game defaults. " ..
        "Adjust them in the game's Interface options if needed.")
    Apply()
end

---------------------------------------------------------------------------
-- Settings panel
---------------------------------------------------------------------------
local settingsCategory

local function CreateCheck(parent, key, label, y)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", 16, y)
    local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    text:SetText(label)
    check:SetScript("OnClick", function(self)
        DB[key] = self:GetChecked() and true or false
        Apply()
    end)
    parent.checks[key] = check
    return check
end

local function CreatePanel()
    panel = CreateFrame("Frame", "NameHiderOptionsPanel", UIParent)
    panel.name = TITLE
    panel.checks = {}
    panel:Hide()

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(TITLE .. "  |cff888888" .. VERSION .. "|r")

    panel.status = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    panel.status:SetPoint("TOPLEFT", 16, -44)

    CreateCheck(panel, "enabled", "Hide names in major cities and sanctuaries", -72)
    CreateCheck(panel, "hidePlayers", "Player names", -108)
    CreateCheck(panel, "hidePets", "Pet, minion, guardian and totem names", -136)
    CreateCheck(panel, "hideNPCs", "NPC and critter names (for maximum immersion)", -164)

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 20, -202)
    note:SetWidth(560)
    note:SetJustifyH("LEFT")
    note:SetText(
        "Name Hider turns off the game's own name settings while you are in a city and puts them back " ..
        "when you leave or log out. To hide names everywhere, use the game's Interface options instead.\n\n" ..
        "Your targeted unit always shows its name. If you change a hidden name setting while in a city, " ..
        "your change is kept and Name Hider leaves it alone until you next enter a city.\n\n" ..
        "A key to toggle Name Hider can be set in Key Bindings > AddOns.\n" ..
        "Commands: /namehider toggle | reset | status")

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(260, 24)
    reset:SetPoint("TOPLEFT", 18, -330)
    reset:SetText("Reset name settings to game defaults")
    reset:SetScript("OnClick", ResetToDefaults)

    panel:SetScript("OnShow", UpdatePanel)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, TITLE)
        if ok and category and pcall(Settings.RegisterAddOnCategory, category) then
            settingsCategory = category
        end
    end
    if not settingsCategory and InterfaceOptions_AddCategory then
        pcall(InterfaceOptions_AddCategory, panel)
    end
end

local function OpenSettings()
    if settingsCategory and Settings.OpenToCategory then
        local id = settingsCategory.GetID and settingsCategory:GetID() or settingsCategory.ID
        if pcall(Settings.OpenToCategory, id) then return end
    end
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        return
    end
    Print("settings window unavailable; use /namehider toggle.")
end

function NameHider_OnCompartmentClick()
    OpenSettings()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")

local function OnLogin()
    NameHiderDB = NameHiderDB or {}
    DB = NameHiderDB
    DB.saved = DB.saved or {}
    for key, value in pairs(DEFAULTS) do
        if DB[key] == nil then DB[key] = value end
    end

    CreatePanel()

    local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if IsLoaded and IsLoaded("NameDisable") then
        Print("|cffff4444NameDisable is also enabled. Please disable or uninstall it; both change the same settings.|r")
    end
end

local handlers = {}

function handlers.PLAYER_LOGIN()
    OnLogin()
end

function handlers.PLAYER_ENTERING_WORLD()
    if ready then QueueApply() return end
    -- Zone info and account CVars may not be settled on the first frame.
    C_Timer.After(1, function()
        -- Leftovers from a logout that couldn't restore: drop any that no longer look hidden.
        DetectUserChanges(true)
        wipe(released)
        ready = true
        Apply()
        C_Timer.NewTicker(2, Apply) -- safety net for missed zone events
    end)
end

function handlers.PLAYER_REGEN_ENABLED()
    if applyPending then Apply() end
end

function handlers.PLAYER_LOGOUT()
    -- Leave settings as the user had them, so removing the addon leaves nothing behind.
    if DB then RestoreAll() end
end

handlers.ZONE_CHANGED = QueueApply
handlers.ZONE_CHANGED_INDOORS = QueueApply
handlers.ZONE_CHANGED_NEW_AREA = QueueApply
handlers.CVAR_UPDATE = function() if ready then QueueApply() end end

for event in pairs(handlers) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", function(_, event, ...) handlers[event](...) end)

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
SLASH_NAMEHIDER1 = "/namehider"
SlashCmdList.NAMEHIDER = function(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "toggle" then
        NameHider_Toggle()
    elseif command == "reset" then
        ResetToDefaults()
    elseif command == "status" then
        Print(VERSION .. " | " .. (DB.enabled and "on" or "off") .. " | in city: " .. tostring(IsInCity()) ..
            " | zone: " .. tostring(GetRealZoneText and GetRealZoneText()))
        for _, group in ipairs({ "players", "pets", "npcs" }) do
            for _, cvar in ipairs(GROUPS[group]) do
                local note = DB.saved[cvar] and (" (hidden, normally " .. DB.saved[cvar] .. ")")
                    or (released[cvar] and " (your change, left alone)") or ""
                print("  " .. cvar .. " = " .. tostring(GetValue(cvar)) .. note)
            end
        end
    else
        OpenSettings()
    end
end
