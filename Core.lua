--[=[
Sheepdog World of Warcraft Add-on
Copyright (c) 2011-2012 by John Wellesz (Archarodim@teaser.fr)
All rights reserved

Version @project-version@

A very simple add-on that should prevent you from breaking crowd control spell.

This add-on uses the Ace3 framework.

type /Sheepdog to get a list of existing options.

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
--  global                        == NAME__WORD2
--  locals                        == name_word2
--  members                       == Name_Word2

-- Debug templates
local ERROR     = 1;
local WARNING   = 2;
local INFO      = 3;
local INFO2     = 4;

local ADDON_NAME, T = ...;

-- === Add-on basics and variable declarations {{{
T.Sheepdog = LibStub("AceAddon-3.0"):NewAddon("Sheepdog", "AceConsole-3.0", "AceEvent-3.0");
local SD = T.Sheepdog;
local SharedMedias = LibStub("LibSharedMedia-3.0");
local LSM = LibStub("AceGUISharedMediaWidgets-1.0");

local _, _, _, tocversion = GetBuildInfo();
T._tocversion = tocversion;



--@debug@
_SD_DEBUG = SD;
--@end-debug@

SD.Localized_Text = LibStub("AceLocale-3.0"):GetLocale("Sheepdog", true);

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
        name = "Sheepdog",
        order = 1,
        args = {
            Description = {
                type = 'description',
                name = L["DESCRIPTION"],
                order = 1,
            },
            Version_Header = {
                type = 'header',
                name = L["VERSION"] .. ' @project-version@ - ' .. L["RELEASE_DATE"] .. ' @project-date-iso@',
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
            TargetingSound = {
                type = 'select',
                dialogControl = 'LSM30_Sound',
                name = L["OPT_TARGETING_SOUND"],
                desc = L["OPT_TARGETING_SOUND_DESC"],
                values = AceGUIWidgetLSMlists.sound,
                order = 40,
            },
            AlertSound = {
                type = 'select',
                dialogControl = 'LSM30_Sound',
                name = L["OPT_ALERT_SOUND"],
                desc = L["OPT_ALERT_SOUND_DESC"],
                values = AceGUIWidgetLSMlists.sound,
                disabled = function() return not SD.db.global.NearbyAlert end,
                order = 43,
            },
            Header2000 = {
                type = 'header',
                name = '',
                order = 45,
            },
            NearbyAlert = {
                type = 'toggle',
                name = L["OPT_NEARBYALERT"],
                desc = L["OPT_NEARBYALERT_DESC"],
                order = 50,
            },
            UseRaidAlertFrame = {
                type = 'toggle',
                name = L["OPT_USERAIDALERTFRAME"],
                desc = L["OPT_USERAIDALERTFRAME_DESC"],
                order = 60,
            },
            Header9000 = {
                type = 'header',
                name = '',
                order = 900,
            },
            Debug = {
                type = 'toggle',
                name = L["OPT_DEBUG"],
                desc = L["OPT_DEBUG_DESC"],
                guiHidden = true,
                order = 1000,
            },
            WelcomeMessage = {
                type = 'toggle',
                name = L["OPT_WELCOMEMESSAGE"],
                desc = L["OPT_WELCOMEMESSAGE_DESC"],
                order = 1010,
            },
            Version = {
                type = 'execute',
                name = L["OPT_VERSION"],
                desc = L["OPT_VERSION_DESC"],
                guiHidden = true,
                func = function () SD:Print(L["VERSION"], '@project-version@,', L["RELEASE_DATE"], '@project-date-iso@') end,
                order = 1020,
            },
        },
    };
end -- }}}

local DEFAULT__CONFIGURATION = { -- {{{
    global = {
        Enabled = true,
        Debug = false,
        TargetingSound = 'Sheepdog_MediumBark',
        AlertSound = 'Sheepdog_Whining_Dog',
        NearbyAlert = true,
        UseRaidAlertFrame = true,
        WelcomeMessage = true,
    }
};
-- }}}


-- = Add-on Management functions {{{
function SD:OnInitialize()

    self.db = LibStub("AceDB-3.0"):New("Sheepdog", DEFAULT__CONFIGURATION);

    if AddonLoader and AddonLoader.RemoveInterfaceOptions then
        AddonLoader:RemoveInterfaceOptions("Sheepdog")
    end

    LibStub("AceConfig-3.0"):RegisterOptionsTable(tostring(self), GetCoreOptions, {"shed"});
    --LibStub("AceConfigDialog-3.0"):AddToBlizOptions(tostring(self));

    self:RegisterChatCommand('Sheepdog', function() LibStub("AceConfigDialog-3.0"):Open("Sheepdog") end, true);
    

    self:RegisterCCEffects();

    self:CreateClassColorTables();

    -- register sounds
    SharedMedias:Register('sound', 'Sheepdog_Squeak', 'Interface\\AddOns\\Sheepdog\\Sounds\\24731__propthis__SQUEAK3.ogg' );
    SharedMedias:Register('sound', 'Sheepdog_Whining_Dog', 'Interface\\AddOns\\Sheepdog\\Sounds\\whining1.ogg' );
    SharedMedias:Register('sound', 'Sheepdog_MediumBark', 'Interface\\AddOns\\Sheepdog\\Sounds\\mediumBark.ogg' );

    self:SetEnabledState(self.db.global.Enabled);
end

function SD:OnEnable()

    self:RegisterEvent("PLAYER_TARGET_CHANGED");

    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

    if self.db.global.WelcomeMessage then
        self:Print(L["ENABLED"]);
    end

end

function SD:OnDisable()

    self:Print(L["DISABLED"]);

end
-- }}}

-- }}}

-- CC spells management {{{
SD_C.CC_SPELLS_BY_NAME = {};
do
    local CC_SPELLS = {

        -- http://www.wowwiki.com/Crowd_control

        -- warlock
        710, -- Banish
        5782, -- Fear - there is currently no way to detect glyphed fear so this will also works for normal Fear.
        6358, -- seduction

        -- shamans
        -- 76780, -- Bind Elemental (removed in WoD)
        51514, -- Hex

        -- druids
        -- 2637, -- Hibernate (removed in WoD)

        -- mages
        118, -- Polymorph (sheep)

        -- paladins
        20066, -- Repentance

        -- rogues
        6770, -- sap

        -- priests
        9484, -- Shackle Undead

        -- hunters
        -- 31932, -- Freezing Trap Effect (too short)
        19386, -- Wyvern Sting

        -- monks
        115078, -- Paralysis
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

local CC_SPELLS_BY_NAME = SD_C.CC_SPELLS_BY_NAME;

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

--local TARGET_SOUND_PLAYED = false;

-- Events handlers {{{
--[=[ unused events {{{
function SD:UNIT_AURA(selfevent, unit, other)
    --self:Debug("UNIT_AURA", unit, other);
    if unit == 'target' then
        -- scans debuffs
        local is_CC = self:Check_Unit('target');

        if is_CC then
            self:TargetIsCrowdControlled();
        else
            TARGET_SOUND_PLAYED = false;
        end
    end
end

function SD:UPDATE_MOUSEOVER_UNIT()
    self:Debug("UPDATE_MOUSEOVER_UNIT");
end

-- }}} ]=]

function SD:PLAYER_TARGET_CHANGED()
    -- scans debuffs
    local is_CC = self:Check_Unit('target');

    if is_CC then
        self:TargetIsCrowdControlled();
    end
end

do
    local band      = _G.bit.band;
    local UnitGUID  = _G.UnitGUID;

    local OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER;

    local TOC = T._tocversion;
    local nothing = 'nothing';

    function SD:COMBAT_LOG_EVENT_UNFILTERED(e, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellNAME)

        -- the event must be SPELL_AURA_APPLIED
        if event ~= "SPELL_AURA_APPLIED" then
            --self:Debug(INFO2, "not SPELL_AURA_APPLIED", event);
            return;
        end

        -- the spell must be part of CC_SPELLS_BY_NAME
        if not CC_SPELLS_BY_NAME[spellNAME] then
            --self:Debug(INFO2, "not a cc spell:", spellNAME);
            return;
        end

        -- the source must be a friendly player inside you raid/group ie: not an outsider
        if band(sourceFlags, OUTSIDER) == OUTSIDER then
            --self:Debug(INFO2, sourceName "is an outsider");
            return;
        end

        --@debug@
        sourceGUID = ""; -- to test output
        --@end-debug@

        -- we don't care if it's ourself
        if sourceGUID == UnitGUID('player') then
            --self:Debug("Nearby filter would have fired");
            return;
        end

        -- if the CCed unit is our target then issue a warning
        if destGUID == UnitGUID('target') then
            self:TargetIsCrowdControlled();
            --@debug@
            --self:UnitCrowdControlledNearBy(destName, destFlags, arg9, spellNAME, sourceName);
            --@end-debug@
        else
            self:UnitCrowdControlledNearBy(destName, destRaidFlags, spellID, spellNAME, sourceName);
        end
       
    end
end

-- }}}

local PlaySoundFile = _G.PlaySoundFile;
function SD:TargetIsCrowdControlled(ccDebuff)

    if RaidWarningFrame and self.db.global.UseRaidAlertFrame then
        RaidNotice_AddMessage( RaidWarningFrame, L["TARGET_IS_CROWD_CONTROLLED"], ChatTypeInfo["RAID_WARNING"] );
    else
        UIErrorsFrame:AddMessage(L["TARGET_IS_CROWD_CONTROLLED"], 1, 0, 0, 1, UIERRORS_HOLD_TIME)
    end

    PlaySoundFile(SharedMedias:Fetch('sound', self.db.global.TargetingSound));

end

local UnitClass = _G.UnitClass;
local band      = _G.bit.band;
local ICON_LIST = _G.ICON_LIST
function SD:UnitCrowdControlledNearBy(unitName, unitRaidFlags, spellID, spellName, sourceName, sourceGUID)

    if not self.db.global.NearbyAlert then
        return;
    end

    local sourceClassColor = "FF909090";
    if UnitClass(sourceName) then
        sourceClassColor = self:GetClassHexColor(  select(2, UnitClass(sourceName) ) );
    end

    -- extract raid target number
    local raidIcon = SD:GetHighestBitPostion(band(unitRaidFlags, 0xFF));
    --self:Debug(raidIcon, unitRaidFlags, band(unitRaidFlags, 0xFF));

    local message = (L["UNIT_NEARBY_IS_CROWD_CONTROLLED"]):format( 
        ("|cff11cc00|Hspell:%d|h%s|h|r"):format(spellID, self:SafeString( spellName ) ), -- clickable spellname
        self:ColorText(self:SafeString( unitName ), "FFFF0000") .. (raidIcon ~= 0 and (" (%s:0|t)"):format( ICON_LIST[raidIcon] ) or "" ), -- target name in red with raid icon
        ("|Hplayer:%s|h%s|h"):format(self:SafeString( sourceName ), self:ColorText(self:SafeString( sourceName ), sourceClassColor)) -- clicable colored player name
    );

    self:Print(message);

    if RaidWarningFrame and self.db.global.UseRaidAlertFrame then
        RaidNotice_AddMessage( RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"] );
    else
        UIErrorsFrame:AddMessage(message, 1, 0, 0, 1, UIERRORS_HOLD_TIME)
    end

    PlaySoundFile(SharedMedias:Fetch('sound', self.db.global.AlertSound));
end

