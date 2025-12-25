--// Obsidian UI Example – Executor Ready
--// Clean base you can extend safely

-- =========================
-- Load Library & Addons
-- =========================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- =========================
-- Create Window
-- =========================
local Window = Library:CreateWindow({
    Title = "Obsidian Example UI",
    Footer = "example build",
    Icon = "home",
    Center = true,
    AutoShow = true,
    NotifySide = "Right",
    EnableSidebarResize = true,
})

-- =========================
-- Tabs
-- =========================
local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

-- =========================
-- Main Tab Groupboxes
-- =========================
local MainLeft = Tabs.Main:AddLeftGroupbox("Main Features", "rocket")
local MainRight = Tabs.Main:AddRightGroupbox("Settings", "wrench")

-- =========================
-- UI Elements (Main)
-- =========================

-- Toggle
MainLeft:AddToggle("AutoFarm", {
    Text = "Enable Auto Farm",
    Default = false,
})

-- Slider
MainLeft:AddSlider("FarmSpeed", {
    Text = "Farm Speed",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
})

-- Dropdown
MainLeft:AddDropdown("FarmMode", {
    Text = "Farm Mode",
    Values = { "Safe", "Fast", "Insane" },
    Default = 1,
})

-- Button
MainRight:AddButton({
    Text = "Print Status",
    Func = function()
        print("AutoFarm:", Library.Toggles.AutoFarm.Value)
        print("Speed:", Library.Options.FarmSpeed.Value)
        print("Mode:", Library.Options.FarmMode.Value)
        Library:Notify("Status printed to console", 3)
    end
})

-- Divider
MainRight:AddDivider("Danger Zone")

-- Risky Button
MainRight:AddButton({
    Text = "Unload UI",
    Risky = true,
    Func = function()
        Library:Unload()
    end
})

-- =========================
-- Dependency Example
-- =========================
local DepBox = MainLeft:AddDependencyBox()

DepBox:AddSlider("AdvancedPower", {
    Text = "Advanced Power",
    Default = 10,
    Min = 1,
    Max = 50,
})

DepBox:SetupDependencies({
    { Library.Toggles.AutoFarm, true }
})

-- =========================
-- UI Settings Tab
-- =========================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/ExampleUI")

-- Ignore menu keybind if you add one later
SaveManager:SetIgnoreIndexes({})

-- Build UI
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Load defaults
ThemeManager:LoadDefault()
SaveManager:LoadAutoloadConfig()

-- =========================
-- Callbacks (after UI creation)
-- =========================
Library.Toggles.AutoFarm:OnChanged(function(state)
    print("AutoFarm toggled:", state)
end)

Library.Options.FarmSpeed:OnChanged(function(value)
    print("Farm speed:", value)
end)

Library.Options.FarmMode:OnChanged(function(value)
    print("Farm mode:", value)
end)

-- =========================
-- Ready
-- =========================
Library:Notify("UI Loaded Successfully", 4)
