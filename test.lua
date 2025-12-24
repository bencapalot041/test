-- [6] OBSIDIAN UI (POST-AUTH, MOBILE + PC SAFE)
local function LoadSniperUI()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    local Options = Library.Options
    local Toggles = Library.Toggles

    local Window = Library:CreateWindow({
        Title = "GOON SNIPER",
        Footer = Version,
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    local Tabs = {
        Main = Window:AddTab("Main", "crosshair"),
        Filters = Window:AddTab("Filters", "list"),
        Safety = Window:AddTab("Safety", "shield"),
        Key = Window:AddKeyTab("Key System"),
        UI = Window:AddTab("UI Settings", "settings"),
    }

    -- =====================
    -- MAIN TAB
    -- =====================
    local MainBox = Tabs.Main:AddLeftGroupbox("Sniper Control")

    MainBox:AddToggle("SniperEnabled", {
        Text = "Enable Sniper",
        Default = getgenv().SniperEnabled,
        Callback = function(v)
            getgenv().SniperEnabled = v
            SaveConfig()
        end,
    })

    MainBox:AddButton("Force Server Hop", function()
        Hop()
    end)

    MainBox:AddLabel("Status: Controlled by sniper loop")

    -- =====================
    -- FILTERS TAB
    -- =====================
    local FilterBox = Tabs.Filters:AddLeftGroupbox("Pet Filters")

    FilterBox:AddDropdown("PetSelect", {
        Text = "Select Pets",
        Values = PetList,
        Multi = true,
        Searchable = true,
        Callback = function(tbl)
            for pet, enabled in pairs(tbl) do
                if enabled and not getgenv().CurrentFilters[pet] then
                    getgenv().CurrentFilters[pet] = {0, 9999999}
                elseif not enabled then
                    getgenv().CurrentFilters[pet] = nil
                end
            end
            SaveConfig()
        end,
    })

    FilterBox:AddInput("MinWeight", {
        Text = "Min Weight",
        Numeric = true,
        Callback = function(v)
            v = tonumber(v)
            if not v then return end
            for pet,_ in pairs(getgenv().CurrentFilters) do
                getgenv().CurrentFilters[pet][1] = v
            end
            SaveConfig()
        end,
    })

    FilterBox:AddInput("MaxPrice", {
        Text = "Max Price",
        Numeric = true,
        Callback = function(v)
            v = tonumber(v)
            if not v then return end
            for pet,_ in pairs(getgenv().CurrentFilters) do
                getgenv().CurrentFilters[pet][2] = v
            end
            SaveConfig()
        end,
    })

    -- =====================
    -- SAFETY TAB
    -- =====================
    local SafetyBox = Tabs.Safety:AddLeftGroupbox("Safety")

    SafetyBox:AddInput("Webhook", {
        Text = "Discord Webhook",
        Default = getgenv().WebhookURL,
        Callback = function(v)
            getgenv().WebhookURL = v
            SaveConfig()
        end,
    })

    SafetyBox:AddSlider("HopDelay", {
        Text = "Auto-Hop Delay",
        Min = 30,
        Max = 300,
        Default = getgenv().HopDelay or 60,
        Suffix = "s",
        Callback = function(v)
            getgenv().HopDelay = v
            SaveConfig()
        end,
    })

    -- =====================
    -- KEY TAB (REPLACES OLD KEY UI)
    -- =====================
    Tabs.Key:AddLabel({
        Text = "Enter your access key below",
        DoesWrap = true,
    })

    Tabs.Key:AddKeyBox(function(key)
        if ValidateKey(key) then
            if writefile then writefile(KeyFile, key) end
            Library:Notify({
                Title = "Access Granted",
                Description = "Key accepted",
                Time = 3,
            })
        else
            Library:Notify({
                Title = "Invalid Key",
                Description = "Key rejected",
                Time = 3,
            })
        end
    end)

    -- =====================
    -- UI SETTINGS
    -- =====================
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})

    ThemeManager:SetFolder("GoonSniper")
    SaveManager:SetFolder("GoonSniper/Configs")

    SaveManager:BuildConfigSection(Tabs.UI)
    ThemeManager:ApplyToTab(Tabs.UI)

    SaveManager:LoadAutoloadConfig()
end
