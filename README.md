# RaposaScripts

Assistente de escrita com IA em um único script Lua.

## Arquivo principal

- `RaposaAI.lua`

O script cria:
- tela de carregamento;
- interface de chat;
- histórico curto de conversa;
- chamada direta à API Gemini;
- resposta dentro do chat;
- botão **Copiar** para copiar a resposta ao clipboard;
- tratamento básico de erros HTTP/API.

## Configuração

No início de `RaposaAI.lua`:

```lua
local GEMINI_API_KEY = "COLE_SUA_CHAVE_AQUI"
local MODEL = "gemini-3.8-flash"
```

Use apenas uma chave sua e autorizada. Não coloque chaves reais em commits, mesmo em repositórios privados.

O script não contém rotação de chaves para contornar quotas/rate limits.
