--[=[
Sheepdog World of Warcraft Add-on
Copyright (c) 2011-2018 by John Wellesz (Sheepdog@2072productions.com)
All rights reserved

Version @project-version@

A very simple add-on that should prevent you from breaking crowd control spell.

This add-on uses the Ace3 framework.

type /Sheepdog to get a list of existing options.

-----
    utils.lua
-----


--]=]

local ERROR     = 1;
local WARNING   = 2;
local INFO      = 3;
local INFO2     = 4;


local ADDON_NAME, T = ...;
local SD = T.Sheepdog;

local SD_C = T.Sheepdog.Constants;


function SD:ColorText (text, color) --{{{

    if type(text) ~= "string" then
        text = tostring(text)
    end

    return "|c".. color .. text .. "|r";
end --}}}


-- function SD:UnitName(Unit) {{{
local UnitName = _G.UnitName;
function SD:UnitName(Unit)
    local name, server = UnitName(Unit);
        if ( server and server ~= "" ) then
            return name.."-"..server;
        else
            return name;
        end 
end
-- }}}


function SD:TableMap(t, f)
    local mapped_t = {};
    for k,v in pairs(t) do
        mapped_t[k] = f(v);
    end
    return mapped_t;
end

--  function SD:Debug(...) {{{
do
    local Debug_Templates = {
        [ERROR]     = "|cFFFF2222Debug:|cFFCC4444[%s.%3d]:|r|cFFFF5555",
        [WARNING]   = "|cFFFF2222Debug:|cFFCC4444[%s.%3d]:|r|cFF55FF55",
        [INFO]      = "|cFFFF2222Debug:|cFFCC4444[%s.%3d]:|r|cFF9999FF",
        [INFO2]     = "|cFFFF2222Debug:|cFFCC4444[%s.%3d]:|r|cFFFF9922",
        [false]     = "|cFFFF2222Debug:|cFFCC4444[%s.%3d]:|r",
    }
    local select, type = _G.select, _G.type;
    function SD:Debug(...)
        if not SD.db.global.Debug then return end;

        local template = (type((select(1,...))) == "number" and Debug_Templates[select(1, ...)]) and (select(1, ...)) or false;

        local DebugHeader = (Debug_Templates[template]):format(date("%S"), (GetTime() % 1) * 1000);

        if template then
            self:Print(DebugHeader, select(2, ...));
        else
            self:Print(DebugHeader, ...);
        end
    end
end -- }}}


-- function SD:GetOPtionPath(info) {{{
function SD:GetOPtionPath(info)
    return table.concat(info, "->");
end -- }}}


-- function SD:SafeString(value) {{{
do
    local type = _G.type;
    function SD:SafeString(value)

        if type(value) ~= "string" then
            return type(value);
        end

        return value;

    end
end -- }}}


-- Class coloring related functions {{{
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS;

SD_C.ClassesColors = { };

local LC = _G.LOCALIZED_CLASS_NAMES_MALE;

function SD:GetClassColor (englishClass) -- {{{
    if not SD_C.ClassesColors[englishClass] then
        if RAID_CLASS_COLORS and RAID_CLASS_COLORS[englishClass] then
            SD_C.ClassesColors[englishClass] = { RAID_CLASS_COLORS[englishClass].r, RAID_CLASS_COLORS[englishClass].g, RAID_CLASS_COLORS[englishClass].b };
        else
            SD_C.ClassesColors[englishClass] = { 0.63, 0.63, 0.63 };
        end
    end
    return unpack(SD_C.ClassesColors[englishClass]);
end -- }}}

SD_C.HexClassColor = { };

function SD:GetClassHexColor(englishClass) -- {{{

    if not SD_C.HexClassColor[englishClass] then

        local r, g, b = self:GetClassColor(englishClass);

        SD_C.HexClassColor[englishClass] = ("FF%02x%02x%02x"):format( r * 255, g * 255, b * 255);

    end

    return SD_C.HexClassColor[englishClass];
end -- }}}

local NON_CLASSIC_CLASSES = {
        ["DEMONHUNTER"]    = true,
        ["DEATHKNIGHT"]    = true,
        ["MONK"]           = true
    
};

function SD:CreateClassColorTables () -- {{{
    if RAID_CLASS_COLORS then
        local class, colors;
        for class in pairs(RAID_CLASS_COLORS) do
            if LC[class] then -- thank to a wonderful add-on that adds the wrong translation "Death Knight" to the global RAID_CLASS_COLORS....
                SD:GetClassHexColor(class);
            else
                if not (SD_C.WOWC and NON_CLASSIC_CLASSES[class]) then
                    RAID_CLASS_COLORS[class] = nil; -- Eat that!
                    print("Sheepdog: |cFFFF0000Stupid value found in _G.RAID_CLASS_COLORS table|r\nThis will cause many issues (tainting), Sheepdog will display this message until the culprit add-on is fixed or removed, the Stupid value is: '", class, "'");
                end
            end
        end
    else
        SD:Debug(ERROR, "global RAID_CLASS_COLORS does not exist...");
    end
end -- }}}
-- }}}


-- function SD:GetHighestBitPostion(num) {{{
local band      = _G.bit.band;
function SD:GetHighestBitPostion(num)

    if num == 0 then
        return 0;
    end

    if band(num, num-1) ~= 0 then
        SD:Debug(ERROR, num, "is not a power of 2!", band(num, num-1));
        return;
    end


    local pos = 1;
    while num ~= 1 do
        num = num / 2;
        pos = pos + 1;
    end

    if pos > 64 then SD:Debug(ERROR, num, "loop!"); return 0; end

    return pos;

end -- }}}


