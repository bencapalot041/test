Rayfield

--// Boot Rayfield Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "Goons Hub",
    Icon = "home",
    LoadingTitle = "Goons Hub",
    LoadingSubtitle = "Auto Booth System",
    ShowText = "Goons Hub",
    Theme = "DarkBlue",

    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GoonsHub",
        FileName = "AutoBoothConfig"
    },

    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },

    KeySystem = false
})

--// Tabs (Sidebar-equivalent)
local MainTab     = Window:CreateTab("Main", "home")
local ServerTab   = Window:CreateTab("Server", "server")
local WebhookTab  = Window:CreateTab("Webhook", "link")
local SettingsTab = Window:CreateTab("Settings", "settings")

--////////////////////////////////////////////////////
--// MAIN TAB
--////////////////////////////////////////////////////

MainTab:CreateSection("Auto Listing")

-- Pets To List (Multi-select dropdown)
local PetsDropdown = MainTab:CreateDropdown({
    Name = "Pets To List",
    Options = {
        "Mimic Octopus",
        "Koi",
        "Peacock",
        "Raccoon",
        "Kitsune"
    },
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "PetsToList",
    Callback = function(Options)
        Rayfield:Notify({
            Title = "Pets Updated",
            Content = "Selected pets updated.",
            Duration = 3,
            Image = "list"
        })
    end
})

-- Price Input
local PriceInput = MainTab:CreateInput({
    Name = "Price for Pet",
    CurrentValue = "",
    PlaceholderText = "Enter price",
    RemoveTextAfterFocusLost = false,
    Flag = "PetPrice",
    Callback = function(Text)
        Rayfield:Notify({
            Title = "Price Set",
            Content = "Price updated to: " .. Text,
            Duration = 3,
            Image = "dollar-sign"
        })
    end
})

MainTab:CreateDivider()

MainTab:CreateSection("KG Filter")

-- Min KG Input
local MinKG = MainTab:CreateInput({
    Name = "Minimum KG",
    CurrentValue = "",
    PlaceholderText = "Enter minimum KG",
    RemoveTextAfterFocusLost = false,
    Flag = "MinKG",
    Callback = function(Text)
        local value = tonumber(Text)
        if value then
            -- valid number
        else
            -- invalid input (non-number)
        end
    end
})

-- Max KG Input
local MaxKG = MainTab:CreateInput({
    Name = "Maximum KG",
    CurrentValue = "",
    PlaceholderText = "Enter maximum KG",
    RemoveTextAfterFocusLost = false,
    Flag = "MaxKG",
    Callback = function(Text)
        local value = tonumber(Text)
        if value then
            -- valid number
        else
            -- invalid input (non-number)
        end
    end
})

--////////////////////////////////////////////////////
--// SERVER TAB
--////////////////////////////////////////////////////

ServerTab:CreateSection("Server")

ServerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        Rayfield:Notify({
            Title = "Server",
            Content = "Rejoining server...",
            Duration = 3,
            Image = "refresh-cw"
        })
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

--////////////////////////////////////////////////////
--// WEBHOOK TAB
--////////////////////////////////////////////////////

WebhookTab:CreateSection("Webhook Settings")

local WebhookInput = WebhookTab:CreateInput({
    Name = "Webhook URL",
    CurrentValue = "",
    PlaceholderText = "Paste webhook here",
    RemoveTextAfterFocusLost = false,
    Flag = "WebhookURL",
    Callback = function(Text)
    end
})

--////////////////////////////////////////////////////
--// SETTINGS TAB
--////////////////////////////////////////////////////

SettingsTab:CreateSection("Interface")

SettingsTab:CreateToggle({
    Name = "UI Notifications",
    CurrentValue = true,
    Flag = "UINotifications",
    Callback = function(Value)
        Rayfield:Notify({
            Title = "Settings",
            Content = "Notifications " .. (Value and "Enabled" or "Disabled"),
            Duration = 3,
            Image = "bell"
        })
    end
})

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
    end
})

--////////////////////////////////////////////////////
--// LOAD CONFIGURATION (MUST BE LAST)
--////////////////////////////////////////////////////

Rayfield:LoadConfiguration()
