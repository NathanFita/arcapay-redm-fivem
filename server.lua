-- =============================================================================
-- ArcaPay Server Script - RedM / FiveM
-- Compativel com: VORP, RSG, RPX, QBCore, ESX, Standalone
-- =============================================================================

local API_URL = Config.ApiUrl
local TOKEN = Config.Token
local POLL_MS = Config.PollInterval or 10000
local FRAMEWORK = Config.Framework or "auto"

-- Framework references (lazy loaded)
local VORPcore, RSGcore, QBCore, ESX
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
    elseif GetResourceState("qb-core") == "started" then
        frameworkName = "qbcore"
    elseif GetResourceState("es_extended") == "started" then
        frameworkName = "esx"
    end

    print(("[ArcaPay] Framework detectada: %s"):format(frameworkName))
end

local function loadFramework()
    if frameworkName == "vorp" then
        TriggerEvent("getCore", function(core) VORPcore = core end)
    elseif frameworkName == "rsg" then
        RSGcore = exports["rsg-core"]:GetCoreObject()
    elseif frameworkName == "qbcore" then
        QBCore = exports["qb-core"]:GetCoreObject()
    elseif frameworkName == "esx" then
        ESX = exports["es_extended"]:getSharedObject()
    end
end

-- =============================================================================
-- PLAYER IDENTIFICATION
-- =============================================================================
local function getPlayerByIdentifier(idType, idValue)
    if not idValue or idValue == "" then return nil end

    idValue = tostring(idValue):gsub("%s+", "")

    -- Se for server_id direto
    if idType == "server_id" then
        local src = tonumber(idValue)
        if src and GetPlayerName(src) then return src end
        return nil
    end

    -- Busca por identifier
    local prefix = ({
        steam = "steam:",
        discord = "discord:",
        license = "license:",
        fivem = "fivem:",
        ip = "ip:",
    })[idType] or ""

    -- Se o valor ja tem o prefixo, usa direto
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

-- Extrai o identifier do comando (primeira palavra apos o comando)
local function parseCommand(cmdText)
    local parts = {}
    for word in cmdText:gmatch("%S+") do
        parts[#parts + 1] = word
    end
    return parts
end

-- =============================================================================
-- COMMAND HANDLERS
-- =============================================================================

local handlers = {}

-- ─── VORP ────────────────────────────────────────────────────────────────────

handlers.vorp = {
    -- addmoney <identifier> <amount> [type]
    -- type: money | gold | rol
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

    -- giveitem <identifier> <item> <amount>
    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src or not item then return false, "Jogador offline ou item invalido" end
        exports.vorp_inventory:addItem(src, item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,

    -- giveweapon <identifier> <weapon_hash>
    giveweapon = function(parts, src)
        local weapon = parts[3]
        if not src or not weapon then return false, "Jogador offline ou arma invalida" end
        exports.vorp_inventory:createWeapon(src, weapon, {})
        return true, ("Arma %s entregue"):format(weapon)
    end,
}

-- ─── RSG ─────────────────────────────────────────────────────────────────────

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
}

-- ─── QBCORE (FiveM) ─────────────────────────────────────────────────────────

handlers.qbcore = {
    addmoney = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        local moneyType = parts[4] or "cash"
        if not src then return false, "Jogador offline" end
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false, "Player nao encontrado" end
        player.Functions.AddMoney(moneyType, amount)
        return true, ("Adicionado %d %s"):format(amount, moneyType)
    end,

    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src then return false, "Jogador offline" end
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return false, "Player nao encontrado" end
        player.Functions.AddItem(item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,
}

-- ─── ESX (FiveM) ─────────────────────────────────────────────────────────────

handlers.esx = {
    addmoney = function(parts, src)
        local amount = tonumber(parts[3]) or 0
        local account = parts[4] or "money"
        if not src then return false, "Jogador offline" end
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false, "Player nao encontrado" end
        xPlayer.addAccountMoney(account, amount)
        return true, ("Adicionado %d %s"):format(amount, account)
    end,

    giveitem = function(parts, src)
        local item = parts[3]
        local amount = tonumber(parts[4]) or 1
        if not src then return false, "Jogador offline" end
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false, "Player nao encontrado" end
        xPlayer.addInventoryItem(item, amount)
        return true, ("Item %s x%d entregue"):format(item, amount)
    end,
}

-- ─── RPX (RedM) ──────────────────────────────────────────────────────────────

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

-- =============================================================================
-- EXECUTE COMMAND
-- =============================================================================
local function executeCommand(cmd)
    local text = cmd.command
    local parts = parseCommand(text)
    local action = parts[1] and parts[1]:lower() or ""
    local identifier = parts[2] or ""

    -- Encontra o jogador online pelo identifier
    local src = getPlayerByIdentifier(Config.IdentifierType, identifier)

    -- Tenta handler especifico da framework
    local fwHandlers = handlers[frameworkName]
    if fwHandlers and fwHandlers[action] then
        local ok, msg = fwHandlers[action](parts, src)
        return ok, msg
    end

    -- Fallback: executar como comando de console do servidor
    -- Substitui {source} pelo server id do jogador se estiver online
    if src then
        text = text:gsub("{source}", tostring(src))
        text = text:gsub("{player}", tostring(src))
    end

    ExecuteCommand(text)
    return true, "Comando executado via console: " .. text
end

-- =============================================================================
-- HTTP HELPERS
-- =============================================================================
local function apiRequest(method, endpoint, body, cb)
    local url = API_URL .. endpoint
    local headers = {
        ["Authorization"] = "Bearer " .. TOKEN,
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
    }

    PerformHttpRequest(url, function(status, response, resHeaders)
        if Config.Debug then
            print(("[ArcaPay] %s %s -> %d"):format(method, endpoint, status or 0))
        end

        if status == 200 or status == 201 then
            local data = json.decode(response) or {}
            cb(data, nil)
        else
            cb(nil, ("HTTP %d: %s"):format(status or 0, response or ""))
        end
    end, method, body and json.encode(body) or "", headers)
end

-- =============================================================================
-- POLLING LOOP
-- =============================================================================
local function pollCommands()
    apiRequest("GET", "/pending-commands", nil, function(commands, err)
        if err then
            if Config.Debug then print("[ArcaPay] Erro no polling: " .. err) end
            return
        end

        if not commands or #commands == 0 then return end

        print(("[ArcaPay] %d comando(s) pendente(s)"):format(#commands))

        for _, cmd in ipairs(commands) do
            local success, message = executeCommand(cmd)

            print(("[ArcaPay] CMD #%s [%s]: %s -> %s"):format(
                cmd.id, success and "OK" or "FAIL", cmd.command, message or ""
            ))

            -- Reporta resultado
            apiRequest("POST", "/report-command", {
                id = cmd.id,
                success = success,
                error = not success and message or nil,
                response = { message = message },
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

    print("[ArcaPay] Script iniciado! Polling a cada " .. (POLL_MS / 1000) .. "s")
    print("[ArcaPay] API: " .. API_URL)

    while true do
        Citizen.Wait(POLL_MS)
        pollCommands()
    end
end)

-- Comando manual pra testar
RegisterCommand("arcapay_poll", function(source)
    if source ~= 0 then return end -- Apenas console
    print("[ArcaPay] Polling manual...")
    pollCommands()
end, true)

RegisterCommand("arcapay_status", function(source)
    if source ~= 0 then return end
    print("[ArcaPay] Framework: " .. frameworkName)
    print("[ArcaPay] API URL: " .. API_URL)
    print("[ArcaPay] Token: " .. TOKEN:sub(1, 8) .. "...")
    print("[ArcaPay] Polling: " .. (POLL_MS / 1000) .. "s")
end, true)
