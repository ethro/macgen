local E, _, V, P, G = unpack(ElvUI)
local L = E.Libs.ACL:GetLocale('ElvUI', E.global.general.locale)
local EP = LibStub('LibElvUIPlugin-1.0')
local addon, Engine = ...

local _G = _G
local format = format
local GetAddOnMetadata = GetAddOnMetadata
local SetCVar = SetCVar

local macgen = E:NewModule(addon, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

Engine[1] = macgen -- macgen
Engine[2] = E -- ElvUI Engine
Engine[3] = L -- ElvUI Locales
Engine[4] = V -- ElvUI PrivateDB
Engine[5] = P -- ElvUI ProfileDB
Engine[6] = G -- ElvUI GlobalDB
_G[addon] = Engine

-- Constants
macgen.Config = {}
macgen.CreditsList = {}
macgen.DefaultFont = 'Expressway'
macgen.DefaultTexture = 'Minimalist'
macgen.Name = '|cff4beb2cmacgen|r'
macgen.RequiredVersion = 13.04
macgen.Version = GetAddOnMetadata(addon, 'Version')

function macgen:initialize()
	-- EP:RegisterPlugin(addon, macgen.Config)
	macgen:RegisterEvents()
end

local function callback_initialize()
	macgen:initialize()
end

E:RegisterModule(addon, callback_initialize)
