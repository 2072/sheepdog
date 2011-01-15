--[=[
SheepDog World of Warcraft Add-on
Copyright (c) 2011 by John Wellesz (Archarodim@teaser.fr)
All rights reserved

Version @project-version@

A very simple add-on that should prevent you from breaking crowd control spell.

This add-on uses the Ace3 framework.

type /SheepDog to get a list of existing options.

-----
    Core.lua
-----


--]=]

--========= NAMING Convention ==========
--      VARIABLES AND FUNCTIONS (upvalues excluded)
-- global variable                == _NAME_WORD2 (underscore + full uppercase)
-- semi-global (file locals)      == NAME_WORD2 (full uppercase)
-- locals to closures or members  == NameWord2
-- locals to functions            == nameWord2
--
--      TABLES
--  globale                       == NAME__WORD2
--  locals                        == name_word2
--  members                       == Name_Word2

-- Debug templates
local ERROR     = 1;
local WARNING   = 2;
local INFO      = 3;
local INFO2     = 4;

local ADDON_NAME, T = ...;

-- === Add-on basics and variable declarations {{{
T.SheepDog = LibStub("AceAddon-3.0"):NewAddon("SheepDog", "AceConsole-3.0", "AceEvent-3.0");
local SD = T.SheepDog;
local SharedMedias = LibStub("LibSharedMedia-3.0");
local LSM = LibStub("AceGUISharedMediaWidgets-1.0");


--@debug@
_SD_DEBUG = SD;
--@end-debug@

SD.Localized_Text = LibStub("AceLocale-3.0"):GetLocale("SheepDog", true);

local L = SD.Localized_Text;

SD.Constants = {};
local SD_C = SD.Constants;


-- SD:SetHandler (module, info, value) {{{

-- Used in Ace3 option table to get feedback when setting options through command line
function SD:SetHandler (module, info, value)

    module.db.global[info[#info]] = value;

    if info["uiType"] == "cmd" then

        if value == true then
            value = L["OPT_ON"];
        elseif value == false then
            value = L["OPT_OFF"];
        end

        self:Print(SD:ColorText(SD:GetOPtionPath(info), "FF00DD00"), "=>", SD:ColorText(value, "FF3399EE"));
    end
end -- }}}


local function GetCoreOptions() -- {{{
    return {
        type = 'group',
        get = function (info) return SD.db.global[info[#info]]; end,
        set = function (info, value) SD:SetHandler(SD, info, value) end,
        childGroups = 'tab',
        name = "SheepDog",
        order = 1,
        args = {
            Version_Header = {
                type = 'header',
                name = L["VERSION"] .. ' @project-version@',
                order = 1,
            },
            Release_Date_Header = {
                type = 'header',
                name = L["RELEASE_DATE"] .. ' @project-date-iso@',
                order = 2,
            },
            On = {
                type = 'toggle',
                name = L["OPT_ON"],
                desc = L["OPT_ON_DESC"],
                set = function(info) SD.db.global.Enabled = SD:Enable(); return SD.db.global.Enabled; end,
                get = function(info) return SD:IsEnabled(); end,
                order = 10,
            },
            Off = {
                type = 'toggle',
                name = L["OPT_OFF"],
                desc = L["OPT_OFF_DESC"],
                set = function(info) SD.db.global.Enabled = not SD:Disable(); return SD.db.global.Enabled; end,
                get = function(info) return not SD:IsEnabled(); end,
                order = 20,
            },

            Header1000 = {
                type = 'header',
                name = '',
                order = 30,
            },
            targetingSound = {
                type = 'select',
                dialogControl = 'LSM30_Sound',
                name = L["OPT_TARGETING_SOUND"],
                desc = L["OPT_TARGETING_SOUND_DESC"],
                values = AceGUIWidgetLSMlists.sound,
            },
            
            Debug = {
                type = 'toggle',
                name = L["OPT_DEBUG"],
                desc = L["OPT_DEBUG_DESC"],
                order = 1000,
            },
            Version = {
                type = 'execute',
                name = L["OPT_VERSION"],
                desc = L["OPT_VERSION_DESC"],
                guiHidden = true,
                func = function () SD:Print(L["VERSION"], '@project-version@,', L["RELEASE_DATE"], '@project-date-iso@') end,
                order = 1010,
            },
        },
    };
end -- }}}

local DEFAULT__CONFIGURATION = { -- {{{
global = {
    Enabled = true,
    Debug = false,
    targetingSound = 'SheepDog_Squeak',
}
};
-- }}}


-- = Add-on Management functions {{{
function SD:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("SheepDog", DEFAULT__CONFIGURATION);

    LibStub("AceConfig-3.0"):RegisterOptionsTable(tostring(self), GetCoreOptions, {"shed"});
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(tostring(self));

    self:RegisterChatCommand('SheepDog', function() LibStub("AceConfigDialog-3.0"):Open("SheepDog") end, true);
    
    self:SetEnabledState(self.db.global.Enabled);

    self:RegisterCCEffects();

    -- register sounds
    SharedMedias:Register('sound', 'SheepDog_Squeak', 'Interface\\AddOns\\SheepDog\\Sounds\\24731__propthis__SQUEAK3.ogg' );

end

function SD:OnEnable()

    self:RegisterEvent("UNIT_AURA");
--    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
    self:RegisterEvent("PLAYER_TARGET_CHANGED");

    self:Print(L["ENABLED"]);

end

function SD:OnDisable()

    self:Print(L["DISABLED"]);

end
-- }}}

-- }}}

-- CC spells management {{{
local CC_SPELLS_BY_NAME = {};
SD_C.CC_SPELLS_BY_NAME = CC_SPELLS_BY_NAME;
do
    local CC_SPELLS = {
        710, -- Banish
        31932, -- Freezing Trap Effect
        2637, -- Hibernate
        118, -- Polymorph (sheep)
        6770, -- sap
        6358, -- seduction
        9484, -- Shackle Undead
    };

    function SD:RegisterCCEffects ()
        for i, spellID in ipairs(CC_SPELLS) do
            if (GetSpellInfo(spellID)) then
                SD_C.CC_SPELLS_BY_NAME[(GetSpellInfo(spellID))] = true;
            else
                self:Debug(ERROR, "Missing spell:", spellID);
            end
        end
        self:Debug(INFO, "Spells registered!");
    end
end
-- }}}


-- function SD:Check_Unit(unit) {{{
do
    local UnitExists     = _G.UnitExists;
    local UnitCanAttack  = _G.UnitCanAttack;
    local UnitDebuff     = _G.UnitDebuff;
    local Debuff = false;
    function SD:Check_Unit(unit)

        if UnitExists(unit) and UnitCanAttack('player', unit) then
            self:Debug(INFO, "Checking", unit);
            local i = 1;
            while true do
                Debuff = (UnitDebuff(unit, i));
                i = i + 1;

                if not Debuff then
                    break;
                end

                if CC_SPELLS_BY_NAME[Debuff] then
                    self:Debug(INFO, "CC effect found on", unit, UnitIsCharmed(unit));
                    return Debuff;
                end
            end
        end

        return false;

    end
end -- }}}

-- Events handlers {{{
function SD:UNIT_AURA(selfevent, unit, other)
    --self:Debug("UNIT_AURA", unit, other);
    if unit == 'target' then
        -- scans debuffs
        local is_CC = self:Check_Unit('target');

        if is_CC then
            self:TargetIsCrowdControlled();
        end
    end
end

function SD:UPDATE_MOUSEOVER_UNIT()
    self:Debug("UPDATE_MOUSEOVER_UNIT");
end


function SD:PLAYER_TARGET_CHANGED()
    self:Debug("PLAYER_TARGET_CHANGED");

    -- scans debuffs
    local is_CC = self:Check_Unit('target');

    if is_CC then
        self:TargetIsCrowdControlled();
    end

end
-- }}}

local PlaySoundFile = _G.PlaySoundFile;
function SD:TargetIsCrowdControlled(ccDebuff)
    self:Print(L["TARGET_IS_CROWD_CONTROLLED"]);
    PlaySoundFile(SharedMedias:Fetch('sound', self.db.global.targetingSound));
end

