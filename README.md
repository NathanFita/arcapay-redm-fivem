# ArcaPay - Script RedM / FiveM

Script de entrega automatica de produtos para servidores RedM e FiveM.

## Frameworks suportadas

- **VORP Core** (RedM)
- **RSG Core** (RedM)
- **RPX Core** (RedM)
- **QBCore** (FiveM)
- **ESX** (FiveM)
- **Standalone** (qualquer servidor)

A framework e detectada automaticamente.

## Instalacao

1. Baixe este repositorio e coloque na pasta `resources/` do seu servidor
2. Adicione `ensure arcapay` no `server.cfg`
3. Acesse o painel ArcaPay: **Integracoes > Scripts**
4. Gere um token e cole no `config.lua`
5. Reinicie o servidor

## Configuracao

Edite o `config.lua`:

```lua
Config.Token = "SEU_TOKEN_AQUI"
Config.ApiUrl = "https://arcapay.org/api/v1/fivem"
Config.PollInterval = 10000 -- 10 segundos
Config.Framework = "auto"   -- auto | vorp | rsg | rpx | qbcore | esx | standalone
Config.IdentifierType = "discord" -- steam | discord | license | charid | server_id
```

## Comandos suportados

Configure os comandos no produto dentro do painel ArcaPay.

### VORP
| Comando | Exemplo | Descricao |
|---------|---------|-----------|
| `addmoney` | `addmoney $discord 5000` | Adiciona dinheiro |
| `addmoney` | `addmoney $discord 100 gold` | Adiciona ouro |
| `giveitem` | `giveitem $discord bread 5` | Da item ao jogador |
| `giveweapon` | `giveweapon $discord WEAPON_REVOLVER_CATTLEMAN` | Da arma ao jogador |

### RSG
| Comando | Exemplo | Descricao |
|---------|---------|-----------|
| `addmoney` | `addmoney $discord 5000 cash` | Adiciona cash |
| `giveitem` | `giveitem $discord bread 5` | Da item ao jogador |

### QBCore
| Comando | Exemplo | Descricao |
|---------|---------|-----------|
| `addmoney` | `addmoney $discord 5000 cash` | Adiciona cash/bank/crypto |
| `giveitem` | `giveitem $discord weapon_pistol 1` | Da item ao jogador |

### ESX
| Comando | Exemplo | Descricao |
|---------|---------|-----------|
| `addmoney` | `addmoney $discord 5000 money` | Adiciona money/bank/black_money |
| `giveitem` | `giveitem $discord bread 5` | Da item ao jogador |

### Qualquer framework (console)
Qualquer comando que nao tenha handler especifico e executado como comando de console:
```
give.item {source} bread 5
```
Use `{source}` ou `{player}` para o server ID do jogador.

## Variaveis

As variaveis configuradas na loja (Integracoes > Variaveis) sao substituidas automaticamente:
- `$discord` → Discord ID do cliente
- `$steam` → Steam ID do cliente
- `{customer_name}` → Nome do cliente
- `{customer_email}` → Email do cliente
- `{order_id}` → ID do pedido
- `{product_name}` → Nome do produto
- `{quantity}` → Quantidade

## Comandos do servidor

| Comando | Descricao |
|---------|-----------|
| `arcapay_poll` | Forca polling manual |
| `arcapay_status` | Mostra status do script |

## Como funciona

1. Cliente compra na sua loja e preenche os dados (Discord ID, etc)
2. Ao pagar, o ArcaPay cria comandos pendentes
3. Este script faz polling a cada 10s buscando comandos pendentes
4. Executa o comando no servidor
5. Reporta o resultado pro ArcaPay

## Suporte

- Painel: [arcapay.org](https://arcapay.org)
- Discord: [discord.gg/atlanta](https://discord.gg/atlanta)
