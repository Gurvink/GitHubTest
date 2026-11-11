local googleplay = require("_services.googleplay")
local ios = require("_services.ios")
local poki = require("_services.poki")
local steam = require("_services.steam")
adinfo = adinfo

local ads = require("_services.ads")
local analytics = require("_services.analytics")
local devicestore = require("_services.devicestore")
local interappcommunication = require("_modules.interappcommunication")

local devices = require("_modules.devices")

local M = {}

-- PLATFORM IDENTIFICATION
local PLATS = { NONE = "NONE", IOS = "IOS", ANDROID = "ANDROID", POKI = "POKI", STEAM =  "STEAM", SWITCH = "SWITCH"}
local currentplatform = PLATS.ANDROID    -- CHANGE THIS TO DECIDE THE PLATFORM.
_CURRENT_PLATFORM = currentplatform
_IS_NONE = (currentplatform == PLATS.NONE) == true
_IS_ANDROID = (currentplatform == PLATS.ANDROID) == true
_IS_IOS = (currentplatform == PLATS.IOS) == true
local poki_sdk_exists = (poki.exists() and true) or false
_IS_POKI = (currentplatform == PLATS.POKI) and poki_sdk_exists
_IS_HTML5 = (currentplatform == PLATS.POKI) and not poki_sdk_exists
_IS_STEAM = (currentplatform == PLATS.STEAM) == true
_IS_SWITCH = (currentplatform == PLATS.SWITCH) == true

_IS_MOBILEAPP = (_IS_ANDROID or _IS_IOS)
_IS_MOBILE = (_IS_MOBILEAPP or (_IS_POKI and (devices.mobile() or devices.tablet())))
_IS_STEAMDECK = (_IS_STEAM and steam.is_steam_deck())

-- APPTYPE IDENTIFICATION
local APPTYPE = { DEFAULT = "DEFAULT", CURATOR = "CURATOR", VIEWER = "VIEWER"}
local currentapptype = APPTYPE.DEFAULT
_IS_NONE = (currentapptype == APPTYPE.DEFAULT) == true
_IS_CURATOR = (currentapptype == APPTYPE.CURATOR) == true
_IS_VIEWER = (currentapptype == APPTYPE.VIEWER) == true


-- Methods
local init_mobile
local on_mobiledevice_init_done
local on_platform_init_done
local adinfo_setup

function M.initialize(callback)
    LOG_INFO("[PLATFORM]: Starting platform initialization")
    on_platform_init_done = callback

    -- MOBILE DEVICES
    if _IS_MOBILEAPP then
        LOG_INFO("[PLATFORM]: Starting mobile initialization")
        init_mobile()

    -- POKI / HTML5
    elseif _IS_POKI then
        LOG_INFO("[PLATFORM]: Starting web initialization")
        -- Unique Poki module not setup to work with this module yet.
        on_platform_init_done()
    elseif _IS_HTML5 then
        on_platform_init_done()
        
    -- STEAM
    elseif _IS_STEAM then
        LOG_INFO("[PLATFORM]: Starting Steam initialization")
        defos.toggle_fullscreen()
        steam.initialize(function()
            on_platform_init_done()
        end)
    
    -- FALLBACK
    else
        LOG_WARNING("[PLATFORM]: Cannot identify platform. Continuing without platform initialization.")
        on_platform_init_done()
    end
end


init_mobile = function()
    interappcommunication.initialize()

    LOG_INFO("Starting AdInfo and ATT")
    adinfo_setup(function (info)
        local att_allowed = info ~= nil and info.ad_tracking_enabled == true
        local idfa_gaid = "00000000-0000-0000-0000-000000000000"
        if att_allowed and info.ad_ident then idfa_gaid = info.ad_ident end
        analytics.set_idfa_gaid(idfa_gaid)

        local id_name = _IS_IOS and "IDFA" or "GAID"
        LOG_INFO("[ADINFO]: ATT/tracking allowed = " .. ((att_allowed == true) and "true" or "false"))
        LOG_INFO("[ADINFO]: " .. id_name .. " = " .. idfa_gaid)
        if info then LOG_INFO("[ADINFO]: ", info) else LOG_INFO("[ADINFO]: table is nil") end

        -- Google Play Game Services
        if _IS_ANDROID then
            googleplay.initialize(function()
                on_mobiledevice_init_done()
            end)
        -- Apple Game Centre
        elseif _IS_IOS then
            ios.initialize(function()
                on_mobiledevice_init_done()
            end)
        end
    end)
end

adinfo_setup = function (callback)
    if not adinfo then
        LOG_WARNING("[ADINFO]: Couldn't find AdInfo SDK")
		callback(nil)
		return
	end
    -- App Tracking Transparency
	adinfo.get(function(_, info)
		callback(info)
	end)
end

on_mobiledevice_init_done = function()
    LOG_INFO("Mobile initialization complete")
    LOG_INFO("Starting ad SDK initialization")
    -- Initialize ads
    ads.init(function ()
        LOG_INFO("Ad SDK initialization complete")
        LOG_INFO("Starting analytics SDK initialization")
        -- Initialize analytics 
        analytics.init(function()
             LOG_INFO("Analytics SDK initialization complete")
            -- Continue initialization through the callback            
            on_platform_init_done()
        end)
    end)
end

function M.initialize_devicestore()
    LOG_INFO("Starting devicestore initialization")
    devicestore.init()
end

return M