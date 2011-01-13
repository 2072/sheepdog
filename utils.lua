--[=[
SheepDog World of Warcraft Add-on
Copyright (c) 2011 by John Wellesz (Archarodim@teaser.fr)
All rights reserved

Version @project-version@

A very simple add-on that should prevent you from breaking crowd control spell.

This add-on uses the Ace3 framework.

type /SheepDog to get a list of existing options.

-----
    utils.lua
-----


--]=]

local ERROR     = 1;
local WARNING   = 2;
local INFO      = 3;
local INFO2     = 4;


local ADDON_NAME, T = ...;
local SD = T.SheepDog;

local SD_C = T.SheepDog.Constants;



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

        local template = type((select(1,...))) == "number" and (select(1, ...)) or false;

        local DebugHeader = (Debug_Templates[template]):format(date("%S"), (GetTime() % 1) * 1000);

        if template then
            self:Print(DebugHeader, select(2, ...));
        else
            self:Print(DebugHeader, ...);
        end
    end
end -- }}}


-- function HHTD:GetOPtionPath(info) {{{
function SD:GetOPtionPath(info)
    return table.concat(info, "->");
end -- }}}


