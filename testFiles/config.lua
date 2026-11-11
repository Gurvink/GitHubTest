local devices = require("_modules.devices")
local M = {}
_IS_DEBUG = sys.get_engine_info().is_debug
_IS_DEFOLDEDITOR = sys.get_engine_info().is_debug and devices.desktop()

-- IAP
M.iap_product_remove_ads = "ldnoads"
M.iap_product_usd_price = {                         -- USD reference price per product. Used for accumulating spent money.
    [M.iap_product_remove_ads] = 5.99,
}
M.iap_product_consumable = {
}

-- ADJUST
M.adjust_app_token      = "l0z1imr4gg74"
-- Set true to send Adjust traffic to the sandbox. Release builds force this off.
local adjust_sandbox_in_debug = false
M.adjust_is_sandbox     = _IS_DEBUG and adjust_sandbox_in_debug
M.adjust_log_level      = 'info'
M.adjust_send_in_background = true
M.adjust_iap_verify_purchases = true                    -- Set true after enabling Purchase Verification for this app in the Adjust dashboard (steps 2–4).
                                                        -- While false, verify_purchase is skipped to avoid code 20011 noise in logcat.
M.adjust_events = {
    IAP_GROSS_ADDED = "863uuo",
    UNIQUE_FIRST_IAP = "3c17y5",
}

-- FIREBASE
-- On for every debug build, off for every release build. iOS applies this at startup (DebugView needs it in the build). Android ignores it;
-- To use DebugView on Android, use: "adb shell setprop debug.firebase.analytics.app com.unept.leveldevil".
M.testing_firebase_debugview = _IS_DEBUG
M.firebase_manual_iap_android = false                       -- Google Play reports in_app_purchase automatically once linked. Enabling this as well double-counts purchases.

-- TIKTOK APP EVENTS SDK (placeholders — paste values from TikTok Events Manager)
M.tiktok_access_token = { android = "TTtMriLcQXMvCEtl7oATqzufYhW0OtMr", ios = "TTspRxEk0usY4p0dyzihrS50DA8tjOks" } -- App Secret per platform
M.tiktok_app_id = { android = "com.unept.leveldevil", ios = "6477413486" }
M.tiktok_tiktok_app_id = { android = "7642343100236496914", ios = "7642343724755779592" }
M.tiktok_disable_skan = true -- Keep true while Adjust owns SKAdNetwork conversion values.
M.tiktok_debug = _IS_DEBUG and (devices.android() or devices.ios())     -- On for debug builds on Android and iOS. Release builds, desktop, and web stay off.

-- APPLOVIN
M.applovin_sdk_key      = "UC4dE5iwLvPlqf99TgWLEDdlkbUyJxIntEBz2x5nNxcKmexlr8EQJqlBJS_BD2D_yTbsqv3IrAA6275cyJ0neL"
M.applovin_use_test_ad_units = false                        -- Debug builds only. Release builds ignore this and keep the live ad units.
M.hyprmx_test_mode = false                                  -- Debug builds only. Release builds ignore this and keep live HyprMX ads.
M.applovin_test_interstitial = { android = "2d13706de496bb72", ios = "1ca979b533945dfe" }
M.applovin_test_rewarded = { android = "2f6921959487bd40", ios = "9bdf167f98c665a6" }

-- AMPLITUDE
M.amplitude_enabled = false
M.amplitude_region_lock = false -- When true, Amplitude only runs for users in the countries below.
M.amplitude_allowed_countries = {US = true, GE = true}
M.amplitude_url = "https://api2.amplitude.com/2/httpapi"    -- M.amplitude_url_europe = "https://api.eu.amplitude.com/2/httpapi"
M.amplitude_api_key = "22879a7c29b7f12f3fb0786ab5c7c806"    -- DebugKey = bb4aba29a64cc7f2b2600f893d705a23 -- ReleaseKey = 22879a7c29b7f12f3fb0786ab5c7c806
M.amplitude_headers = { ["Content-Type"] = "application/json", ["Accept"] = "*/*" }
M.amplitude_savelocation = {folder = "leveldevil", file = "analytics_state"}

return M