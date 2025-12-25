--// Boot Rayfield Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// Create Window
local Window = Rayfield:CreateWindow({
    Name = "Jay Hub",
    Icon = "home",
    LoadingTitle = "Jay Hub",
    LoadingSubtitle = "Auto Booth System",
    ShowText = "Jay Hub",
    Theme = "DarkBlue",

    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "JayHub",
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

-- Min KG Slider
local MinKG = MainTab:CreateSlider({
    Name = "Minimum KG",
    Range = {0, 100000},
    Increment = 1,
    Suffix = " KG",
    CurrentValue = 0,
    Flag = "MinKG",
    Callback = function(Value)
    end
})

-- Max KG Slider
local MaxKG = MainTab:CreateSlider({
    Name = "Maximum KG",
    Range = {0, 100000},
    Increment = 1,
    Suffix = " KG",
    CurrentValue = 0,
    Flag = "MaxKG",
    Callback = function(Value)
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
