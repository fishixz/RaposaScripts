local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService:WaitForChild("AIWriterConfig"))
local Remote = ReplicatedStorage:WaitForChild("AIWriterRequest")

local lastRequest = {}

local VALID_MODES = {
    improve = true,
    correct = true,
    continue = true,
    shorten = true,
}

local function reply(player, ok, value)
    Remote:FireClient(player, {
        ok = ok,
        result = ok and value or nil,
        error = ok and nil or value,
    })
end

Remote.OnServerEvent:Connect(function(player, payload)
    if typeof(payload) ~= "table" then
        return reply(player, false, "Pedido inválido.")
    end

    local text = tostring(payload.text or "")
    local mode = tostring(payload.mode or "improve")

    text = text:match("^%s*(.-)%s*$") or ""

    if text == "" then
        return reply(player, false, "Escreva alguma coisa primeiro.")
    end

    if #text > Config.MaxInputLength then
        return reply(player, false, ("O texto pode ter no máximo %d caracteres."):format(Config.MaxInputLength))
    end

    if not VALID_MODES[mode] then
        return reply(player, false, "Modo inválido.")
    end

    local now = os.clock()
    local previous = lastRequest[player.UserId] or 0

    if now - previous < Config.CooldownSeconds then
        return reply(player, false, "Espere alguns segundos antes de enviar novamente.")
    end

    lastRequest[player.UserId] = now

    if Config.BackendUrl:find("SEU%-BACKEND") then
        return reply(player, false, "Configure o BackendUrl no AIWriterConfig.")
    end

    local body = HttpService:JSONEncode({
        text = text,
        mode = mode,
        userId = player.UserId,
        username = player.Name,
    })

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = Config.BackendUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = body,
        })
    end)

    if not success then
        warn("[AIWriter] HTTP error:", response)
        return reply(player, false, "Não foi possível falar com a IA.")
    end

    if not response.Success then
        warn("[AIWriter] Backend status:", response.StatusCode, response.Body)
        return reply(player, false, "O serviço de IA respondeu com erro.")
    end

    local decodedSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodedSuccess or typeof(data) ~= "table" then
        return reply(player, false, "Resposta inválida do serviço de IA.")
    end

    local result = tostring(data.result or "")

    if result == "" then
        return reply(player, false, "A IA não retornou nenhum texto.")
    end

    reply(player, true, result)
end)

game.Players.PlayerRemoving:Connect(function(player)
    lastRequest[player.UserId] = nil
end)
