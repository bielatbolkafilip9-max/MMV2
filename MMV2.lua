-- ==========================================
-- OVERDRIVE H NATIVE PLUGIN (FULL VERSION)
-- ==========================================
local shared = odh_shared_plugins
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tworzenie zakładki pluginu w Overdrive H z Twoją ścieżką
local my_tab = shared.CreateTab("MMV Admin & Reset", "bielatbolkafilip9-max/MMV1/refs/heads/main/MMV2")

-- Funkcja bezpiecznego wysyłania komend na czacie
local function sendChatCommand(cmd)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(cmd) end
        else
            local sayMessageRequest = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") 
                and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            if sayMessageRequest then sayMessageRequest:FireServer(cmd, "All") end
        end
    end)
end

-- Detekcja końca rundy / lobby
local function isInLobbyOrEnded()
    local success, result = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                    local text = string.lower(gui.Text)
                    if text:find("intermission") or text:find("voting") or text:find("victory") or text:find("defeat") or text:find("round over") or text:find("waiting") then
                        return true
                    end
                end
            end
        end
        return false
    end)
    return success and result
end

----------------------------------------------------
-- SCREEN RESET BUTTON OVERLAY (UI)
----------------------------------------------------
local screenGui = CoreGui:FindFirstChild("MMV_ScreenResetGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MMV_ScreenResetGui"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
end

local screenResetBtn = Instance.new("TextButton")
screenResetBtn.Size = UDim2.new(0, 110, 0, 45)
screenResetBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
screenResetBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
screenResetBtn.Text = "💀 RESET"
screenResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
screenResetBtn.TextSize = 16
screenResetBtn.Font = Enum.Font.SourceSansBold
screenResetBtn.Active = true
screenResetBtn.Draggable = true
screenResetBtn.Visible = false
screenResetBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = screenResetBtn

screenResetBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
            shared.Notify("Character Reset!", 1.5)
        end
    end)
end)

----------------------------------------------------
-- SECTION 1: PLAYER ACTIONS (RESET OVERLAY)
----------------------------------------------------
local actions_section = my_tab:AddSection("Player Actions", "SCREEN OVERLAY & CONTROLS")

actions_section:AddToggle("Show Reset Button on Screen", function(state)
    screenResetBtn.Visible = state
    if state then
        shared.Notify("Reset Button Enabled!", 2)
    else
        shared.Notify("Reset Button Hidden!", 2)
    end
end)

actions_section:AddButton("💀 Reset Character Now", function()
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
            shared.Notify("Character Reset!", 2)
        end
    end)
end)

----------------------------------------------------
-- SECTION 2: ADMIN COMMANDS (MATCHING SCREENSHOTS)
----------------------------------------------------
local admin_section = my_tab:AddSection("Admin Commands", "MMV AUTO COMMANDS")

-- 1. Sheriff Options
local sheriffInput = LocalPlayer.Name
admin_section:AddTextBox("Sheriff Input", function(text)
    if text and text ~= "" then sheriffInput = text end
end)

local autoSheriff = false
admin_section:AddToggle("Auto Sheriff Input", function(state)
    autoSheriff = state
end)

-- 2. Murderer Options
local murdererInput = LocalPlayer.Name
admin_section:AddTextBox("Murderer Input", function(text)
    if text and text ~= "" then murdererInput = text end
end)

local autoMurderer = false
admin_section:AddToggle("Auto Murderer Input", function(state)
    autoMurderer = state
end)

-- 3. Map Options
local mapInput = "Milbase"
admin_section:AddTextBox("Map Input", function(text)
    if text and text ~= "" then mapInput = text end
end)

admin_section:AddButton("Set Map", function()
    if mapInput ~= "" then
        sendChatCommand("/map " .. mapInput)
        shared.Notify("Sent /map " .. mapInput, 2)
    end
end)

local autoMap = false
admin_section:AddToggle("Automatically Vote Map", function(state)
    autoMap = state
end)

----------------------------------------------------
-- AUTO COMMAND LOOP (RUNS ONCE EVERY NEW ROUND)
----------------------------------------------------
task.spawn(function()
    local sentThisRound = false
    while true do
        if isInLobbyOrEnded() then
            sentThisRound = false
        else
            if not sentThisRound then
                task.wait(1.5)
                
                if autoSheriff and sheriffInput ~= "" then
                    sendChatCommand("/sheriff " .. sheriffInput)
                    task.wait(0.5)
                end
                if autoMurderer and murdererInput ~= "" then
                    sendChatCommand("/murderer " .. murdererInput)
                    task.wait(0.5)
                end
                if autoMap and mapInput ~= "" then
                    sendChatCommand("/map " .. mapInput)
                end
                
                sentThisRound = true
            end
        end
        task.wait(1)
    end
end)
