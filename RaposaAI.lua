-- Raposa AI Writer
-- Script standalone para uso no seu próprio jogo/ambiente.
-- Configure uma chave legítima do Gemini abaixo. Não publique a chave.

local GEMINI_API_KEY = "COLE_SUA_CHAVE_AQUI"
local MODEL = "gemini-3.8-flash"
local MAX_HISTORY = 8

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

local function getRequest()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
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
    if ok and result then parent = result end
end
parent = parent or CoreGui

local old = parent:FindFirstChild("RaposaAI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RaposaAI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local loading = Instance.new("Frame")
loading.Size = UDim2.fromScale(1, 1)
loading.BackgroundColor3 = Color3.fromRGB(12, 13, 16)
loading.Parent = gui

local loadTitle = Instance.new("TextLabel")
loadTitle.AnchorPoint = Vector2.new(.5, .5)
loadTitle.Position = UDim2.fromScale(.5, .46)
loadTitle.Size = UDim2.fromOffset(420, 44)
loadTitle.BackgroundTransparency = 1
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 28
loadTitle.TextColor3 = Color3.fromRGB(245, 245, 247)
loadTitle.Text = "Raposa AI"
loadTitle.Parent = loading

local loadStatus = Instance.new("TextLabel")
loadStatus.AnchorPoint = Vector2.new(.5, .5)
loadStatus.Position = UDim2.fromScale(.5, .53)
loadStatus.Size = UDim2.fromOffset(520, 30)
loadStatus.BackgroundTransparency = 1
loadStatus.Font = Enum.Font.Gotham
loadStatus.TextSize = 15
loadStatus.TextColor3 = Color3.fromRGB(150, 154, 165)
loadStatus.Text = "Inicializando..."
loadStatus.Parent = loading

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(.5, .5)
main.Position = UDim2.fromScale(.5, .5)
main.Size = UDim2.fromOffset(620, 520)
main.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(52, 55, 64)
stroke.Thickness = 1
stroke.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 58)
top.BackgroundTransparency = 1
top.Parent = main

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18, 0)
title.Size = UDim2.new(1, -100, 1, 0)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(245, 245, 247)
title.Text = "Raposa AI Writer"
title.Parent = top

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, .5)
close.Position = UDim2.new(1, -14, .5, 0)
close.Size = UDim2.fromOffset(34, 34)
close.BackgroundColor3 = Color3.fromRGB(36, 38, 45)
close.Text = "×"
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(220, 220, 225)
close.Parent = top
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 9)

local messages = Instance.new("ScrollingFrame")
messages.Position = UDim2.fromOffset(16, 58)
messages.Size = UDim2.new(1, -32, 1, -154)
messages.BackgroundColor3 = Color3.fromRGB(24, 25, 30)
messages.BorderSizePixel = 0
messages.ScrollBarThickness = 4
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y
messages.CanvasSize = UDim2.new()
messages.Parent = main
Instance.new("UICorner", messages).CornerRadius = UDim.new(0, 12)

local msgPadding = Instance.new("UIPadding")
msgPadding.PaddingTop = UDim.new(0, 12)
msgPadding.PaddingBottom = UDim.new(0, 12)
msgPadding.PaddingLeft = UDim.new(0, 12)
msgPadding.PaddingRight = UDim.new(0, 12)
msgPadding.Parent = messages

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = messages

local input = Instance.new("TextBox")
input.Position = UDim2.new(0, 16, 1, -82)
input.Size = UDim2.new(1, -112, 0, 58)
input.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
input.BorderSizePixel = 0
input.ClearTextOnFocus = false
input.MultiLine = true
input.TextWrapped = true
input.TextXAlignment = Enum.TextXAlignment.Left
input.TextYAlignment = Enum.TextYAlignment.Top
input.PlaceholderText = "Escreva algo para a IA..."
input.PlaceholderColor3 = Color3.fromRGB(120, 124, 136)
input.TextColor3 = Color3.fromRGB(240, 240, 243)
input.Font = Enum.Font.Gotham
input.TextSize = 15
input.Text = ""
input.Parent = main
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 12)

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingTop = UDim.new(0, 10)
inputPadding.PaddingBottom = UDim.new(0, 10)
inputPadding.PaddingLeft = UDim.new(0, 12)
inputPadding.PaddingRight = UDim.new(0, 12)
inputPadding.Parent = input

local send = Instance.new("TextButton")
send.AnchorPoint = Vector2.new(1, 0)
send.Position = UDim2.new(1, -16, 1, -82)
send.Size = UDim2.fromOffset(80, 58)
send.BackgroundColor3 = Color3.fromRGB(239, 111, 55)
send.Text = "Enviar"
send.TextColor3 = Color3.new(1,1,1)
send.Font = Enum.Font.GothamBold
send.TextSize = 14
send.Parent = main
Instance.new("UICorner", send).CornerRadius = UDim.new(0, 12)

local history = {}
local busy = false

local function addBubble(text, isUser, canCopy)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.Parent = messages

    local bubble = Instance.new("Frame")
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(.82, 0, 0, 0)
    bubble.Position = isUser and UDim2.new(.18,0,0,0) or UDim2.new(0,0,0,0)
    bubble.BackgroundColor3 = isUser and Color3.fromRGB(56, 58, 68) or Color3.fromRGB(31, 33, 40)
    bubble.BorderSizePixel = 0
    bubble.Parent = holder
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 12)

    local label = Instance.new("TextLabel")
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Size = UDim2.new(1, -24, 0, 0)
    label.Position = UDim2.fromOffset(12, 10)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(238, 238, 242)
    label.Text = text
    label.Parent = bubble

    local bottomPad = canCopy and 42 or 16
    local sizer = Instance.new("UIPadding")
    sizer.PaddingBottom = UDim.new(0, bottomPad)
    sizer.Parent = bubble

    if canCopy then
        local copy = Instance.new("TextButton")
        copy.AnchorPoint = Vector2.new(0, 1)
        copy.Position = UDim2.new(0, 12, 1, -8)
        copy.Size = UDim2.fromOffset(74, 26)
        copy.BackgroundColor3 = Color3.fromRGB(45, 48, 57)
        copy.Text = "Copiar"
        copy.TextColor3 = Color3.fromRGB(225,225,230)
        copy.Font = Enum.Font.GothamMedium
        copy.TextSize = 12
        copy.Parent = bubble
        Instance.new("UICorner", copy).CornerRadius = UDim.new(0, 7)

        copy.MouseButton1Click:Connect(function()
            if copyText(text) then
                copy.Text = "Copiado!"
                task.delay(1.2, function()
                    if copy and copy.Parent then copy.Text = "Copiar" end
                end)
            else
                copy.Text = "Indisponível"
            end
        end)
    end

    task.defer(function()
        messages.CanvasPosition = Vector2.new(0, math.max(0, messages.AbsoluteCanvasSize.Y))
    end)
end

local function extractText(data)
    local out = {}
    for _, candidate in ipairs(data.candidates or {}) do
        local content = candidate.content
        if content and content.parts then
            for _, part in ipairs(content.parts) do
                if part.text then table.insert(out, part.text) end
            end
        end
    end
    return table.concat(out, "\n")
end

local function askGemini(userText)
    if GEMINI_API_KEY == "" or GEMINI_API_KEY == "COLE_SUA_CHAVE_AQUI" then
        return nil, "Configure GEMINI_API_KEY no início do script."
    end

    local contents = {}
    for _, item in ipairs(history) do
        table.insert(contents, {
            role = item.role,
            parts = {{text = item.text}}
        })
    end
    table.insert(contents, {
        role = "user",
        parts = {{text = userText}}
    })

    local body = HttpService:JSONEncode({
        systemInstruction = {
            parts = {{
                text = "Você é um assistente de escrita. Ajude a escrever, corrigir, reformular, continuar ou melhorar textos. Responda de forma natural em português do Brasil, salvo quando o usuário pedir outro idioma. Não acrescente explicações desnecessárias quando o usuário só quiser o texto final."
            }}
        },
        contents = contents,
        generationConfig = {
            temperature = 0.7,
            maxOutputTokens = 1200
        }
    })

    local ok, response = pcall(function()
        return requestFn({
            Url = "https://generativelanguage.googleapis.com/v1beta/models/" .. MODEL .. ":generateContent",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-goog-api-key"] = GEMINI_API_KEY
            },
            Body = body
        })
    end)

    if not ok then
        return nil, "Falha HTTP: " .. tostring(response)
    end

    local status = response.StatusCode or response.Status or 0
    if status < 200 or status >= 300 then
        local detail = tostring(response.Body or "")
        if #detail > 240 then detail = detail:sub(1, 240) .. "..." end
        return nil, "Gemini respondeu HTTP " .. tostring(status) .. ": " .. detail
    end

    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if not decodedOk then
        return nil, "Resposta inválida da API."
    end

    local text = extractText(data)
    if text == "" then
        return nil, "A API não retornou texto."
    end

    table.insert(history, {role = "user", text = userText})
    table.insert(history, {role = "model", text = text})
    while #history > MAX_HISTORY do
        table.remove(history, 1)
    end

    return text
end

local function submit()
    if busy then return end
    local text = input.Text:match("^%s*(.-)%s*$")
    if not text or text == "" then return end

    busy = true
    input.Text = ""
    send.Text = "..."
    addBubble(text, true, false)

    task.spawn(function()
        local answer, err = askGemini(text)
        if answer then
            addBubble(answer, false, true)
        else
            addBubble("Erro: " .. tostring(err), false, false)
        end
        busy = false
        send.Text = "Enviar"
    end)
end

send.MouseButton1Click:Connect(submit)
input.FocusLost:Connect(function(enterPressed)
    if enterPressed and not input:IsFocused() then
        submit()
    end
end)
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

loadStatus.Text = "Preparando interface..."
task.wait(.45)
loadStatus.Text = "Conectando ao Gemini..."
task.wait(.45)

if GEMINI_API_KEY == "" or GEMINI_API_KEY == "COLE_SUA_CHAVE_AQUI" then
    loadStatus.Text = "Interface pronta — configure sua chave Gemini no script."
else
    loadStatus.Text = "Pronto."
end

task.wait(.55)
main.Visible = true
TweenService:Create(loading, TweenInfo.new(.25), {BackgroundTransparency = 1}):Play()
for _, child in ipairs(loading:GetChildren()) do
    if child:IsA("TextLabel") then
        TweenService:Create(child, TweenInfo.new(.2), {TextTransparency = 1}):Play()
    end
end
task.wait(.28)
loading:Destroy()

addBubble("Olá! Escreva um texto e eu posso ajudar a melhorar, corrigir, continuar ou reformular.", false, false)
