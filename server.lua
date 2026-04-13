-- =============================================================================
-- ArcaPay Server Script - RedM
-- Compativel com: VORP, RSG, RPX, DokusCore, Standalone
-- =============================================================================

local API_URL = Config.ApiUrl
local TOKEN = Config.Token
local POLL_MS = Config.PollInterval or 10000
local FRAMEWORK = Config.Framework or "auto"

local VORPcore, RSGcore
local frameworkName = "standalone"

-- =============================================================================
-- DETECT FRAMEWORK
-- =============================================================================
local function detectFramework()
    if FRAMEWORK ~= "auto" then
        frameworkName = FRAMEWORK
        return
    end
    if GetResourceState("vorp_core") == "started" then
        frameworkName = "vorp"
    elseif GetResourceState("rsg-core") == "started" then
        frameworkName = "rsg"
    elseif GetResourceState("rpx_core") == "started" then
        frameworkName = "rpx"
    elseif GetResourceState("dokuscore") == "started" then
        frameworkName = "dokus"
    end
    print(("[ArcaPay] Framework: %s"):format(frameworkName))
end

local function loadFramework()
    if frameworkName == "vorp" then
        TriggerEvent("getCore", function(core) VORPcore = core end)
    elseif frameworkName == "rsg" then
        RSGcore = exports["rsg-core"]:GetCoreObject()
    end
end

-- =============================================================================
-- PLAYER IDENTIFICATION
-- =============================================================================
local function getPlayerByIdentifier(idType, idValue)
    if not idValue or idValue == "" then return nil end
    idValue = tostring(idValue):gsub("%s+", "")

    if idType == "server_id" then
        local src = tonumber(idValue)
        if src and GetPlayerName(src) then return src end
        return nil
    end

    local prefix = ({
        steam = "steam:", discord = "discord:", license = "license:", fivem = "fivem:",
    })[idType] or ""

    local searchValue = idValue
    if prefix ~= "" and not idValue:find("^" .. prefix) then
        searchValue = prefix .. idValue
    end

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = GetPlayerIdentifier(src, i)
            if id and id:lower() == searchValue:lower() then
                return src
            end
        end
    end
    return nil
end

local function parseCommand(cmdText)
    local parts = {}
    for word in cmdText:gmatch("%S+") do parts[#parts + 1] = word end
    return parts
end

-- =============================================================================
-- COMMAND HANDLERS - REDM
-- =============================================================================

local handlers = {}

-- VORP Core
handlers.vorp = {
    addmoney = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        local currency = parts[4] or "money"
        if not src then return false, "Jogador offline" end
        local character = VORPcore.getUser(src).getUsedCharacter
        if not character then return false, "Personagem nao encontrado" end
        if currency == "gold" then
            character.addGold(amount)
        elseif currency == "rol" then
            character.addRol(amount)
        else
            character.addCurrency(0, amount)
        end
        return true, ("Adicionado %d %s"):format(amount, currency)
    end,
    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src or not item then return false, "Jogador offline ou item invalido" end
        exports.vorp_inventory:addItem(src, item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,
    giveweapon = function(parts, src)
        local weapon = parts[3]
        if not src or not weapon then return false, "Jogador offline ou arma invalida" end
        exports.vorp_inventory:createWeapon(src, weapon, {})
        return true, ("Arma %s entregue"):format(weapon)
    end,
    addxp = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        if not src then return false, "Jogador offline" end
        local character = VORPcore.getUser(src).getUsedCharacter
        if not character then return false, "Personagem nao encontrado" end
        character.addXp(amount)
        return true, ("XP +%d"):format(amount)
    end,
}

-- RSG Core
handlers.rsg = {
    addmoney = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        local currency = parts[4] or "cash"
        if not src then return false, "Jogador offline" end
        local player = RSGcore.Functions.GetPlayer(src)
        if not player then return false, "Player nao encontrado" end
        player.Functions.AddMoney(currency, amount)
        return true, ("Adicionado %d %s"):format(amount, currency)
    end,
    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src then return false, "Jogador offline" end
        local player = RSGcore.Functions.GetPlayer(src)
        if not player then return false, "Player nao encontrado" end
        player.Functions.AddItem(item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,
    giveweapon = function(parts, src)
        local weapon = parts[3]
        if not src then return false, "Jogador offline" end
        local player = RSGcore.Functions.GetPlayer(src)
        if not player then return false, "Player nao encontrado" end
        player.Functions.AddItem(weapon, 1)
        return true, ("Arma %s entregue"):format(weapon)
    end,
}

-- RPX Core
handlers.rpx = {
    addmoney = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        if not src then return false, "Jogador offline" end
        exports.rpx_core:AddMoney(src, amount)
        return true, ("Adicionado $%d"):format(amount)
    end,
    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src then return false, "Jogador offline" end
        exports.rpx_inventory:AddItem(src, item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,
}

-- DokusCore
handlers.dokus = {
    addmoney = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        if not src then return false, "Jogador offline" end
        exports.dokuscore:AddMoney(src, amount)
        return true, ("Adicionado $%d"):format(amount)
    end,
    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src then return false, "Jogador offline" end
        exports.dokuscore:AddItem(src, item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,
}

-- =============================================================================
-- EXECUTE COMMAND
-- =============================================================================
local function executeCommand(cmd)
    local text = cmd.command
    local parts = parseCommand(text)
    local action = parts[1] and parts[1]:lower() or ""
    local identifier = parts[2] or ""

    local src = getPlayerByIdentifier(Config.IdentifierType, identifier)

    local fwHandlers = handlers[frameworkName]
    if fwHandlers and fwHandlers[action] then
        return fwHandlers[action](parts, src)
    end

    -- Fallback: console command
    if src then
        text = text:gsub("{source}", tostring(src))
        text = text:gsub("{player}", tostring(src))
    end
    ExecuteCommand(text)
    return true, "Console: " .. text
end

-- =============================================================================
-- HTTP + POLLING
-- =============================================================================
local function apiRequest(method, endpoint, body, cb)
    PerformHttpRequest(API_URL .. endpoint, function(status, response, _)
        if Config.Debug then print(("[ArcaPay] %s %s -> %d"):format(method, endpoint, status or 0)) end
        if status == 200 or status == 201 then
            cb(json.decode(response) or {}, nil)
        else
            cb(nil, ("HTTP %d"):format(status or 0))
        end
    end, method, body and json.encode(body) or "", {
        ["Authorization"] = "Bearer " .. TOKEN,
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
    })
end

local function pollCommands()
    apiRequest("GET", "/pending-commands", nil, function(commands, err)
        if err or not commands or #commands == 0 then return end
        print(("[ArcaPay] %d comando(s) pendente(s)"):format(#commands))
        for _, cmd in ipairs(commands) do
            local ok, msg = executeCommand(cmd)
            print(("[ArcaPay] #%s [%s]: %s -> %s"):format(cmd.id, ok and "OK" or "FAIL", cmd.command, msg or ""))
            apiRequest("POST", "/report-command", {
                id = cmd.id, success = ok,
                error = not ok and msg or nil,
                response = { message = msg },
            }, function() end)
        end
    end)
end

-- =============================================================================
-- INIT
-- =============================================================================
Citizen.CreateThread(function()
    detectFramework()
    Citizen.Wait(2000)
    loadFramework()
    print("[ArcaPay] Iniciado! Polling a cada " .. (POLL_MS / 1000) .. "s")
    while true do
        Citizen.Wait(POLL_MS)
        pollCommands()
    end
end)

RegisterCommand("arcapay_poll", function(s) if s ~= 0 then return end pollCommands() end, true)
RegisterCommand("arcapay_status", function(s)
    if s ~= 0 then return end
    print("[ArcaPay] Framework: " .. frameworkName)
    print("[ArcaPay] API: " .. API_URL)
    print("[ArcaPay] Token: " .. TOKEN:sub(1, 8) .. "...")
end, true)
