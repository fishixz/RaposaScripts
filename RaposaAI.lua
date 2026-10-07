-- Raposa AI Writer
-- Standalone. As chaves são fornecidas pelo usuário em runtime e ficam somente em memória.
-- O script valida todas as chaves informadas, mas usa uma chave válida por sessão.
-- Em HTTP 429, respeita Retry-After quando disponível e tenta novamente com backoff.

local MODEL = "gemini-3.8-flash"
local MAX_HISTORY_ITEMS = 10
local DEFAULT_RETRY_SECONDS = 10
local MAX_RETRY_SECONDS = 60

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

local SYSTEM_PROMPT = table.concat({
    "Você é um assistente de escrita e respostas rápidas em português do Brasil.",
    "Seja objetivo, claro e útil. Por padrão responda em uma única mensagem curta, sem blocos longos ou vários parágrafos.",
    "Faça exatamente o que o usuário pedir e preserve o sentido do texto ao corrigir ou reformular.",
    "Se a pergunta depender de fatos atuais, notícias, política, pessoas públicas, datas, declarações ou informações da internet, use a Pesquisa Google disponível para verificar antes de responder.",
    "Quando citar uma fala atribuída a alguém, não invente: pesquise, deixe claro o contexto essencial e só use citação literal quando houver suporte.",
    "Evite introduções desnecessárias. Dê a resposta diretamente."
}, " ")

local function getRequest()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if typeof(http) == "table" and typeof(http.request) == "function" then return http.request end
    if typeof(syn) == "table" and typeof(syn.request) == "function" then return syn.request end
    error("Este ambiente não expõe uma função HTTP compatível.")
end

local function copyText(text)
    if typeof(setclipboard) == "function" then
        setclipboard(text)
        return true
    end
    if typeof(toclipboard) == "function" then
        toclipboard(text)
        return true
    end
    return false
end

local requestFn = getRequest()

local parent
if typeof(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and result then
        parent = result
    end
end
parent = parent or CoreGui

local old = parent:FindFirstChild("RaposaAI")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RaposaAI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local main = Instance.new("Frame")
main.Name = "Window"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(600, 500)
main.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
main.BorderSizePixel = 0
main.ClipsDescendants = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(54, 57, 67)
mainStroke.Thickness = 1
mainStroke.Parent = main

local top = Instance.new("Frame")
top.Name = "Topbar"
top.Size = UDim2.new(1, 0, 0, 56)
top.BackgroundTransparency = 1
top.Active = true
top.Parent = main

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 0)
title.Size = UDim2.new(1, -110, 1, 0)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 19
title.TextColor3 = Color3.fromRGB(245, 245, 248)
title.Text = "Raposa AI"
title.Parent = top

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0.5)
close.Position = UDim2.new(1, -14, 0.5, 0)
close.Size = UDim2.fromOffset(34, 34)
close.BackgroundColor3 = Color3.fromRGB(37, 39, 47)
close.BorderSizePixel = 0
close.Text = "×"
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(226, 226, 230)
close.Parent = top
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 9)

local toggle = Instance.new("TextButton")
toggle.Name = "ToggleBall"
toggle.AnchorPoint = Vector2.new(0, 0.5)
toggle.Size = UDim2.fromOffset(44, 44)
toggle.BackgroundColor3 = Color3.fromRGB(239, 111, 55)
toggle.BorderSizePixel = 0
toggle.Text = "R"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.Parent = gui
Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(255, 160, 112)
toggleStroke.Transparency = 0.25
toggleStroke.Parent = toggle

local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -6, 1, -6)
resizeHandle.Size = UDim2.fromOffset(26, 26)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = "↘"
resizeHandle.TextColor3 = Color3.fromRGB(130, 134, 145)
resizeHandle.TextSize = 18
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.ZIndex = 20
resizeHandle.Parent = main

local body = Instance.new("Frame")
body.Position = UDim2.fromOffset(12, 56)
body.Size = UDim2.new(1, -24, 1, -68)
body.BackgroundColor3 = Color3.fromRGB(23, 24, 29)
body.BorderSizePixel = 0
body.ClipsDescendants = true
body.Parent = main
Instance.new("UICorner", body).CornerRadius = UDim.new(0, 12)

local loadingPage = Instance.new("Frame")
loadingPage.Size = UDim2.fromScale(1, 1)
loadingPage.BackgroundTransparency = 1
loadingPage.Parent = body

local loadingTitle = Instance.new("TextLabel")
loadingTitle.AnchorPoint = Vector2.new(0.5, 0.5)
loadingTitle.Position = UDim2.fromScale(0.5, 0.45)
loadingTitle.Size = UDim2.new(1, -60, 0, 40)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "Carregando Raposa AI"
loadingTitle.TextColor3 = Color3.fromRGB(245, 245, 248)
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.TextSize = 23
loadingTitle.Parent = loadingPage

local loadingStatus = Instance.new("TextLabel")
loadingStatus.AnchorPoint = Vector2.new(0.5, 0.5)
loadingStatus.Position = UDim2.fromScale(0.5, 0.55)
loadingStatus.Size = UDim2.new(1, -60, 0, 28)
loadingStatus.BackgroundTransparency = 1
loadingStatus.Text = "Preparando interface..."
loadingStatus.TextColor3 = Color3.fromRGB(145, 149, 160)
loadingStatus.Font = Enum.Font.Gotham
loadingStatus.TextSize = 14
loadingStatus.Parent = loadingPage

local keyPage = Instance.new("Frame")
keyPage.Size = UDim2.fromScale(1, 1)
keyPage.BackgroundTransparency = 1
keyPage.Visible = false
keyPage.Parent = body

local keyTitle = Instance.new("TextLabel")
keyTitle.Position = UDim2.fromOffset(22, 18)
keyTitle.Size = UDim2.new(1, -44, 0, 32)
keyTitle.BackgroundTransparency = 1
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 20
keyTitle.TextColor3 = Color3.fromRGB(245, 245, 248)
keyTitle.Text = "Conectar ao Gemini"
keyTitle.Parent = keyPage

local keyHelp = Instance.new("TextLabel")
keyHelp.Position = UDim2.fromOffset(22, 52)
keyHelp.Size = UDim2.new(1, -44, 0, 42)
keyHelp.BackgroundTransparency = 1
keyHelp.TextXAlignment = Enum.TextXAlignment.Left
keyHelp.TextYAlignment = Enum.TextYAlignment.Top
keyHelp.TextWrapped = true
keyHelp.Font = Enum.Font.Gotham
keyHelp.TextSize = 13
keyHelp.TextColor3 = Color3.fromRGB(158, 162, 173)
keyHelp.Text = "Cole suas chaves do Gemini abaixo, uma por linha. Elas ficam somente na memória desta execução."
keyHelp.Parent = keyPage

local keyBox = Instance.new("TextBox")
keyBox.Position = UDim2.fromOffset(22, 102)
keyBox.Size = UDim2.new(1, -44, 1, -190)
keyBox.BackgroundColor3 = Color3.fromRGB(31, 33, 40)
keyBox.BorderSizePixel = 0
keyBox.ClearTextOnFocus = false
keyBox.MultiLine = true
keyBox.TextWrapped = false
keyBox.TextXAlignment = Enum.TextXAlignment.Left
keyBox.TextYAlignment = Enum.TextYAlignment.Top
keyBox.PlaceholderText = "AIza...\nAIza...\nAIza..."
keyBox.PlaceholderColor3 = Color3.fromRGB(105, 109, 120)
keyBox.TextColor3 = Color3.fromRGB(235, 235, 239)
keyBox.Font = Enum.Font.Code
keyBox.TextSize = 14
keyBox.Text = ""
keyBox.Parent = keyPage
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 10)

local keyPadding = Instance.new("UIPadding")
keyPadding.PaddingTop = UDim.new(0, 12)
keyPadding.PaddingBottom = UDim.new(0, 12)
keyPadding.PaddingLeft = UDim.new(0, 12)
keyPadding.PaddingRight = UDim.new(0, 12)
keyPadding.Parent = keyBox

local keyStatus = Instance.new("TextLabel")
keyStatus.Position = UDim2.new(0, 22, 1, -80)
keyStatus.Size = UDim2.new(1, -170, 0, 48)
keyStatus.BackgroundTransparency = 1
keyStatus.TextXAlignment = Enum.TextXAlignment.Left
keyStatus.TextWrapped = true
keyStatus.Font = Enum.Font.Gotham
keyStatus.TextSize = 12
keyStatus.TextColor3 = Color3.fromRGB(158, 162, 173)
keyStatus.Text = "Nenhuma chave verificada."
keyStatus.Parent = keyPage

local verify = Instance.new("TextButton")
verify.AnchorPoint = Vector2.new(1, 1)
verify.Position = UDim2.new(1, -22, 1, -24)
verify.Size = UDim2.fromOffset(132, 44)
verify.BackgroundColor3 = Color3.fromRGB(239, 111, 55)
verify.BorderSizePixel = 0
verify.Text = "Verificar"
verify.TextColor3 = Color3.new(1, 1, 1)
verify.Font = Enum.Font.GothamBold
verify.TextSize = 14
verify.Parent = keyPage
Instance.new("UICorner", verify).CornerRadius = UDim.new(0, 10)

local chatPage = Instance.new("Frame")
chatPage.Size = UDim2.fromScale(1, 1)
chatPage.BackgroundTransparency = 1
chatPage.Visible = false
chatPage.Parent = body

local messages = Instance.new("ScrollingFrame")
messages.Position = UDim2.fromOffset(12, 12)
messages.Size = UDim2.new(1, -24, 1, -94)
messages.BackgroundColor3 = Color3.fromRGB(27, 29, 35)
messages.BorderSizePixel = 0
messages.ScrollBarThickness = 4
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y
messages.CanvasSize = UDim2.new()
messages.Parent = chatPage
Instance.new("UICorner", messages).CornerRadius = UDim.new(0, 10)

local msgPadding = Instance.new("UIPadding")
msgPadding.PaddingTop = UDim.new(0, 12)
msgPadding.PaddingBottom = UDim.new(0, 12)
msgPadding.PaddingLeft = UDim.new(0, 12)
msgPadding.PaddingRight = UDim.new(0, 12)
msgPadding.Parent = messages

local msgLayout = Instance.new("UIListLayout")
msgLayout.Padding = UDim.new(0, 9)
msgLayout.SortOrder = Enum.SortOrder.LayoutOrder
msgLayout.Parent = messages

local input = Instance.new("TextBox")
input.Position = UDim2.new(0, 12, 1, -70)
input.Size = UDim2.new(1, -106, 0, 58)
input.BackgroundColor3 = Color3.fromRGB(31, 33, 40)
input.BorderSizePixel = 0
input.ClearTextOnFocus = false
input.MultiLine = true
input.TextWrapped = true
input.TextXAlignment = Enum.TextXAlignment.Left
input.TextYAlignment = Enum.TextYAlignment.Top
input.PlaceholderText = "Escreva sua mensagem..."
input.PlaceholderColor3 = Color3.fromRGB(110, 114, 125)
input.TextColor3 = Color3.fromRGB(239, 239, 242)
input.Font = Enum.Font.Gotham
input.TextSize = 14
input.Text = ""
input.Parent = chatPage
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingTop = UDim.new(0, 9)
inputPadding.PaddingBottom = UDim.new(0, 9)
inputPadding.PaddingLeft = UDim.new(0, 11)
inputPadding.PaddingRight = UDim.new(0, 11)
inputPadding.Parent = input

local send = Instance.new("TextButton")
send.AnchorPoint = Vector2.new(1, 1)
send.Position = UDim2.new(1, -12, 1, -12)
send.Size = UDim2.fromOffset(82, 58)
send.BackgroundColor3 = Color3.fromRGB(239, 111, 55)
send.BorderSizePixel = 0
send.Text = "Enviar"
send.TextColor3 = Color3.new(1, 1, 1)
send.Font = Enum.Font.GothamBold
send.TextSize = 14
send.Parent = chatPage
Instance.new("UICorner", send).CornerRadius = UDim.new(0, 10)

local activeKey = nil
local validKeys = {}
local history = {}
local busy = false
local hidden = false
local retryCount = 0

local function updateTogglePosition()
    local x = main.AbsolutePosition.X + main.AbsoluteSize.X + 10
    local y = main.AbsolutePosition.Y + (main.AbsoluteSize.Y / 2)

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

    x = math.clamp(x, 6, math.max(6, viewport.X - toggle.AbsoluteSize.X - 6))
    y = math.clamp(y, toggle.AbsoluteSize.Y / 2 + 6, viewport.Y - toggle.AbsoluteSize.Y / 2 - 6)

    toggle.Position = UDim2.fromOffset(x, y)
end

RunService.RenderStepped:Connect(function()
    if not hidden then
        updateTogglePosition()
    end
end)

local dragging = false
local dragStart
local startPos
local dragInput

top.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1
        or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inputObject.Position
        startPos = main.Position

        inputObject.Changed:Connect(function()
            if inputObject.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

top.InputChanged:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseMovement
        or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragInput = inputObject
    end
end)

UserInputService.InputChanged:Connect(function(inputObject)
    if dragging and inputObject == dragInput then
        local delta = inputObject.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local resizing = false
local resizeStart
local resizeSize

resizeHandle.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1
        or inputObject.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = inputObject.Position
        resizeSize = main.AbsoluteSize

        inputObject.Changed:Connect(function()
            if inputObject.UserInputState == Enum.UserInputState.End then
                resizing = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(inputObject)
    if not resizing then return end
    if inputObject.UserInputType ~= Enum.UserInputType.MouseMovement
        and inputObject.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = inputObject.Position - resizeStart
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

    local newWidth = math.clamp(resizeSize.X + delta.X, 420, math.max(420, viewport.X - 40))
    local newHeight = math.clamp(resizeSize.Y + delta.Y, 340, math.max(340, viewport.Y - 40))

    main.Size = UDim2.fromOffset(newWidth, newHeight)
end)

toggle.MouseButton1Click:Connect(function()
    hidden = not hidden
    if hidden then
        updateTogglePosition()
        main.Visible = false
        toggle.Text = "R"
    else
        main.Visible = true
        toggle.Text = "‹"
        updateTogglePosition()
    end
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local function scrollBottom()
    task.defer(function()
        task.wait()
        messages.CanvasPosition = Vector2.new(0, math.max(0, messages.AbsoluteCanvasSize.Y))
    end)
end

local function addBubble(text, isUser, isSystem)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.Parent = messages

    local bubble = Instance.new("Frame")
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(isSystem and 1 or 0.84, isSystem and 0 or -2, 0, 0)
    bubble.Position = isUser and UDim2.new(0.16, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    bubble.BackgroundColor3 = isSystem
        and Color3.fromRGB(39, 35, 30)
        or (isUser and Color3.fromRGB(57, 60, 70) or Color3.fromRGB(35, 37, 44))
    bubble.BorderSizePixel = 0
    bubble.Active = not isUser and not isSystem
    bubble.Parent = holder
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 11)

    local label = Instance.new("TextLabel")
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Size = UDim2.new(1, -22, 0, 0)
    label.Position = UDim2.fromOffset(11, 9)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = isSystem and Enum.Font.GothamMedium or Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = isSystem and Color3.fromRGB(224, 182, 142) or Color3.fromRGB(238, 238, 241)
    label.Text = text
    label.Active = false
    label.Parent = bubble

    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 18)
    pad.Parent = bubble

    if not isUser and not isSystem then
        local lastTap = 0
        bubble.InputBegan:Connect(function(inputObject)
            if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
                and inputObject.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local now = os.clock()
            if now - lastTap <= 0.38 then
                if copyText(text) then
                    local oldText = label.Text
                    label.Text = oldText .. "\n\n✓ Copiado"
                    task.delay(0.8, function()
                        if label and label.Parent then
                            label.Text = oldText
                        end
                    end)
                end
                lastTap = 0
            else
                lastTap = now
            end
        end)
    end

    scrollBottom()
    return holder
end

local function parseKeys(raw)
    local keys = {}
    local seen = {}

    for line in tostring(raw):gmatch("[^\r\n]+") do
        local key = line:match("^%s*(.-)%s*$")
        if key and key ~= "" and not seen[key] then
            seen[key] = true
            table.insert(keys, key)
        end
    end

    return keys
end

local function extractText(data)
    local output = {}

    for _, candidate in ipairs(data.candidates or {}) do
        local content = candidate.content
        if content and content.parts then
            for _, part in ipairs(content.parts) do
                if type(part.text) == "string" and part.text ~= "" then
                    table.insert(output, part.text)
                end
            end
        end
    end

    return table.concat(output, "\n"):match("^%s*(.-)%s*$") or ""
end

local function getStatus(response)
    return tonumber(response.StatusCode or response.Status or 0) or 0
end

local function getRetrySeconds(response, attempt)
    local headers = response.Headers or response.headers or {}
    local retryAfter = headers["Retry-After"]
        or headers["retry-after"]
        or headers["Retry-after"]

    local numeric = tonumber(retryAfter)
    if numeric and numeric > 0 then
        return math.clamp(math.ceil(numeric), 1, MAX_RETRY_SECONDS)
    end

    local body = tostring(response.Body or "")
    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if decodedOk and type(data) == "table" then
        local details = data.error and data.error.details
        if type(details) == "table" then
            for _, detail in ipairs(details) do
                local delay = detail.retryDelay
                if type(delay) == "string" then
                    local seconds = tonumber(delay:match("([%d%.]+)s"))
                    if seconds then
                        return math.clamp(math.ceil(seconds), 1, MAX_RETRY_SECONDS)
                    end
                end
            end
        end
    end

    return math.min(DEFAULT_RETRY_SECONDS * math.max(1, attempt), MAX_RETRY_SECONDS)
end

local function requestGemini(apiKey, userText, includeHistory, useSearch)
    local contents = {}

    if includeHistory then
        for _, item in ipairs(history) do
            table.insert(contents, {
                role = item.role,
                parts = {{text = item.text}}
            })
        end
    end

    table.insert(contents, {
        role = "user",
        parts = {{text = userText}}
    })

    local payload = {
        system_instruction = {
            parts = {{text = SYSTEM_PROMPT}}
        },
        contents = contents,
        generationConfig = {
            temperature = 0.45,
            maxOutputTokens = 420
        }
    }

    if useSearch then
        payload.tools = {
            {google_search = {}}
        }
    end

    return requestFn({
        Url = "https://generativelanguage.googleapis.com/v1beta/models/" .. MODEL .. ":generateContent",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["x-goog-api-key"] = apiKey
        },
        Body = HttpService:JSONEncode(payload)
    })
end

local function validateKey(apiKey)
    local ok, response = pcall(function()
        return requestGemini(apiKey, "Responda somente com OK.", false, false)
    end)

    if not ok then
        return false, "network"
    end

    local status = getStatus(response)

    if status >= 200 and status < 300 then
        return true, "valid"
    end

    if status == 429 then
        return false, "rate_limited"
    end

    if status == 400 or status == 401 or status == 403 then
        return false, "invalid"
    end

    return false, "error_" .. tostring(status)
end

local function openChat()
    keyPage.Visible = false
    chatPage.Visible = true
    title.Text = "Raposa AI • conectado"
    addBubble("Pronto. A IA está conectada. Dê dois cliques/toques em uma resposta para copiá-la.", false, true)
end

verify.MouseButton1Click:Connect(function()
    if busy then return end

    local keys = parseKeys(keyBox.Text)
    if #keys == 0 then
        keyStatus.Text = "Cole pelo menos uma chave, uma por linha."
        keyStatus.TextColor3 = Color3.fromRGB(225, 128, 128)
        return
    end

    busy = true
    verify.Text = "Verificando..."
    verify.AutoButtonColor = false
    validKeys = {}
    activeKey = nil

    local limited = 0
    local invalid = 0
    local errors = 0

    for index, key in ipairs(keys) do
        keyStatus.Text = ("Verificando chave %d de %d..."):format(index, #keys)

        local ok, reason = validateKey(key)
        if ok then
            table.insert(validKeys, key)
        elseif reason == "rate_limited" then
            limited = limited + 1
        elseif reason == "invalid" then
            invalid = invalid + 1
        else
            errors = errors + 1
        end
    end

    verify.Text = "Verificar"
    verify.AutoButtonColor = true
    busy = false

    if #validKeys > 0 then
        activeKey = validKeys[1]
        keyBox.Text = ""
        keyStatus.TextColor3 = Color3.fromRGB(132, 205, 150)
        keyStatus.Text = ("%d chave(s) válida(s). Conectando..."):format(#validKeys)
        task.wait(0.45)
        openChat()
        return
    end

    keyStatus.TextColor3 = Color3.fromRGB(225, 150, 120)

    if limited > 0 and invalid == 0 then
        keyStatus.Text = "As chaves responderam com limite de uso. Aguarde e verifique novamente."
    else
        keyStatus.Text = ("Nenhuma chave disponível. Inválidas: %d • limitadas: %d • outros erros: %d"):format(
            invalid,
            limited,
            errors
        )
    end
end)

local function askGemini(userText)
    if not activeKey then
        return nil, "Nenhuma chave ativa."
    end

    local attempt = 0

    while gui.Parent do
        attempt = attempt + 1

        local ok, response = pcall(function()
            return requestGemini(activeKey, userText, true, true)
        end)

        if not ok then
            return nil, "Falha de rede: " .. tostring(response)
        end

        local status = getStatus(response)

        if status >= 200 and status < 300 then
            retryCount = 0

            local decodeOk, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if not decodeOk then
                return nil, "A API retornou uma resposta inválida."
            end

            local text = extractText(data)
            if text == "" then
                return nil, "A IA não retornou texto."
            end

            table.insert(history, {role = "user", text = userText})
            table.insert(history, {role = "model", text = text})

            while #history > MAX_HISTORY_ITEMS do
                table.remove(history, 1)
            end

            return text
        end

        if status == 429 then
            retryCount = retryCount + 1
            local waitSeconds = getRetrySeconds(response, retryCount)

            addBubble(
                ("Limite de uso atingido. Aguarde %d segundo(s); vou tentar reconectar automaticamente."):format(waitSeconds),
                false,
                true
            )

            for remaining = waitSeconds, 1, -1 do
                if not gui.Parent then
                    return nil, "Interface encerrada."
                end
                send.Text = tostring(remaining) .. "s"
                task.wait(1)
            end

            send.Text = "..."
        elseif status == 400 or status == 401 or status == 403 then
            return nil, "A chave ativa foi recusada pela API. Volte e informe outra chave."
        else
            local detail = tostring(response.Body or "")
            if #detail > 220 then
                detail = detail:sub(1, 220) .. "..."
            end
            return nil, "Erro HTTP " .. tostring(status) .. ": " .. detail
        end
    end

    return nil, "Interface encerrada."
end

local function submit()
    if busy or not activeKey then return end

    local text = input.Text:match("^%s*(.-)%s*$")
    if not text or text == "" then return end

    busy = true
    input.Text = ""
    send.Text = "..."
    send.AutoButtonColor = false

    addBubble(text, true, false)

    task.spawn(function()
        local answer, err = askGemini(text)

        if answer then
            addBubble(answer, false, false)
        elseif err then
            addBubble("Erro: " .. tostring(err), false, true)
        end

        busy = false
        send.Text = "Enviar"
        send.AutoButtonColor = true
    end)
end

send.MouseButton1Click:Connect(submit)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        submit()
    end
end)

toggle.Text = "‹"
updateTogglePosition()

loadingStatus.Text = "Preparando janela..."
task.wait(0.35)
loadingStatus.Text = "Preparando conexão..."
task.wait(0.35)
loadingStatus.Text = "Pronto para receber suas chaves."
task.wait(0.45)

loadingPage.Visible = false
keyPage.Visible = true
