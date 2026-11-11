local M = {}

local json = require("cjson")

local PLATFORM_TO_PLATS = {
    ["ios"] = "IOS",
    ["android"] = "ANDROID",
    ["windows"] = "STEAM",
    ["macos"] = "STEAM",
    ["linux"] = "STEAM",
    ["html5"] = "POKI"
}

local APP_TYPE_TO_APPTYPE = {
    ["default"] = "DEFAULT",
    ["curator"] = "CURATOR",
    ["viewer"] = "VIEWER",
}


local function read_file(path)
    path = path:gsub("^/", "")

    local file, err = io.open(path, "rb")
    if not file then
        error("Cannot read " .. path .. ": " .. tostring(err))
    end

    local content = file:read("*a")
    file:close()

    return content
end

local function write_file(path, content)
    path = path:gsub("^/", "")

    local file, err = io.open(path, "wb")
    if not file then
        error("Cannot write " .. path .. ": " .. tostring(err))
    end

    file:write(content)
    file:close()
end


function patch_platform_settings(platform, app_type, platform_path)
    print("Patching platform", platform, app_type)

    local platform_key = PLATFORM_TO_PLATS[platform]
    if not platform_key then
        error("Unknown platform: " .. platform)
    end

    local app_type_key = APP_TYPE_TO_APPTYPE[app_type]
    if not app_type_key then
        error("Unknown app type: " .. app_type)
    end

    local text = read_file(platform_path)
    local new_text, platform_count = text:gsub(
        "(local%s+currentplatform%s*=%s*)PLATS%.[%w_]+",
        "%1PLATS." .. platform_key,
        1
    )
    if platform_count ~= 1 then
        error("Could not find local currentplatform assignment in platform.lua")
    end

    local final_text, app_type_count = new_text:gsub(
        "(local%s+currentapptype%s*=%s*)APPTYPE%.[%w_]+",
        "%1APPTYPE." .. app_type_key,
        1
    )

    if app_type_count ~= 1 then
        error("Could not find local currentapptype assignment in platform.lua")
    end

    if final_text ~= text then
        write_file(platform_path, final_text)
    end

    print("Patched platform settings")
end

function patch_gamemanager_debug(debug_enabled, gamemanger_path)
    print("Patching gamemanager debug to", debug_enabled, gamemanger_path)
    local bypass_value = debug_enabled and "false" or "true"
    local text = read_file(gamemanger_path)
    local new_text, count = text:gsub(
        "M%.DEBUG_bypass_debug_check%s*=%s*%S+",
        "M.DEBUG_bypass_debug_check = " .. bypass_value,
        1
    )

    if count ~= 1 then
        error("Could not find M.DEBUG_bypass_debug_check assignment in gamemanger.lua")
    end

    if new_text ~= text then
        write_file(gamemanger_path, new_text)
    end
end

function patch_amplitude_settings(amplitude_enabled, amplitude_region_lock, config_path)
    print("Patching amplitude settings to", amplitude_enabled, amplitude_region_lock, config_path)
    local enabled_value = amplitude_enabled and "true" or "false"
    local region_lock_value = amplitude_region_lock and "true" or "false"
    local text = read_file(config_path)

    local new_text, enabled_count = text:gsub(
        "M%.amplitude_enabled%s*=%s*%S+",
        "M.amplitude_enabled = " .. enabled_value,
        1
    )

    if enabled_count ~= 1 then
        error("Could not find M.amplitude_enabled assignment in config.lua")
    end

    local final_text, region_lock_count = new_text:gsub(
        "M%.amplitude_region_lock%s*=%s*%S+",
        "M.amplitude_region_lock = " .. region_lock_value,
        1
    )
    if region_lock_count ~= 1 then
        error("Could not find M.amplitude_region_lock assignment in config.lua")
    end

    if final_text ~= text then
        write_file(config_path, new_text)
    end

    print("Patched amplitude settings")

end

function patch_ab_testing(ab_testing_enabled, force_version_enabled, force_version, force_version_creation,
                          ab_tester_path)
    print("Patching ab testing settings to", ab_testing_enabled, force_version_enabled, force_version,
        force_version_creation, ab_tester_path)
    local ab_testing_value = ab_testing_enabled and "true" or "false"
    local force_version_value = force_version_enabled and ("M.versions." .. force_version) or "nil"
    local force_version_creation_value = force_version_creation and "true" or "false"
    local text = read_file(ab_tester_path)

    local new_text, ab_testing_count = text:gsub(
        "local%s+USE_AB_TESTING%s*=%s*%S+",
        "local USE_AB_TESTING = " .. ab_testing_value,
        1
    )
    if ab_testing_count ~= 1 then
        error("Could not find local USE_AB_TESTING assignment in A_B_tester.lua")
    end

    local after_force_version, force_version_count = new_text:gsub(
        "local%s+FORCE_VERSION%s*=%s*%S+",
        "local FORCE_VERSION = " .. force_version_value,
        1
    )
    if force_version_count ~= 1 then
        error("Could not find local FORCE_VERSION assignment in A_B_tester.lua")
    end

    local final_text, force_creation_count = after_force_version:gsub(
        "local%s+FORCE_VERSION_CREATION%s*=%s*%S+",
        "local FORCE_VERSION_CREATION = " .. force_version_creation_value,
        1
    )
    if force_creation_count ~= 1 then
        error("Could not find local FORCE_VERSION_CREATION assignment in A_B_tester.lua")
    end

    if final_text ~= text then
       write_file(ab_tester_path, final_text)
    end

    print("Patched ab testing")
end

function patch_custom_api_sandbox(custom_api_path)
    print("Patching custom API sandbox to false in", custom_api_path)
    local text = read_file(custom_api_path)
    local new_text, count = text:gsub(
        "local%s+USE_SANDBOX_ENVIRONMENT%s*=%s*%S+",
        "local USE_SANDBOX_ENVIRONMENT = false",
        1
    )
    if count ~= 1 then
        error("Could not find local USE_SANDBOX_ENVIRONMENT assignment in custom_API.lua")
    end

    if new_text ~= text then
        write_file(custom_api_path, new_text)
    end

    print("Patched custom API sandbox")
end

function patch_game_project(platform, version, version_code, bundle_version, GAME_PROJECT_PATH)

    print("Patching game project to", platform, version, version_code, bundle_version, GAME_PROJECT_PATH)
    local project_text = read_file(GAME_PROJECT_PATH)
    project_text = project_text:gsub("%s+version%s*=%s*%S+", "\nversion = " .. version, 1)

    if platform == "android" then
        if not version_code then
            error("version_code is required for Android builds")
        end
        project_text = project_text:gsub("%s+version_code%s*=%s*%S+", "version_code = " .. version_code, 1)
    elseif platform == "ios" then
        if not bundle_version then
            error("bundle_version is required for iOS builds")
        end

        project_text = project_text:gsub("%s+bundle_version%s*=%s*%S+", "bundle_version = \"" .. bundle_version .. "\"", 1)
    end

    write_file(GAME_PROJECT_PATH, project_text)

    print("Patched game project")
end

function M.patch_bundle(platform, settings, data)
    patch_platform_settings(platform, settings.app_type, data.platform_path)
 
    patch_gamemanager_debug(settings.debug, data.gamemanager_path)
   
    patch_amplitude_settings(settings.amplitude, settings.region_lock, data.config_path)
  
    patch_ab_testing(settings.ab_testing, settings.force_version, settings.forced_version,settings.force_creation, data.ab_tester_path)
   
    patch_custom_api_sandbox(data.custom_api_path)
  
    patch_game_project(platform, data.version, settings.version_code, settings.bundle_version, data.game_project_path)
end

if arg then

    local PLATFORM_TO_PLAT = {
        ["wasm-web"] = "html5",
        ["x86_64-macos"] = "macos",
        ["x86_64-linux"] = "linux",
        ["x86_64-win32"] = "windows",
        ["arm64-ios"] = "ios",
        ["armv7-android"] = "android"
    }

    local platform = PLATFORM_TO_PLAT[arg[1]]
    local data_json = arg[2]

    if not platform or not data_json then
        pprint(arg, platform, data_json)
        error("Usage: lua custom_bundle_patcher.lua")
    end

    local data = json.decode(data_json)
    local settings = data.platforms[platform]

    M.patch_bundle(platform, settings, data)
end

return M
