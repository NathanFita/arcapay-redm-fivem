Config = {}

-- =============================================================================
-- CONFIGURACAO PRINCIPAL
-- =============================================================================

-- Token gerado em: Integracoes > Scripts no painel ArcaPay
Config.Token = "SEU_TOKEN_AQUI"

-- URL da API (nao altere a menos que use dominio custom)
Config.ApiUrl = "https://arcapay.org/api/v1/fivem"

-- Intervalo de polling em ms (10000 = 10 segundos)
Config.PollInterval = 10000

-- Framework detectada automaticamente, ou force:
-- "auto" | "vorp" | "rsg" | "rpx" | "qbcore" | "esx" | "standalone"
Config.Framework = "auto"

-- =============================================================================
-- IDENTIFICACAO DO JOGADOR
-- As variaveis do checkout sao usadas pra encontrar o jogador online.
-- O script tenta identificar por: steam, discord, license, id do servidor
-- =============================================================================

-- Tipo de identificador usado nas variaveis da loja
-- "steam" | "discord" | "license" | "charid" | "server_id"
Config.IdentifierType = "discord"

-- =============================================================================
-- LOGS
-- =============================================================================
Config.Debug = false
