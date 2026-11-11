local chapterinfo       = require("_modules.chapterinfo")
local savemanager       = require("_modules.savemanager")
local soundmanager      = require("_modules.soundmanager")
local ads               = require("_services.ads")
local devicestore       = require("_services.devicestore")
local poki              = require("_services.poki")
local achievements      = require("_services.achievements")
local level_select_info = require "_modules.level-select.level-select-info"
local monarch           = require("monarch.monarch")
local analytics         = require("_services.analytics")
local analytics_duration = require("_modules.analytics_duration")
local config            = require("_services.config")
local infinite_mode     = require("_modules.infinite_mode")
local AB_test           = require("_modules.A_B_tester")

local M = {}

M.DEBUG_bypass_mobile_check = false -- EDIT THIS TO FORCE THE MOBILE BUTTONS TO APPEAR
M.DEBUG_bypass_desktop_check = false -- EDIT THIS TO FORCE THE MOBILE BUTTONS TO APPEAR
M.DEBUG_bypass_debug_check = true -- EDIT THIS TO REMOVE CERTAIN DEBUG-ONLY MECHANICS

M.DEBUG_visuals_active = false
M.DEBUG_fastmode_active = false

local cursorpos = vmath.vector3() -- Updated by customcursor.gui_script.

M.currentlevel = {chapter = 1, portal = 1, level = 1}
M.levels_without_indicator = {
    {chapter = 1, portal = 0, level = 1},
    {chapter = 1, portal = 16, level = 7},
    {chapter = 1, portal = 16, level = 8},
    {chapter = 2, portal = 14, level = 1},
    {chapter = 2, portal = 14, level = 2},
    {chapter = 3, portal = 16, level = 6},
    {chapter = 2, portal = 0, level = 1},
    {chapter = -1, portal = -2, level = -1},
    {chapter = -1, portal = -3, level = -1},
    {chapter = -1, portal = -4, level = -1},
    {chapter = -1, portal = -1, level = -1},
}
local early_conquer_levels = {
    {chapter = 1, portal = 16, level = 5},
    {chapter = 2, portal = 14, level = 1},
    {chapter = 3, portal = 16, level = 5},
}
M.currentleveldata = {foreground_color = vmath.vector4(1,1,1,1), background_color = vmath.vector4(0.3,0.3,0.3,1), mapsize_in_units = vmath.vector3(528,336, 0), mapobject_offset = vmath.vector3(0,0,0)}
M.currentlevelobjects = {}

M.heroes = {}
M.is_versusmode = false
M.is_speedrunmode = false
M.is_countdown_active = false
M.versus_score = {p1 = 0, p2 = 0}
M.is_results_level = false
M.is_current_level_curated = false
M.first_input = false
M.hero_died = false  --Boolean to prevent multiple heroes from counting as multiple heroes dying at the same time
M.level_editor_level_complete = false
M.recieved_file = nil
M.browser_share_level_code = nil
M.browser_level_name = nil
M.show_results_page = false
M.infinite_mode_send_to_browser = false
M.is_complete_popup_open = false


M.collections = {
    main = "main",
    -- modeselect = "menu-modeselect",
    modeselect = "menu-levelselect",
    levelselect = "menu-levelselect",
    sublevels = "menu-sublevels",
    levelselect_c1 = "menu-levelselect",
    levelselect_c2 = "menu-levelselect",
    levelselect_c3 = "menu-levelselect",
    langselect = "menu-langselect",
    level = "level",
    level_editor_saves = "level-editor-saves",
    level_editor_curator = "level-editor-curator",
    level_editor_viewer = "level-editor-viewer",
    level_editor_modeselect = "level-editor-mode-select",
    level_editor = "level-editor",
    level_browser = "level-browser",
    settings = "menu-settings",
    debug = "debug",
    texture_tester = "texture_tester",
}
local current_collection = M.collections.main
M.settings_previous_screen = M.collections.levelselect

function M.get_level_editor_saves_collection()
	if _IS_CURATOR then
		return M.collections.level_editor_curator
	end
	if _IS_VIEWER then
		return M.collections.level_editor_viewer
	end
	return M.collections.level_editor_saves
end

M.url_transition = "transition:/GUI#transition"
M.url_letterbox = "transition:/GUI#letterbox"
M.gui_render_orders = {
    customcursor = 15,
    DEBUG_gui = 14,
    popup_menu = 10,
    speedrun = 7,
    transition = 6,
    menu_modeselect = 5,
    menu_levelselect = 5,
    menu_settingsselect = 5,
    menu_level_editor_modeselect = 5,
    menu_level_browser = 5,
    menu_level_editor_saves = 5,
    menu_langselect = 5,
    pausemenu = 4,
    hud_level = 3,
    virtualbuttons = 3,
    level_editor_gui = 3,
    property_window_gui = 2,
    letterbox = 2,
    hud_skullkeys = 1,
}

M.poki_gameplay_states = {
	START = 'start',
	STOP = 'stop'
}

---@deprecated use remote_config.values instead
---@type table
M.remote_parameters = {}

M.ad_variables = {
    interstitial_ad_immunity = 1, --Counter, counting up from 1
    level_timer = 0,
    level_death_counter = 0,
    level_death_interstitial_counter = 0,
    general_timer = 0,
    session_level_progression = 0,
    punishment_ad_level_index = 5,
    punishment_ad_checked_level = 3,
    punishment_ad_max_deaths = 3,
    punishment_ad_level_skip = 4,
    show_ad_at_end_of_portal = false,
    show_ad_override = false,
    interstitial_per_portal = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
    },
    infinitemode_skip_amount = 0,
    infinitemode_timer = 0,
}

M.languages = { 
    "English",
    "简体中文",
    "Français",
    "繁體中文",
    "Deutsch",
    "日本語",
    "Português",
    "Español"
}

M.inputs_held = {
    -- p1
    {
        left = false,
        right = false,
        up = false,
        down = false,
        jump = false,
    },
    -- p2
    {
        left = false,
        right = false,
        up = false,
        down = false,
        jump = false,
    }    
}
M.inputs_pressed = {
    -- p1
    {
        left = false,
        right = false,
        up = false,
        down = false,
        jump = false,
    },
    -- p2
    {
        left = false,
        right = false,
        up = false,
        down = false,
        jump = false,
    }
}
M.inputs = {
    p1 = {
        left = hash("p1_left"),
        right = hash("p1_right"),
        up = hash("p1_up"),
        down = hash("p1_down"),
        jump = hash("p1_jump"),
        reload = hash("reload"),
        fullscreen = hash("fullscreen"),
    },
    p2 = {
        left = hash("p2_left"),
        right = hash("p2_right"),
        up = hash("p2_up"),
        down = hash("p2_down"),
        jump = hash("p2_jump"),
    },
    gamepad = {
        s_left = hash("s_left"),
        s_right = hash("s_right"),
        s_up = hash("s_up"),
        s_down = hash("s_down"),
        dpad_left = hash("dpad_left"),
        dpad_right = hash("dpad_right"),
        dpad_up = hash("dpad_up"),
        dpad_down = hash("dpad_down"),
        gp_jump = hash("gp_jump"),
        gp_reload = hash("gp_reload")
    }
}
M.listener = {}

function M.ResetObjectList()
    M.currentlevelobjects = {}
end

function M.AddLevelObject(tiled_id, url)
    assert(M.currentlevelobjects[tiled_id] == nil, "Tried to track object with duplicate id " .. tiled_id)
    M.currentlevelobjects[tiled_id] = url
end

function M.TiledIdToUrl(id)
    local url = M.currentlevelobjects[id]
    assert(url, "failed to find defold url for tiled id: " .. id)
    local exists = go.exists(url)
    assert(exists, "tried to access object that no longer exists with tiled id: " .. id .. ", url: " .. url)
    return url
end

function M.prep_random_versus_level()
    local lvl
    local portal
    while lvl == nil or (lvl == M.currentlevel.level) do
        local rndm = math.random(1, 14)
        lvl = (rndm <= 7) and rndm or rndm-7
        portal = (rndm <= 7) and 1 or 2
    end
    M.currentlevel.chapter = 0
    M.currentlevel.portal = portal
    M.currentlevel.level = lvl
end

function M.portalstarted()
    _AMP_EVENTS.LEVEL_STARTED.properties.map_number = M.currentlevel.chapter
    _AMP_EVENTS.LEVEL_STARTED.properties.level_number = M.currentlevel.portal
    _AMP_EVENTS.LEVEL_STARTED.properties.attempts = 1
    -- Portal-level totals. Do not reset these on each sublevel load.
    _AMP_EVENTS.LEVEL_COMPLETED.properties.map_number = M.currentlevel.chapter
    _AMP_EVENTS.LEVEL_COMPLETED.properties.level_number = M.currentlevel.portal
    _AMP_EVENTS.LEVEL_COMPLETED.properties.attempts = 1
    _AMP_EVENTS.LEVEL_COMPLETED.properties.deaths = 0
    analytics_duration.start_level()
    savemanager.increment_total_portal_started()
	analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.LEVEL_STARTED)
end

function M.levelfinished(activator,next_level)
    msg.post("level:/inputs#inputs", "block_reload")
    local data
    local should_play_ad = false
    -- VERSUS MODE
    if M.is_versusmode then
        M.currentlevel.chapter = 0
        -- Load random VS mode level
        -- TODO: Save any level that has already been played in this session.
        if M.versus_score.p1 < 5 and M.versus_score.p2 < 5 then
            M.prep_random_versus_level()
            M.is_results_level = false
        else
            M.currentlevel.chapter = 0
            M.currentlevel.portal = 3
            M.currentlevel.level = (M.versus_score.p1 >= 5) and 1 or 2
            M.is_results_level = true
            savemanager.increment_total_versus_completed()
            analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.MULTILEVEL_COMPLETED)
        end
        analytics.track_tiktok_event(_TIKTOK_EVENTS.LEVEL_ACHIEVED)
        data = {collection_to_load = M.collections.level}
        msg.post(M.url_transition, "do_anim", data)
        return
    end
    
    local levelcount_in_portal = chapterinfo.levelamount_per_portal[M.currentlevel.chapter] and chapterinfo.levelamount_per_portal[M.currentlevel.chapter][M.currentlevel.portal] or 1

    -- Last level in chapter 1 should only go up to 6, then send you back if you have no keys
    local force_portal_completion = false
    if M.is_speedrunmode == true then
        if M.currentlevel.chapter == 1 and M.currentlevel.portal == 16 and M.currentlevel.level == 6 then
            force_portal_completion = true                        
        end
    end
    if M.currentlevel.chapter == 1 and M.currentlevel.portal == 16 and M.currentlevel.level == 7 then
        savemanager.set_secret_2(true)
    end

    if M.currentlevel.chapter == 1 and M.currentlevel.portal == 16 and M.currentlevel.level == 5 then
        achievements.achievement_unlock(achievements.IDs.first_ending)
    end

    if M.currentlevel.chapter == 2 and M.currentlevel.portal == 14 and M.currentlevel.level == 1 then
        achievements.achievement_unlock(achievements.IDs.second_ending)
    end

    if M.currentlevel.chapter == 3 and M.currentlevel.portal == 16 and M.currentlevel.level == 5 then
        achievements.achievement_unlock(achievements.IDs.third_ending)
    end

    local bonus_sublevel_id = level_select_info.current_sublevel and level_select_info.current_sublevel.portal_layout
    if savemanager.is_bonus_portal(M.currentlevel.portal) and bonus_sublevel_id then
        savemanager.set_currentlevel_portal_conquered(M.currentlevel, bonus_sublevel_id)
    end

    -- COMPLETED LEVEL    
    if M.currentlevel.level < levelcount_in_portal and force_portal_completion == false then

        -- Some levels must force conquered state on their portal
        for _, lvl in ipairs(early_conquer_levels) do
            if M.currentlevel.level == lvl.level and M.currentlevel.portal == lvl.portal and M.currentlevel.chapter == lvl.chapter then
                savemanager.set_portal_conquered(M.currentlevel.chapter, M.currentlevel.portal, true)
                if M.is_speedrunmode then
                    msg.post("speedrun:/gui#speedrun", "check_speedrun")
                end
                break
            end
        end

        -- Next level
        if savemanager.is_bonus_portal(M.currentlevel.portal) then
            msg.post(soundmanager.audioref, soundmanager.triggers.music_stop, {name = nil, fadetime = 0})
            data = {collection_to_load = M.collections.sublevels}
        else
            local new_currentlevel = {chapter = M.currentlevel.chapter, portal = M.currentlevel.portal, level = M.currentlevel.level + 1}
            data = {collection_to_load = M.collections.level, new_currentlevel = new_currentlevel}
        end

        if M.is_speedrunmode then
            msg.post(M.url_transition, "do_anim", data)
            return
        end
        
    -- COMPLETED PORTAL
    else        
        -- Speedrun Mode
        if M.is_speedrunmode then            
            -- Continuing speedrun mode                  
            if M.currentlevel.portal < chapterinfo.portal_count_by_chapter(M.currentlevel.chapter) then
                M.currentlevel.portal = M.currentlevel.portal + 1
                M.currentlevel.level = 1
                msg.post(M.url_transition, "do_anim", {collection_to_load = M.collections.level})
                return
            -- Completed speedrun mode
            else                                 
                local levelselect_to_load = M.collections["levelselect_c" .. M.currentlevel.chapter]  
                data = {collection_to_load = levelselect_to_load}
                msg.post(M.url_transition, "do_anim", {collection_to_load = levelselect_to_load})
                msg.post("speedrun:/gui#speedrun", "timer_stop")
                M.is_speedrunmode = false
                return
            end
        end

        -- Regular Play        
        should_play_ad = M.ad_variables.show_ad_at_end_of_portal and true or should_play_ad

        M.ad_variables.session_level_progression = M.ad_variables.session_level_progression + 1 
        M.ad_variables.interstitial_per_portal = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}

        msg.post(soundmanager.audioref, soundmanager.triggers.music_stop, {name = nil, fadetime = 0})
        local levelselect_to_load = M.collections["levelselect_c" .. M.currentlevel.chapter] or M.collections.levelselect_c1
        data = {collection_to_load = levelselect_to_load}
        if savemanager.is_bonus_portal(M.currentlevel.portal) == false and M.currentlevel.chapter ~= -1 then
            savemanager.set_currentlevel_portal_conquered(M.currentlevel, bonus_sublevel_id)
        end
        -- Analytics
        if M.currentlevel.portal <= 99 then
            savemanager.increment_total_portals_completed()
            _AMP_EVENTS.LEVEL_COMPLETED.properties.duration = analytics_duration.level_duration()
            analytics_duration.stop_level()
            analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.LEVEL_COMPLETED)
        end

        local AB_version = AB_test.get_version()

        if AB_version.version_name == AB_test.versions.A.version_name then
            if M.currentlevel.chapter == 1 and M.currentlevel.portal < 10 --[[M.currentlevel.chapter == 1 and (M.currentlevel.portal == 1 or M.currentlevel.portal == 2)]] then
                M.currentlevel.portal = M.currentlevel.portal + 1
                M.currentlevel.level = 1
                data = {collection_to_load = M.collections.level}
            end
        end

    end
    if next_level then
        msg.post(soundmanager.audioref, soundmanager.triggers.music_stop, {name = nil, fadetime = 0})
        data = {collection_to_load = next_level}
        if not savemanager.is_bonus_portal(M.currentlevel.portal) then
            savemanager.set_currentlevel_portal_conquered(M.currentlevel, bonus_sublevel_id)
        end
    end
    
    if M.currentlevel.chapter == 1 and M.currentlevel.portal == 0 and M.currentlevel.level == 1 then
        data = {collection_to_load = M.collections.levelselect}
    end   

    if M.currentlevel.chapter == -1 then -- Level editor chapter   
        local portal = M.currentlevel.portal
        if portal == -1 then
            M.level_editor_level_complete = true
            data = {collection_to_load = M.collections.level_editor}
        elseif portal == -2 then
            data = {collection_to_load = M.collections.level_browser}
        elseif portal == -3 then
            data = {collection_to_load = M.get_level_editor_saves_collection()}
        elseif portal == -4 then
            infinite_mode.increment_level_streak()
            infinite_mode.set_played(M.browser_share_level_code)
            msg.post("timer:/gui#timer", "timer_submit")
            _AMP_EVENTS.CUSTOMLEVEL_COMPLETED.properties.result = "win"
            analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.CUSTOMLEVEL_COMPLETED)
            analytics.track_tiktok_event(_TIKTOK_EVENTS.LEVEL_ACHIEVED)
            
            if activator then
                local level_name = infinite_mode.curated_level_list[M.browser_share_level_code].name
                infinite_mode.select_random_from_unplayed(function (random_entry)
                    if not random_entry then
                        data = {collection_to_load = M.collections.levelselect}
                        msg.post(M.url_transition, "do_anim", data)
                        return
                    end

                    monarch.show("RESULTS_PAGE",nil,{name = level_name, level_code = M.browser_share_level_code})
                    M.recieved_file = random_entry.level_string
                    M.browser_share_level_code = random_entry.id
                    M.browser_level_name = random_entry.name
                end)
                return
            else
                infinite_mode.select_random_from_unplayed(function (random_entry)
                    if not random_entry then
                        data = {collection_to_load = M.collections.levelselect}
                        msg.post(M.url_transition, "do_anim", data)
                        return
                    end
                    M.recieved_file = random_entry.level_string
                    M.browser_share_level_code = random_entry.id
                    M.browser_level_name = random_entry.name
                    data = {collection_to_load = M.collections.level}
                    msg.post(M.url_transition, "do_anim", data)
                end)
                return
            end
        end
    end

    if M.currentlevel.portal > 99 then -- Bonus portals, send back to sub levels
        data = {collection_to_load = M.collections.sublevels}
    end

    local had_interstitial_first_levels = false
    local had_interstitial_portal = false

    if _IS_ANDROID or _IS_IOS then
        if M.remote_parameters.use_timer_based_ads == 1 then
            should_play_ad = M.ad_variables.general_timer > M.remote_parameters.ad_timer_duration and true or should_play_ad
        else
            -- If enough time was spent one of the first levels, show an ad 
            should_play_ad = (M.ad_variables.level_timer > M.remote_parameters.seconds_spent_in_level and M.ad_variables.session_level_progression < M.remote_parameters.first_levels_in_session) and true or should_play_ad

            -- If you die X times in one of the first levels, show an ad
            should_play_ad = (M.ad_variables.level_death_counter > M.remote_parameters.death_max_first_levels and M.ad_variables.session_level_progression < M.remote_parameters.first_levels_in_session) and true or should_play_ad
            
            if M.currentlevel.level - 1 == M.remote_parameters.bonus_ad_target_level then --If in the first levels you recieved an ad and its now the bonus ad level, show an ad
                
                for i = 1, M.remote_parameters.bonus_ad_target_level do
                    had_interstitial_first_levels = M.ad_variables.interstitial_per_portal[i] > 0
                end
                should_play_ad = (had_interstitial_first_levels and not M.ad_variables.interstitial_per_portal[M.ad_variables.punishment_ad_checked_level] > 0) and true or should_play_ad
                
                for index, value in pairs(M.ad_variables.interstitial_per_portal) do
                    pprint(value)
                    if value > 0 then
                        had_interstitial_portal = true
                    end
                end
                should_play_ad = not had_interstitial_portal and true or should_play_ad --If there were no interstitials thus far, show one

            elseif M.currentlevel.level - 1 == M.ad_variables.punishment_ad_level_index then --If you had an ad in the checked level, play one in this level index (default is 5)
                should_play_ad = (M.ad_variables.interstitial_per_portal[M.ad_variables.punishment_ad_checked_level] > 0) and true or should_play_ad
            end

            if M.ad_variables.show_ad_override then --Ad override for everything (triggered by dying X times, defaulting to 5)
                should_play_ad = false
                M.ad_variables.show_ad_override = false
            end
        end

        if M.ad_variables.interstitial_ad_immunity > 0 then
            M.ad_variables.interstitial_ad_immunity = M.ad_variables.interstitial_ad_immunity - 1
            should_play_ad = false
        end
    end

    if should_play_ad and M.currentlevel.level <= 5 and not (M.currentlevel.chapter == -1 and M.currentlevel.portal == -1) then
        M.ad_variables.level_timer = 0
        M.ad_variables.general_timer = 0
        if M.currentlevel.chapter > 0 then
            M.ad_variables.interstitial_per_portal[M.currentlevel.level] = M.ad_variables.interstitial_per_portal[M.currentlevel.level] + 1
        end
        ads.popup_removads_threshold = M.remote_parameters.iap_banner_ad_threshold
        ads.show_ad(ads.ad.interstitial, function ()
            -- Remove Ads popup            
            local on_close = function ()
                msg.post(M.url_transition, "do_anim", data)
            end
            -- If there's no popup, on_close will run right away.
            if ads.check_popup_removeads(on_close) == true then
                msg.post("level:/collection0/gui#virtualbuttons", "do_disable")
                msg.post("main:/GUIs#pause", "pause_disable")
            else
                on_close()
            end
            ads.preload_ads()
        end, nil, "sublevel_complete")
    else
        msg.post(M.url_transition, "do_anim", data)
    end

    if M.currentlevel.level >= levelcount_in_portal then        
        M.ad_variables.interstitial_per_portal = {[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}
    end

    M.ad_variables.level_death_counter = 0
    M.ad_variables.level_death_interstitial_counter = 0    

    -- Analytics
    if not M.is_speedrunmode then

        -- Campaign
        if M.currentlevel.chapter > 0 then
            if M.currentlevel.portal <= 99 then
                savemanager.increment_total_levels_completed()
                _AMP_EVENTS.SUBLEVEL_COMPLETED.properties.result = "win"
                _AMP_EVENTS.SUBLEVEL_COMPLETED.properties.duration = analytics_duration.sublevel_duration()
                analytics_duration.stop_sublevel()
                analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.SUBLEVEL_COMPLETED)
            else
                -- Bonus level
                analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.PORTAL_LEVEL_COMPLETED)
            end
            analytics.track_tiktok_event(_TIKTOK_EVENTS.LEVEL_ACHIEVED)
        -- Custom levels
        elseif M.currentlevel.chapter == -1 then
            msg.post(soundmanager.audioref, soundmanager.triggers.music_stop, {name = nil, fadetime = 0})
            _AMP_EVENTS.CUSTOMLEVEL_COMPLETED.properties.result = "win"
            analytics.track_AMPLITUDE_EVENT(_AMP_EVENTS.CUSTOMLEVEL_COMPLETED)
            analytics.track_tiktok_event(_TIKTOK_EVENTS.LEVEL_ACHIEVED)
        end
    end
end

function M.reset_portal()
    M.currentlevel.level = 1
    local data = {collection_to_load = M.collections.level}
    msg.post(M.url_transition, "do_anim", data)
end

function M.DoesLevelExist(chapter,portal,level)
    local portal_string = string.format("%02d", portal)  -- Portal string leads with zeroes
    local filename = chapter.."-"..portal.."-"..level..".tmj"
    local path = "/tiled/common/levels/chapter-"..chapter..'/portal-'.. portal_string ..'/'..filename
    file = sys.load_resource(path)
    return file ~= nil
end

--(Un)subscribe--------
function M.subscribe(callback)
    assert(type(callback) == "function", "Listener must be a function")
	table.insert(M.listener, callback)
end
function M.unsubscribe(callback)
	for i, listener in ipairs(M.listener) do
		if listener == callback then
			table.remove(M.listener, i)
			break
		end
	end
end
----------------

--Collections---------
function M.set_current_collection(new_collection)
    current_collection = new_collection
    for _, callback in ipairs(M.listener) do
		callback(new_collection)
	end
end
function M.get_current_collection()
    return current_collection
end
function M.current_collection_is_gameplay()
    return M.get_current_collection() == M.collections.level
end
----------------

--Inputs----------
--Held inputs (continuous)
function M.set_input_left(newstate, hero_index)
    M.inputs_held[hero_index].left = newstate
end
function M.set_input_right(newstate, hero_index)
    M.inputs_held[hero_index].right = newstate
end
function M.set_input_up(newstate, hero_index)
    M.inputs_held[hero_index].up = newstate
end
function M.set_input_down(newstate, hero_index)
    M.inputs_held[hero_index].down = newstate
end
function M.set_input_jump(newstate, hero_index)
    M.inputs_held[hero_index].jump = newstate
end

-- Pressed inputs (1 frame)
function M.set_input_pressed_left(newstate, hero_index)
    M.inputs_pressed[hero_index].left = newstate
    M.check_for_first_input()
end
function M.set_input_pressed_right(newstate, hero_index)
    M.inputs_pressed[hero_index].right = newstate
    M.check_for_first_input()
end
function M.set_input_pressed_up(newstate, hero_index)
    M.inputs_pressed[hero_index].up = newstate
    M.check_for_first_input()
end
function M.set_input_pressed_down(newstate, hero_index)
    M.inputs_pressed[hero_index].down = newstate
    M.check_for_first_input()
end
function M.set_input_pressed_jump(newstate, hero_index)
    M.inputs_pressed[hero_index].jump = newstate
    M.check_for_first_input()
end

function M.reset_all_inputs(retain_first_input)

    for _, player in ipairs(M.inputs_held) do
        for k in pairs(player) do
            player[k] = false
        end
    end

    for _, player in ipairs(M.inputs_pressed) do
        for k in pairs(player) do
            player[k] = false
        end
    end

    -- Some instances shouldn't reset first input (such as pausing)
    if not retain_first_input then
        M.first_input = false
    end
end

function M.check_for_first_input()
    --pprint("First input: ", M.first_input)
    if not M.first_input then
        poki.gameplay_state_changed(M.poki_gameplay_states.START)
        M.first_input = true
    end
end
-------------------

function M.set_countdown_activity(new_state)
    M.is_countdown_active = new_state
end

--Cursor----------
function M.set_cursorpos(newpos)
    cursorpos = newpos
end
function M.get_cursorpos()
    return cursorpos
end
-------------------

function M.reset_versus_score()
    M.versus_score = {p1 = 0, p2 = 0}
end


--Utility------------

function M.get_foreground_color()
    return M.currentleveldata.foreground_color
end

--DEBUG--------------

--checks if debug mechanics are enabled for this build
---@return boolean
function M.get_debug_mechanics_enabled()
    return not M.DEBUG_bypass_debug_check;
end

function M.DEBUG_set_fastmode(new_value)
    if(new_value ~= M.DEBUG_fastmode_active) then
        M.DEBUG_fastmode_active = new_value;
        msg.post("transition:/GUI#transition", "DEBUG_fastmode", {newstate = M.DEBUG_fastmode_active})
    end
end

function M.DEBUG_toggle_fastmode()
    M.DEBUG_fastmode_active = not M.DEBUG_fastmode_active
    msg.post("transition:/GUI#transition", "DEBUG_fastmode", {newstate = M.DEBUG_fastmode_active})
end

return M