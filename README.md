# RaposaScripts

Base de um assistente de escrita com IA para Roblox Studio.

## Estrutura

- `src/client/WriterAssistant.client.lua` — interface do assistente.
- `src/server/AIWriter.server.lua` — valida pedidos e conversa com um backend HTTP.
- `src/server/AIWriterConfig.lua` — configuração do endpoint.

## Instalação no Roblox Studio

1. Crie um `RemoteEvent` em `ReplicatedStorage` chamado `AIWriterRequest`.
2. Coloque `WriterAssistant.client.lua` em `StarterPlayer > StarterPlayerScripts`.
3. Coloque `AIWriter.server.lua` em `ServerScriptService`.
4. Coloque `AIWriterConfig.lua` como ModuleScript em `ServerScriptService`.
5. Ative **Allow HTTP Requests** nas configurações do jogo.
6. Configure `BackendUrl` em `AIWriterConfig.lua`.

O backend deve aceitar POST JSON:

```json
{
  "text": "texto do jogador",
  "mode": "improve",
  "userId": 123,
  "username": "Player"
}
```

E responder:

```json
{
  "result": "texto retornado pela IA"
}
```

## Modos

- `improve` — melhorar o texto.
- `correct` — corrigir ortografia e gramática.
- `continue` — continuar o texto.
- `shorten` — deixar mais curto.

Nenhuma chave de API deve ficar no LocalScript.
