local M = {}

local USE_SANDBOX_ENVIRONMENT = false

local BASE_URL = "libinj9yai"
local PROD_SUFFIX = "prod"
local SANDBOX_BASE_URL = "2mlhxwo8k2"
local SANDBOX_SUFFIX = "sandbox"

local PROD_URL = "https://".. BASE_URL ..".execute-api.eu-central-1.amazonaws.com/" .. PROD_SUFFIX .. "/"
local SANDBOX_URL = "https://".. SANDBOX_BASE_URL ..".execute-api.eu-central-1.amazonaws.com/" .. SANDBOX_SUFFIX .. "/"

local SANBOX_API_KEY = "wjJmDjiPt84l7iOzfBRCN4AUGHUMm5Dq"
local PROD_API_KEY = "Yn0dW3qh4xif0bQEL8PM7ndJUlSDIBDL"

function M.get_API_URL()
    return USE_SANDBOX_ENVIRONMENT and SANDBOX_URL or PROD_URL
end

function M.get_API_KEY()
    return USE_SANDBOX_ENVIRONMENT and SANBOX_API_KEY or PROD_API_KEY
end

return M