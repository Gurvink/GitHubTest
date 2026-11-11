local USE_AB_TESTING = false
local savemanager = require("_modules.savemanager")

local M = {}

M.versions = {
    DEFAULT = {
        version_name = "default",
        weight = 100,
    },
    A = {
        version_name = "a",
        weight = 0,
    },
    B = {
        version_name = "b",
        weight = 0,
    },
}
-- DEBUG: Used for testing a specific version. This will always override the saved version
local FORCE_VERSION = nil
-- DEBUG: Used for testing. Setting this to true will force a new version to be chosen on init
local FORCE_VERSION_CREATION = false
local DO_TEST_ROLLS = false

M.has_test_version = false
M.test_version = nil

function M.create_AB_version()
    local total_weight = 0
    for _, value in pairs(M.versions) do
        total_weight = total_weight + (value.weight or 0)
    end
    local version = M.versions.DEFAULT

    if total_weight ~= 100 then
        LOG_WARNING("AB version weights do not add up to 100", {
            total_weight = total_weight,
            versions = M.versions
        })
        return version
    end

    LOG_INFO("Creating AB version for user", {
        versions_available = M.versions,
    })

    math.randomseed(os.time())

    local chosen_key = version.version_name

    if total_weight > 0 then
        if DO_TEST_ROLLS then
            local count_table = {
                default = 0,
                a = 0,
                b = 0
            }
    
            for _ = 1, 10000 do
                local roll = math.random(total_weight)
                local cumulative = 0
                for key, value in pairs(M.versions) do
                    cumulative = cumulative + (value.weight or 0)
                    if roll <= cumulative then
                        count_table[value.version_name] = count_table[value.version_name] + 1
                        version = value
                        chosen_key = key
                        break
                    end
                end
            end
    
            LOG_INFO("Performed 10000 rolls, versions chosen: ",count_table)
        end

        local roll = math.random(total_weight)
        local cumulative = 0
        for key, value in pairs(M.versions) do
            cumulative = cumulative + (value.weight or 0)
            if roll <= cumulative then
                version = value
                chosen_key = key
                break
            end
        end
    else
        LOG_WARNING("AB version weights total is 0, falling back to DEFAULT")
    end

    LOG_INFO("Choose version: " .. chosen_key)
    return version
end

function M.initialize_AB_version()
    local application_version = nil
    if _IS_IOS then
        application_version = sys.get_config_string("ios.bundle_version","1.0.0")
    elseif _IS_ANDROID then
        application_version = sys.get_config_number("android.version_code",-1)
    end
    LOG_INFO("application version: " .. (application_version or ""))
    if not USE_AB_TESTING then
        LOG_INFO("AB testing is turned off for this version, resetting version in savemanager to 'DEFAULT'")
        savemanager.set_testing_version(M.versions.DEFAULT, application_version,true)
    end
    local version = savemanager.get_testing_version()

    if FORCE_VERSION then
        version = FORCE_VERSION
        savemanager.set_testing_version(version, application_version, true)
        LOG_INFO("Forcing version: " .. FORCE_VERSION.version_name)
    end

    local has_application_version_mismatch = (version and version.application_version ~= application_version)
    local should_create_new_version = (not version and savemanager.get_firstboot() == true)
    local force_new_version = FORCE_VERSION_CREATION and not FORCE_VERSION

    --if (not version and savemanager.get_firstboot() == true) or (FORCE_VERSION_CREATION and not FORCE_VERSION) then -- User has not had a version set yet, initialize the AB tests
    if (should_create_new_version or force_new_version) or has_application_version_mismatch then
        version = M.create_AB_version()
        savemanager.set_testing_version(version,application_version)
    end

    if not version then
        version = M.versions.DEFAULT
        savemanager.set_testing_version(version,application_version)
    end

    if version ~= M.versions.DEFAULT then
        M.has_test_version = true
    end

    M.test_version = version
end

function M.get_version()
    return savemanager.get_testing_version()
end

return M