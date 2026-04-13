# ArcaPay - Script RedM

Script de entrega automatica de produtos para servidores **RedM**.

## Frameworks suportadas

- **VORP Core** (addmoney, giveitem, giveweapon, addxp)
- **RSG Core** (addmoney, giveitem, giveweapon)
- **RPX Core** (addmoney, giveitem)
- **DokusCore** (addmoney, giveitem)
- **Standalone** (executa via console)

A framework e detectada automaticamente.

## Instalacao

1. Baixe e coloque na pasta `resources/`
2. `ensure arcapay` no `server.cfg`
3. Gere um token em **Integracoes > Scripts** no painel ArcaPay
4. Cole no `config.lua`
5. Reinicie o servidor

## Configuracao (`config.lua`)

```lua
Config.Token = "SEU_TOKEN_AQUI"
Config.Framework = "auto"           -- auto | vorp | rsg | rpx | dokus | standalone
Config.IdentifierType = "discord"   -- steam | discord | license | charid | server_id
Config.PollInterval = 10000         -- ms
```

## Comandos por framework

### VORP
```
addmoney $discord 5000          -- dinheiro
addmoney $discord 100 gold      -- ouro
addmoney $discord 50 rol        -- rol
giveitem $discord bread 5       -- item
giveweapon $discord WEAPON_REVOLVER_CATTLEMAN
addxp $discord 500              -- experiencia
```

### RSG
```
addmoney $discord 5000 cash
giveitem $discord bread 5
giveweapon $discord WEAPON_REVOLVER_CATTLEMAN
```

### RPX / DokusCore
```
addmoney $discord 5000
giveitem $discord bread 5
```

### Console (qualquer framework)
```
give.item {source} bread 5
```

## Comandos do servidor
- `arcapay_poll` — polling manual
- `arcapay_status` — mostra status

## Suporte
- [arcapay.org](https://arcapay.org)
- [discord.gg/atlanta](https://discord.gg/atlanta)
