local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("AIWriterRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "RaposaAIWriter"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(520, 430)
main.Position = UDim2.new(0.5, -260, 0.5, -215)
main.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -32, 0, 44)
title.Position = UDim2.fromOffset(16, 10)
title.BackgroundTransparency = 1
title.Text = "Raposa AI Writer"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -32, 0, 125)
input.Position = UDim2.fromOffset(16, 62)
input.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
input.BorderSizePixel = 0
input.ClearTextOnFocus = false
input.MultiLine = true
input.TextWrapped = true
input.TextXAlignment = Enum.TextXAlignment.Left
input.TextYAlignment = Enum.TextYAlignment.Top
input.PlaceholderText = "Escreva seu texto aqui..."
input.PlaceholderColor3 = Color3.fromRGB(140, 140, 145)
input.TextColor3 = Color3.fromRGB(240, 240, 240)
input.Font = Enum.Font.Gotham
input.TextSize = 16
input.Text = ""
input.Parent = main

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 10)
inputCorner.Parent = input

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = input

local modes = {
    {"Melhorar", "improve"},
    {"Corrigir", "correct"},
    {"Continuar", "continue"},
    {"Encurtar", "shorten"},
}

local selectedMode = "improve"
local modeButtons = {}

local function updateButtons()
    for mode, button in pairs(modeButtons) do
        button.BackgroundColor3 = mode == selectedMode
            and Color3.fromRGB(245, 115, 45)
            or Color3.fromRGB(48, 48, 53)
    end
end

for index, item in ipairs(modes) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(112, 36)
    button.Position = UDim2.fromOffset(16 + ((index - 1) * 122), 200)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 53)
    button.BorderSizePixel = 0
    button.Text = item[1]
    button.TextColor3 = Color3.fromRGB(245, 245, 245)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.Parent = main

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    modeButtons[item[2]] = button

    button.MouseButton1Click:Connect(function()
        selectedMode = item[2]
        updateButtons()
    end)
end

updateButtons()

local send = Instance.new("TextButton")
send.Size = UDim2.new(1, -32, 0, 42)
send.Position = UDim2.fromOffset(16, 248)
send.BackgroundColor3 = Color3.fromRGB(245, 115, 45)
send.BorderSizePixel = 0
send.Text = "Gerar com IA"
send.TextColor3 = Color3.fromRGB(255, 255, 255)
send.Font = Enum.Font.GothamBold
send.TextSize = 16
send.Parent = main

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 10)
sendCorner.Parent = send

local output = Instance.new("TextBox")
output.Size = UDim2.new(1, -32, 0, 105)
output.Position = UDim2.fromOffset(16, 306)
output.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
output.BorderSizePixel = 0
output.ClearTextOnFocus = false
output.MultiLine = true
output.TextWrapped = true
output.TextEditable = false
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.PlaceholderText = "O resultado aparecerá aqui."
output.PlaceholderColor3 = Color3.fromRGB(125, 125, 130)
output.TextColor3 = Color3.fromRGB(240, 240, 240)
output.Font = Enum.Font.Gotham
output.TextSize = 15
output.Text = ""
output.Parent = main

local outputCorner = Instance.new("UICorner")
outputCorner.CornerRadius = UDim.new(0, 10)
outputCorner.Parent = output

local outputPadding = Instance.new("UIPadding")
outputPadding.PaddingTop = UDim.new(0, 10)
outputPadding.PaddingBottom = UDim.new(0, 10)
outputPadding.PaddingLeft = UDim.new(0, 10)
outputPadding.PaddingRight = UDim.new(0, 10)
outputPadding.Parent = output

local waiting = false

send.MouseButton1Click:Connect(function()
    if waiting then
        return
    end

    if input.Text:match("^%s*$") then
        output.Text = "Escreva alguma coisa primeiro."
        return
    end

    waiting = true
    send.Text = "Pensando..."
    send.AutoButtonColor = false

    Remote:FireServer({
        text = input.Text,
        mode = selectedMode,
    })
end)

Remote.OnClientEvent:Connect(function(payload)
    waiting = false
    send.Text = "Gerar com IA"
    send.AutoButtonColor = true

    if typeof(payload) ~= "table" then
        output.Text = "Resposta inválida."
        return
    end

    if payload.ok then
        output.Text = tostring(payload.result or "")
    else
        output.Text = tostring(payload.error or "Ocorreu um erro.")
    end
end)
