--==================================================
-- GOONS — Obsidian Base (Step 2)
-- UI Elements Only (No Logic)
--==================================================
getgenv().SnipeLoop = getgenv().SnipeLoop or -1

local ScriptState = {
    Enabled = false,

    -- Pet Sniper (wiring)
    PetSniperEnabled = false,
    PetSniperSession = 0,

    -- autosave trigger (DO NOT REMOVE)
    ConfigTouch = false,
}


--==================================================
-- PET SNIPER STATUS HANDLER (OBSIDIAN SAFE)
--==================================================

local function SetSniperStatus(state)
    if not SniperStatusLabel then
        return
    end

    --====================================
    -- SNIPER DISABLED
    --====================================
    if not ScriptState.PetSniperEnabled then
        ScriptState.SniperRuntimeState = "OFF"

        SniperStatusLabel:SetText("Sniper: OFF")

        if HUDStateLabel then
            HUDStateLabel.Text = "State: OFF"
            HUDStateLabel.TextColor3 = Color3.fromRGB(170, 170, 170) -- neutral gray
        end

        return
    end

    --====================================
    -- NORMALIZED STATE
    --====================================
    ScriptState.SniperRuntimeState = state

    --====================================
    -- MAIN UI (OBSIDIAN)
    --====================================
    if state == "Idle" then
        SniperStatusLabel:SetText("Sniper: Idle")

    elseif state == "Scanning" then
        SniperStatusLabel:SetText("Sniper: Scanning")

    elseif state == "Teleporting" then
        SniperStatusLabel:SetText("Sniper: Teleporting")

    else
        state = "Idle"
        SniperStatusLabel:SetText("Sniper: Idle")
    end

    --====================================
    -- IN-GAME HUD (COLOR CONTROLLED HERE)
    --====================================
    if HUDStateLabel then
        HUDStateLabel.Text = "State: " .. state

        if state == "Idle" then
            HUDStateLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- WHITE

        elseif state == "Scanning" then
            HUDStateLabel.TextColor3 = Color3.fromRGB(34, 166, 242) -- blue / active

        elseif state == "Teleporting" then
            HUDStateLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- BRIGHT RED

        else
            HUDStateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end


--==================================================
-- FORWARD DECLARATIONS (OBSIDIAN SAFE)
--==================================================

local TryInitBoothData
local GetAllListings
local DoesListingMatchFilters

local function IsPetSniperSessionValid(session)
    return ScriptState.PetSniperEnabled and getgenv().SnipeLoop == session
end

local SniperMainLoop

SniperMainLoop = function(session)
    SetSniperStatus("Scanning")

    -- init booth data once
    if not TryInitBoothData() then
        SetSniperStatus("Idle")
        return
    end

    while IsPetSniperSessionValid(session) do
        local validListings = {}

        local listings = GetAllListings()
        for _, listing in ipairs(listings) do
            if DoesListingMatchFilters(listing) then
                table.insert(validListings, listing)
            end
        end

        -- nothing left in this server
        if #validListings == 0 then
            SetSniperStatus("Idle")
            break
        end

        -- pick cheapest listing
        table.sort(validListings, function(a, b)
            return (a.Price or math.huge) < (b.Price or math.huge)
        end)

        local target = validListings[1]
        if not target then
            SetSniperStatus("Idle")
            break
        end

        -- attempt buy
        local success = false
        local ok, err = pcall(function()
            success = ReplicatedStorage
                .GameEvents
                .TradeEvents
                .Booths
                .BuyListing
                :InvokeServer(target.Player, target.ListingId)
        end)

        if not ok or not success then
            -- buy failed → stop scanning this server
            SetSniperStatus("Idle")
            break
        end

        -- allow booth data to update
        task.wait(0.25)
    end
end

--==================================================
-- GAME IS LOADED
--==================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--==================================================
-- SETTINGS UI HELPERS
--==================================================

local function SetInstanceVisible(inst, visible)
    if not inst then return end
    if inst:IsA("GuiObject") then
        inst.Visible = visible
    end
end

local Players = game:GetService("Players")

local function GetSettingsInsertionPoint()
    local player = Players.LocalPlayer
    if not player then return nil end

    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return nil end

    local settingsUI = gui:FindFirstChild("SettingsUI")
    if not settingsUI then return nil end

    local settingsFrame = settingsUI:FindFirstChild("SettingsFrame")
    if not settingsFrame then return nil end

    local main = settingsFrame:FindFirstChild("Main")
    if not main then return nil end

    local holder = main:FindFirstChild("Holder")
    if not holder then return nil end

    return holder:FindFirstChild("SETTING_INSERTION_POINT")
end

local function FindSettingByText(searchText)
    if not searchText then return nil end

    local container = GetSettingsInsertionPoint()
    if not container then return nil end

    searchText = tostring(searchText):lower()

    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then
            -- Match by frame name
            if child.Name:lower():find(searchText) then
                return child
            end

            -- Match by visible text
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    if desc.Text and desc.Text:lower():find(searchText) then
                        return child
                    end
                end
            end
        end
    end
    return nil
end

ScriptState.PetHUDEnabled = false
ScriptState.ShowBaseWeight = true
ScriptState.ShowFruitNames = true
ScriptState.HUDHidden = false
ScriptState._HUDCache = {}

--==================================================
-- SNIPER HUD STATE (OBSIDIAN SAFE)
--==================================================

ScriptState.SniperHUDEnabled = false
ScriptState.SniperTeleportSeconds = nil
ScriptState.SniperRuntimeState = "Idle"
ScriptState.TeleportDelay = 60 -- seconds (user configurable)


--==================================================
-- LOAD OBSIDIAN
--==================================================

local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bencapalot041/goons/main/addons/SaveManager.lua"
))()

local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bencapalot041/goons/main/addons/ThemeManager.lua"
))()

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/bencapalot041/goons/main/Library.lua"
))()
--==================================================
-- WINDOW
--==================================================

local Window = Library:CreateWindow({
    Title = "Goons",
    Footer = "discord.gg/holygoons",
    Icon = "layers",

    Center = true,
    AutoShow = true,

    ToggleKeybind = Enum.KeyCode.LeftAlt,
})

--==================================================
-- FLOATING LEFT UI TOGGLE 
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "Goons_FloatingToggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.Parent = playerGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ToggleGui
ToggleButton.Size = UDim2.fromOffset(42, 42)
ToggleButton.Position = UDim2.new(0, 8, 0.5, -21) -- LEFT SIDE
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "≡"
ToggleButton.TextSize = 22
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.AutoButtonColor = true
ToggleButton.Active = true
ToggleButton.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = ToggleButton
local uiOpen = true

ToggleButton.MouseButton1Click:Connect(function()
    uiOpen = not uiOpen

    -- toggle Obsidian window
    Window:Toggle()

    -- safety: restore mouse
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end)
--==================================================
-- TABS
--==================================================

local MainTab = Window:AddTab("Main")
local PetSniperTab = Window:AddTab("Goon Sniper")
local TradeBoothTab = Window:AddTab("Trade Booth")
local VisualsTab = Window:AddTab("Visuals")
local SettingsTab = Window:AddTab("Settings")

--==================================================
-- IN-GAME SNIPER DEBUG HUD (TRANSPARENT)
--==================================================

local SniperHUDGui = Instance.new("ScreenGui")
SniperHUDGui.Name = "Goons_SniperHUD"
SniperHUDGui.ResetOnSpawn = false
SniperHUDGui.IgnoreGuiInset = true
SniperHUDGui.Enabled = false
SniperHUDGui.Parent = playerGui

local SniperHUDFrame = Instance.new("Frame")
SniperHUDFrame.Parent = SniperHUDGui
SniperHUDFrame.BackgroundTransparency = 1
SniperHUDFrame.Size = UDim2.fromOffset(320, 120)
SniperHUDFrame.Position = UDim2.fromScale(0.01, 0.25)

local HUDLayout = Instance.new("UIListLayout")
HUDLayout.Parent = SniperHUDFrame
HUDLayout.Padding = UDim.new(0, 6)

local function MakeHUDLabel(text, bold)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, bold and 30 or 26)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center

    lbl.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamBold
    lbl.TextSize = bold and 22 or 18

    
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)

    -- HEAVY OUTLINE FOR VISIBILITY
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(20, 0, 0)

    lbl.Text = text
    lbl.Parent = SniperHUDFrame
    return lbl
end



local HUDTitle = MakeHUDLabel("SNIPER", true)
HUDTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HUDTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
local HUDStateLabel = MakeHUDLabel("Status: Idle")
local HUDTeleportLabel = MakeHUDLabel("Teleport: ")
local HUDSessionLabel = MakeHUDLabel("Session: Inactive")

--==================================================
-- MAIN TAB
--==================================================

local MainControls = MainTab:AddLeftGroupbox("Test")
local StatusLabel = MainControls:AddLabel("Status: Idle")
local SniperStatusLabel = MainControls:AddLabel("Sniper: OFF")

MainControls:AddSlider("TeleportDelaySlider", {
    Text = "Teleport Delay (seconds)",
    Min = 5,
    Max = 300,
    Default = 60,
    Rounding = 0,
    Compact = false,
}):OnChanged(function(value)
    ScriptState.TeleportDelay = value
end)

MainControls:AddToggle("MasterEnable", {
    Text = "Enable Hatching",
    Default = false,
}):OnChanged(function(value)
    ScriptState.Enabled = value

    if StatusLabel then
        if value then
            StatusLabel:SetText("Status: Active")
        else
            StatusLabel:SetText("Status: Idle")
        end
    end

    print("[Goons] Script enabled:", value)
end)

--==================================================
-- TRADE WORLD TELEPORT (PROXIMITY PROMPT)
--==================================================

local function TeleportToTradeWorld()
    local interaction = workspace:FindFirstChild("Interaction")
    if not interaction then
        warn("[Teleport] Interaction not found")
        return
    end

    local platform = interaction:FindFirstChild("PermPortalPlatform")
    if not platform then
        warn("[Teleport] PermPortalPlatform not found")
        return
    end

    local attachment = platform:FindFirstChild("PortalAttachment")
    if not attachment then
        warn("[Teleport] PortalAttachment not found")
        return
    end

    local prompt = attachment:FindFirstChild("TradeWorldPrompt")
    if not prompt or not prompt:IsA("ProximityPrompt") then
        warn("[Teleport] TradeWorldPrompt not found")
        return
    end

    if fireproximityprompt then
        fireproximityprompt(prompt)
        print("[Teleport] Trade World prompt fired")
    else
        warn("[Teleport] fireproximityprompt not supported by executor")
    end
end
--==================================================
-- PET SNIPER SESSION GENERATOR (OBSIDIAN SAFE)
--==================================================

local function NewPetSniperSession()
    local session = os.clock()
    getgenv().SnipeLoop = session
    ScriptState.PetSniperSession = session
    return session
end
--==================================================
-- TELEPORT COUNTDOWN (OBSIDIAN SAFE)
--==================================================

local function StartTeleportCountdown(session, seconds)
    task.spawn(function()
        for i = seconds, 1, -1 do
            if not IsPetSniperSessionValid(session) then
                return
            end

            ScriptState.SniperTeleportSeconds = i
            SetSniperStatus("Teleporting")

            if SniperStatusLabel then
                SniperStatusLabel:SetText(
                    string.format("Sniper: Teleporting in %ds", i)
                )
            end

            if HUDTeleportLabel then
                HUDTeleportLabel.Text =
                    string.format("Teleport in: %ds (delay %ds)", i, seconds)
                HUDTeleportLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                HUDTeleportLabel.TextStrokeColor3 = Color3.fromRGB(60, 0, 0)
            end

            task.wait(1)
        end

        if IsPetSniperSessionValid(session) then
            ScriptState.SniperTeleportSeconds = nil

            if HUDTeleportLabel then
                HUDTeleportLabel.Text = "TELEPORTING NOW"
                HUDTeleportLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                HUDTeleportLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            end

            TeleportToTradeWorld()
        end
    end)
end



--==================================================
-- PET SNIPER TOGGLE
--==================================================

MainControls:AddToggle("EnablePetSniper", {
    Text = "Enable Goon Sniper",
    Default = false,
}):OnChanged(function(enabled)
    ScriptState.PetSniperEnabled = enabled

    if enabled then
        local session = NewPetSniperSession()

        -- HUD session state
        if HUDSessionLabel then
            HUDSessionLabel.Text = "Session: Active"
            HUDSessionLabel.TextColor3 = Color3.fromRGB(34, 242, 41)

        end

        SetSniperStatus("Idle")

        task.spawn(function()
            SniperMainLoop(session)
        end)

        StartTeleportCountdown(session, ScriptState.TeleportDelay or 60)

        print("[PetSniper] Enabled. Session:", session)
    else
        -- HUD reset
        if HUDSessionLabel then
            HUDSessionLabel.Text = "Session: Inactive"
            HUDSessionLabel.TextColor3 = Color3.fromRGB(170, 170, 170)

        end

        if HUDTeleportLabel then
            HUDTeleportLabel.Text = "Teleport: —"
        end

        getgenv().SnipeLoop = -1
        SetSniperStatus("OFF")

        print("[PetSniper] Disabled.")
    end
end)

--==================================================
-- EMERGENCY STOP BUTTON 
--==================================================
MainControls:AddButton({
    Text = "Emergency Stop",
    Func = function()
        print("Emergency stop pressed")
    end,
})
--==================================================
-- GOON SNIPER TAB (FILTER UI ONLY)
--==================================================

-- Persistent sniper filters
ScriptState.SniperFilters = ScriptState.SniperFilters or {}

local SniperControls = PetSniperTab:AddLeftGroupbox("Sniper")
local WatchlistBox = PetSniperTab:AddLeftGroupbox("Active Watchlist")
local WatchlistPageLabel = WatchlistBox:AddLabel("Page 1 / 1")
local WatchlistEntries = {}
local WatchlistEmptyLabel = WatchlistBox:AddLabel("• No active targets")
WatchlistEmptyLabel:SetVisible(false)


local SniperFiltersBox = PetSniperTab:AddRightGroupbox("Pet Filters")
local ManageFiltersBox = PetSniperTab:AddRightGroupbox("Manage Filters")
-- Status label mirror (read-only)
SniperControls:AddLabel("idk")

--==================================================
-- ACTIVE WATCHLIST (LEFT SIDE)
--==================================================

local function RefreshActiveWatchlist()
    -- Remove old dynamic labels
    for _, entry in ipairs(WatchlistEntries) do
        if entry and entry.Remove then
            entry:Remove()
        end
    end
    table.clear(WatchlistEntries)

    local count = 0

    -- Rebuild strictly from ScriptState.SniperFilters
    for petId, filter in pairs(ScriptState.SniperFilters) do
        count += 1

        local text = string.format(
            "• %s (%skg | %s)",
            petId:gsub("^%l", string.upper),
            tostring(filter.MinWeight or 0),
            filter.MaxPrice == math.huge and "∞" or ("$" .. tostring(filter.MaxPrice))
        )

        local label = WatchlistBox:AddLabel(text)
        table.insert(WatchlistEntries, label)
    end

    -- Empty state handling (ONE label only)
    WatchlistEmptyLabel:SetVisible(count == 0)

    WatchlistPageLabel:SetText("Page 1 / 1")
end

--==================================================
-- MANAGE FILTERS — SEARCHABLE DROPDOWN (OBSIDIAN SAFE)
--==================================================
local ManageFilterDropdown = ManageFiltersBox:AddDropdown("ManageFilterSelect", {
    Text = "Select Filter",
    Values = {},
    Default = "",
    Searchable = true,
})

local function RefreshManageFilterDropdown()
    local values = {}
    local displayToPetId = {}

    for petId, filter in pairs(ScriptState.SniperFilters) do
        local label = string.format(
            "%s | Min %s | Max %s",
            petId,
            tostring(filter.MinWeight or 0),
            filter.MaxPrice == math.huge and "∞" or tostring(filter.MaxPrice)
        )

        table.insert(values, label)
        displayToPetId[label] = petId
    end

    table.sort(values)

    ManageFilterDropdown:SetValues(values)
    ManageFilterDropdown:SetValue("")

    -- store mapping on the dropdown itself (safe)
    ManageFilterDropdown._displayToPetId = displayToPetId
end

---- Remove Selected
ManageFiltersBox:AddButton({
    Text = "Remove Selected",
    Func = function()
        local selectedLabel = ManageFilterDropdown.Value
        if not selectedLabel or selectedLabel == "" then
            warn("[ManageFilters] Nothing selected")
            return
        end

        local petId = ManageFilterDropdown._displayToPetId
            and ManageFilterDropdown._displayToPetId[selectedLabel]

        if not petId then
            warn("[ManageFilters] Invalid selection")
            return
        end

        -- THIS is the actual removal
        ScriptState.SniperFilters[petId] = nil

        -- FULL resync
        RefreshManageFilterDropdown()
        RefreshActiveWatchlist()
    end
})

-- Remove all filters
ManageFiltersBox:AddButton({
    Text = "Remove ALL Filters",
    Func = function()
        table.clear(ScriptState.SniperFilters)

        RefreshManageFilterDropdown()
        RefreshActiveWatchlist() -- ADDED

    end
})

-- Refresh dropdown manually
ManageFiltersBox:AddButton({
    Text = "Refresh List",
    Func = function()
        RefreshManageFilterDropdown()
    end
})
--==================================================
-- PET FILTERS — OBDISIAN-NATIVE SEARCHABLE DROPDOWN
--==================================================

local PetIds = {
    'lobster','rainbowlobster','kiwi','bloodkiwi','mimic','capybara','sloth','dilo','rainbowdilo',
    'peacock','cat','orangetabby','mooncat','pig','seaturtle','frog','echofrog','brontosaurus',
    'queenbee','starfish','spinosaurus','rainbowspinosaurus','kitsune','ckitsune','rainbowckitsune',
    'hyacinthmacaw','frenchfryferret','goldengoose','koi','seal','wasp','owl','nightowl','bloodowl',
    'cookedowl','butterfly','trex','mole','pancakemole','turtle','baconpig','triceratops','golem',
    'dragonfly','chickenzombie','raptor','redfox','meerkat','fennecfox','kappa','bunny','bagelbunny',
    'packbee','bearbee','sushibear','tarantulahawk','spriggan','discobee','baldeagle','rooster',
    'ostrich','gorillachef','raccoon','hotdog','rainbowhotdog','greenbean','ankylosaurus',
    'rainbowankylosaurus','lemonlion','applegazelle','peachwasp','iguanodon','rainbowiguanodon',
    'squirrel','dog','goldenlab','shibainu','parasaurolophus','rainbowparasaurolophus','snail',
    'tanuki','orangutan','pachycephalo','rainbowpachycephalo','flamingo','bee','honeybee','petalbee',
    'toucan','moth','crab','cockatrice','imp','pixie','pterodactyl','hamster','griffin',
    'rainbowgriffin','giantant','redgiantant','raiju','phoenix','rainbowphoenix','tanchozuru','wisp',
    'glimmeringsprite','seedling','sandsnake','drake','otter','luminoussprite','polarbear','robin',
    'giantrobin','greymouse','brownmouse','mochimouse','marmot','sugarglider','barnowl',
    'giantbarnowl','chipmunk','redsquirrel','spacesquirrel','swan','giantswan','grizzlybear',
    'giantgrizzlybear','scarletmacaw','shroomie','rainbowshroomie','gnome','ladybug','football',
    'deer','spotteddeer','elk','rainbowelk','panda','jackalope','badger','giantbadger',
    'silvermonkey','dairycow','prayingmantis','woodpecker','salmon','mallard','redpanda',
    'stegosaurus','hedgehog','bloodhedgehog','cardinal','hummingbird','treefrog','iguana',
    'chimpanzee','tiger','silverdragonfly','giantsilverdragonfly','firefly','giantfirefly',
    'mizuchi','rainbowmizuchi','hyrax','fortunesquirrel','chubbychipmunk','idolchipmunk',
    'farmerchipmunk','axolotl','chinchilla','rainbowchinchilla','bat','ghostlybat','bonedog',
    'ghostlybonedog','pumpkinrat','ghostbear','wolf','blackcat','ghostlyblackcat','reaper',
    'spider','ghostlyspider','headlesshorseman','ghostlyheadlesshorseman','darkspriggan',
    'ghostlydarkspriggan','goat','crow','goblin','hexserpent','scarab','ghostlyscarab','mummy',
    'ghostlymummy','lich','tombmarmot','ghostlytombmarmot','woody','glasscat','glassdog',
    'oxpecker','rainbowoxpecker','zebra','rainbowzebra','giraffe','rainbowgiraffe','rhino',
    'rainbowrhino','elephant','rainbowelephant','hydra','rainbowhydra','specter',
    'mantisshrimp','giantmantisshrimp'
}


local KnownWords = {
    "rainbow","blood","giant","golden","silver","ghostly","dark","light",
    "fire","ice","snow","frost","festive","hotdog","pancake"
}

local function FormatPetName(id)
    local name = id
    for _, w in ipairs(KnownWords) do
        name = name:gsub(w, w .. " ")
    end
    name = name:gsub("%s+", " "):match("^%s*(.-)%s*$")
    name = name:gsub("(%a)([%w_]*)", function(a,b)
        return a:upper() .. b
    end)
    return name
end

local DropdownValues = {}
local DisplayToId = {}

for _, id in ipairs(PetIds) do
    local display = FormatPetName(id)
    table.insert(DropdownValues, display)
    DisplayToId[display] = id
end

table.sort(DropdownValues)

local SelectedPetId = nil

local PetDropdown = SniperFiltersBox:AddDropdown("PetSelector", {
    Text = "Select Pet",
    Values = DropdownValues,
    Default = "",
    Searchable = true,
})


local MinWeightInput = SniperFiltersBox:AddInput("MinWeightInput", {
    Text = "Min Weight (kg)",
    Placeholder = "For Example 60",
})

local MaxTokensInput = SniperFiltersBox:AddInput("MaxTokensInput", {
    Text = "Max Tokens",
    Placeholder = "For Example 5000 Tokens",
})

SniperFiltersBox:AddButton({
    Text = "Add Filter",
    Func = function()
        local selectedName = PetDropdown.Value
        if not selectedName or selectedName == "" then
            warn("[SniperFilters] No pet selected")
            return
        end

        local petId = DisplayToId[selectedName]
        if not petId then
            warn("[SniperFilters] Invalid pet:", selectedName)
            return
        end

        ScriptState.SniperFilters[petId] = {
            MinWeight = tonumber(MinWeightInput.Value) or 0,
            MaxPrice = tonumber(MaxTokensInput.Value) or math.huge
        }
        RefreshActiveWatchlist()
        RefreshManageFilterDropdown()
        print("[SniperFilters] Added:", petId)
    end
})


--==================================================
-- VISUALS TAB
--==================================================

local PetHUD = VisualsTab:AddLeftGroupbox("Pet HUD / Info")
local GameVisuals = VisualsTab:AddRightGroupbox("Game Visuals")

PetHUD:AddToggle("SniperHUDEnabled", {
    Text = "Sniper Stats HUD",
    Default = false,
}):OnChanged(function(enabled)
    ScriptState.SniperHUDEnabled = enabled
    SniperHUDGui.Enabled = enabled
end)


PetHUD:AddToggle("ShowPetWeight", {
    Text = "Show BaseWeight",
    Default = true,
})

PetHUD:AddToggle("ShowFruitNames", {
    Text = "Fruit Names",
    Default = true,
})

PetHUD:AddToggle("RemoveWeather", {
    Text = "Remove Weather / Visuals",
    Default = false,
})

GameVisuals:AddButton({
    Text = "Toggle HUD Elements",
    Func = function()
        local player = Players.LocalPlayer
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return end

        -- List of HUD instances
        local targets = {
            gui:FindFirstChild("Hud_UI") and gui.Hud_UI:FindFirstChild("SideBtns") and gui.Hud_UI.SideBtns:FindFirstChild("Pass"),
            gui:FindFirstChild("Hud_UI") and gui.Hud_UI:FindFirstChild("SideBtns") and gui.Hud_UI.SideBtns:FindFirstChild("GardenGuide"),
            gui:FindFirstChild("Hud_UI") and gui.Hud_UI:FindFirstChild("SideBtns") and gui.Hud_UI.SideBtns:FindFirstChild("Trade"),
            gui:FindFirstChild("Hud_UI") and gui.Hud_UI:FindFirstChild("SideBtns") and gui.Hud_UI.SideBtns:FindFirstChild("Shop"),

            gui:FindFirstChild("Teleport_UI") and gui.Teleport_UI.Frame:FindFirstChild("Garden"),
            gui:FindFirstChild("Teleport_UI") and gui.Teleport_UI.Frame:FindFirstChild("Sell"),
            gui:FindFirstChild("Teleport_UI") and gui.Teleport_UI.Frame:FindFirstChild("Seeds"),

            gui:FindFirstChild("TopbarStandard")
                and gui.TopbarStandard.Holders
                and gui.TopbarStandard.Holders.Right
                and gui.TopbarStandard.Holders.Right:FindFirstChild("EVENT NOTIFY"),
        }

        ScriptState.HUDHidden = not ScriptState.HUDHidden

        for _, inst in ipairs(targets) do
            if inst then
                if ScriptState._HUDCache[inst] == nil then
                    ScriptState._HUDCache[inst] = inst.Visible
                end
                SetInstanceVisible(inst, not ScriptState.HUDHidden)
            end
        end

        print("[Visuals] HUD hidden:", ScriptState.HUDHidden)
    end,
})

--==================================================
-- SETTINGS TAB
--==================================================

local SettingsGeneral = SettingsTab:AddLeftGroupbox("General")
local SettingsUI = SettingsTab:AddRightGroupbox("UI")
local SettingsPerformance = SettingsTab:AddLeftGroupbox("Performance")

--==================================================
-- SETTINGS → DEV TOOLS
--==================================================

local DevTools = SettingsTab:AddRightGroupbox("Dev Tools")

DevTools:AddButton({
    Text = "Cobalt",
    Func = function()
        local success, err = pcall(function()
            loadstring(game:HttpGet(
                "https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"
            ))()
        end)

        if not success then
            warn("[DevTools] Cobalt failed to load:", err)
        end
    end,
})

DevTools:AddButton({
    Text = "Dex",
    Func = function()
        loadstring(game:HttpGet(
            "https://rawscripts.net/raw/Universal-Script-Keyless-dex-working-new-25658"
        ))()
    end,
})

MainControls:AddButton({
    Text = "Rejoin Server",
    Func = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId)
    end,
})

SettingsGeneral:AddToggle("AutoSave", {
    Text = "Auto Save Config",
    Default = true,
})

SettingsGeneral:AddButton({
    Text = "Reset Config",
    Func = function()
        print("Reset config pressed")
    end,
})

SettingsPerformance:AddToggle("PerformanceMode", {
    Text = "Performance Mode",
    Default = false,
})

SettingsPerformance:AddSlider("FPSLimit", {
    Text = "FPS Limit",
    Min = 30,
    Max = 240,
    Default = 60,
})

--==================================================
-- SAVE + THEME MANAGERS
--==================================================

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"SniperFilters"})

ThemeManager:SetFolder("Goons")
SaveManager:SetFolder("Goons")

SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)

--==================================================
-- FORCE INITIAL AUTOSAVE (ONE TIME)
--==================================================

task.defer(function()
    ScriptState.ConfigTouch = not ScriptState.ConfigTouch
end)

task.defer(RefreshManageFilterDropdown)
--==================================================
-- PET FILTER MATCH EVALUATION (READ-ONLY)
--==================================================

DoesListingMatchFilters = function(listing)
    if not listing or not ScriptState.SniperFilters then
        return false
    end

    local petName = listing.PetType or listing.PetName
    if not petName then
        return false
    end

    local filter = ScriptState.SniperFilters[petName]
    if not filter then
        return false
    end

    local petWeight = listing.PetMax or listing.Weight or 0
    local price = listing.Price or math.huge

    if petWeight < (filter.MinWeight or 0) then
        return false
    end

    if price > (filter.MaxPrice or math.huge) then
        return false
    end

    return true
end

--==================================================
-- PET SNIPER RUNTIME (OBSIDIAN SAFE)
--==================================================



local TradeController = require(
    ReplicatedStorage.Modules.TradeBoothControllers.TradeBoothController
)

TryInitBoothData = function()
    if getgenv().boothData then
        return true
    end

    local fn = TradeController.GetPlayerBoothData
    if type(fn) ~= "function" then
        return false
    end

    local upvalues = getupvalues(fn)
    if not upvalues or not upvalues[2] then
        return false
    end

    local dataService = upvalues[2]
    if type(dataService.GetDataAsync) ~= "function" then
        return false
    end

    local ok, data = pcall(function()
        return dataService:GetDataAsync()
    end)

    if ok and data then
        getgenv().boothData = data
        return true
    end

    return false
end

GetAllListings = function()
    local Data = getgenv().boothData
    if not Data or not Data.Booths then
        return {}
    end

    local Listings = {}

    for _, boothData in pairs(Data.Booths) do
        if boothData.Owner then
            local playerData = Data.Players and Data.Players[boothData.Owner]
            if playerData and playerData.Listings then
                for _, listing in pairs(playerData.Listings) do
                    if listing.ItemType == "Pet" then
                        table.insert(Listings, listing)
                    end
                end
            end
        end
    end

    return Listings
end
