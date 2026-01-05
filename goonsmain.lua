--==================================================
-- GOONS — Obsidian Clean Base
-- Purpose: Minimal, stable foundation
--==================================================

--==================================================
-- BOOTSTRAP [1]
--==================================================
local ExecutorName = "unknown"

if identifyexecutor then
    ExecutorName = identifyexecutor():lower()
end

local IS_DELTA    = ExecutorName:find("delta") ~= nil
local IS_SELIWARE = ExecutorName:find("seli") ~= nil

local function ExecLog(msg)
    print(string.format("[GOONS | %s] %s", ExecutorName, msg))
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--==================================================
-- GLOBAL EXECUTION GATE (MANDATORY)
--==================================================

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer

    -- Player containers
    player:WaitForChild("PlayerGui")
    player:WaitForChild("Backpack")

    -- Replicated structure
    ReplicatedStorage:WaitForChild("Modules")
    ReplicatedStorage.Modules:WaitForChild("TradeBoothControllers")
    ReplicatedStorage.Modules.TradeBoothControllers:WaitForChild("TradeBoothController")

    -- World container
    while not workspace:FindFirstChild("TradeWorld") do
        task.wait(0.1)
    end

    -- small stabilization buffer
    task.wait(0.3)
end

--==================================================
-- HARD CLIENT HYDRATION BARRIER (MANDATORY)
--==================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- wait for character + humanoid
local function WaitForCharacter()
    if LocalPlayer.Character then
        return
    end
    LocalPlayer.CharacterAdded:Wait()
end

WaitForCharacter()

local character = LocalPlayer.Character
character:WaitForChild("Humanoid")

-- wait for backpack + at least one tool
local backpack = LocalPlayer:WaitForChild("Backpack")

local function WaitForFirstPet(timeout)
    local start = os.clock()
    while os.clock() - start < timeout do
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                return true
            end
        end
        task.wait(0.1)
    end
    return false
end

if not WaitForFirstPet(20) then
    warn("[GOONS] Backpack tools not ready after 20s")
end

-- PRELOAD PET NAMES FOR DROPDOWN (MANDATORY)
local InitialPetValues = {"None"}

do
    local backpack = LocalPlayer:WaitForChild("Backpack")
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(InitialPetValues, tool.Name)
        end
    end
    table.sort(InitialPetValues)
end


--==================================================
-- LOAD OBSIDIAN CORE [2]
--==================================================

local repo = "https://raw.githubusercontent.com/bencapalot041/goons/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

--==================================================
-- WINDOW SETUP [4]
--==================================================

local Window = Library:CreateWindow({
    Title = "GOONS",
    Footer = "discord.gg/holygoons",
    Icon = "layers",
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.LeftAlt,
})

--==================================================
-- TABS
--==================================================

local MainTab        = Window:AddTab("Main")
local SniperTab      = Window:AddTab("Sniper")
local TradeWorldTab  = Window:AddTab("Trade World")
local VisualsTab     = Window:AddTab("Visuals")
local SettingsTab    = Window:AddTab("Settings")

--==================================================
-- TRADE WORLD → AUTOMATION (UI ONLY, NO LOGIC)
--==================================================

-- Left side: Automation controls
local TradeAutomationGroup = TradeWorldTab:AddLeftGroupbox("Automation")

--==================================================
-- TRADE WORLD → STATUS DASHBOARD (READ ONLY)
--==================================================

local TradeStatusGroup = TradeWorldTab:AddLeftGroupbox("Trade World Status")

local TotalBoothsLabel   = TradeStatusGroup:AddLabel("Total Booths: -")
local FreeBoothsLabel    = TradeStatusGroup:AddLabel("Free Booths: -")
local TakenBoothsLabel   = TradeStatusGroup:AddLabel("Occupied Booths: -")
local YourBoothLabel     = TradeStatusGroup:AddLabel("Your Booth: -")

-- Persisted toggle (SaveManager will handle this automatically)
local AutoClaimBoothToggle = TradeAutomationGroup:AddToggle("AutoClaimBooth", {
    Text = "Auto Claim Booth",
    Default = false,

    Tooltip = "Automatically claims the first available booth when enabled.\nRequires a booth skin to be selected first.",
})
-- Persisted toggle: Auto Booth Position
local AutoBoothPositionToggle = TradeAutomationGroup:AddToggle("AutoBoothPosition", {
    Text = "Auto Booth Position",
    Default = false,
    Tooltip = "Automatically teleports you to your claimed booth.",
})

-- Right side: Booth customization
local BoothCustomizationGroup = TradeWorldTab:AddRightGroupbox("Booth Customization")

-- Persisted dropdown (values will be populated later)
local BoothSkinDropdown = BoothCustomizationGroup:AddDropdown("BoothSkinSelect", {
    Text = "Select Booth Skin",
    Values = {Default}, -- Must be a real value
    Default = "",
    Searchable = true,
})

-- Persisted dropdown: Hold Pet
local HoldPetDropdown = BoothCustomizationGroup:AddDropdown("HoldPetSelect", {
    Text = "Auto Hold Pet",
    Values = InitialPetValues,
    Default = "None",
    Searchable = true,
})


local BoothDistanceSlider = BoothCustomizationGroup:AddSlider("BoothDistance", {
    Text = "Booth Distance",
    Default = 12,
    Min = 4,
    Max = 26,
    Rounding = 0,
    Suffix = " studs",
    Tooltip = "How far behind the booth you stand",
})

--==================================================
-- HOLD PET → CONNECTION STATE (ANTI-DUPLICATE)
--==================================================

local HoldPetChangedConnection = nil
local AutoHoldChangedConnection = nil
local LastSelectedPet = "None"
local LastEquippedPet = nil
local HoldPetHydrated = false
local HoldPetRestoring = false
local PendingBoothTeleport = false

--==================================================
-- AUTO SAVE PET SELECT
--==================================================
local function TryRestoreHeldPet()
    local opt = Library.Options.HoldPetSelect
    if not opt or not opt.Value or opt.Value == "None" then
        return
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return
    end

    local tool = backpack:FindFirstChild(opt.Value)
    if not tool then
        return -- tool not ready yet
    end

    -- prevent duplicate equip
    if LastEquippedPet == opt.Value then
        return
    end

    LastSelectedPet = opt.Value
    task.defer(function()
    HoldSelectedPet()
end)
end

local function RestoreHoldPetUI()
    local opt = Library.Options.HoldPetSelect
    if not opt or not opt.Value or opt.Value == "None" then
        return
    end

    -- ensure dropdown knows this value exists
    local values = HoldPetDropdown.Values or {}
    if not table.find(values, opt.Value) then
        table.insert(values, opt.Value)
        HoldPetDropdown:SetValues(values)
    end

    HoldPetDropdown:SetValue(opt.Value)
    LastSelectedPet = opt.Value

    -- equip once UI is synced
    task.defer(TryRestoreHeldPet)
end

--==================================================
-- STATIC BOOTH SKINS (UI ONLY)
--==================================================

local ALL_BOOTH_SKINS = {
    "Default",
    "Wood",
    "Stone",
    "Ice",
    "Candy",
    "Gold",
    "Neon",
    "Dark",
    "Light",
    "Autumn",
    "Winter",
    "Spring",
    "Summer",
    "Galaxy",
    "Lava",
    "Ocean",
    "Forest",
    "Desert",
    "Crimson",
    "Royal",
}

table.sort(ALL_BOOTH_SKINS)

BoothSkinDropdown:SetValues(ALL_BOOTH_SKINS)
BoothSkinDropdown:SetValue("Default")

--==================================================
-- TRADE WORLD → MANUAL CLAIM (PHASE 3, SAFE)
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--==================================================
-- TRADE BOOTH CONTROLLER (AUTHORITATIVE, UI PATH)
--==================================================

local TradeBoothController = require(
    ReplicatedStorage
        .Modules
        .TradeBoothControllers
        .TradeBoothController
)


--==================================================
-- GOONS LOGGER (CLEAN CONSOLE OUTPUT)
--==================================================

local LOG_ENABLED = true

local function Log(scope, message)
    if not LOG_ENABLED then
        return
    end

    print(string.format(
        "[GOONS | %s] %s",
        scope,
        message
    ))
end

local function Warn(scope, message)
    warn(string.format(
        "[GOONS | %s] %s",
        scope,
        message
    ))
end

--==================================================
-- TRADE WORLD → BOOTH & PET STATE
--==================================================

local BoothState = {
    AutoPosition = false,
    HasTeleported = false,

    Distance = 12,
    BehindDir = nil,
    BoothCF = nil,
    HalfDepth = nil,
}

--==================================================
-- PET INVENTORY SCAN (BACKPACK)
--==================================================

local function GetBackpackPets()
    local pets = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return pets
    end

    for _, item in ipairs(backpack:GetChildren()) do
        table.insert(pets, item.Name)
    end

    table.sort(pets)
    return pets
end

--==================================================
-- HOLD PET → TOOL EQUIP (AUTHORITATIVE, SINGLE)
--==================================================
local function HoldSelectedPet()
    local opt = Library.Options.HoldPetSelect
    
    local petName = opt.Value
if not petName or petName == "None" then
    return
end

-- 🔒 debounce
if petName == LastEquippedPet then
    return
    end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    -- 🔒 UNEQUIP ALL TOOLS FIRST (prevents multi-pet bug)
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = backpack
        end
    end

    -- 🔍 FIND SELECTED PET TOOL
    local petTool = backpack:FindFirstChild(petName)
    if not petTool or not petTool:IsA("Tool") then
        Warn("HoldPet", "Pet tool not found: " .. petName)
        return
    end

    -- ✅ EQUIP EXACTLY ONE PET
    humanoid:EquipTool(petTool)
    LastEquippedPet = petName
    Log("HoldPet", "Equipped pet: " .. petName)
end


local function RefreshHoldPetDropdown()
    if HoldPetRestoring then
        return
    end

    local values = GetBackpackPets()
    table.insert(values, 1, "None")

    HoldPetDropdown:SetValues(values)
end




local function HookBackpack()
    local backpack = LocalPlayer:WaitForChild("Backpack")

    -- Initial fill (delayed, safe)
    task.delay(0.2, RefreshHoldPetDropdown)

    backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        task.wait()
        RefreshHoldPetDropdown()
        TryRestoreHeldPet()
    end
end)


    backpack.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            task.wait()
            RefreshHoldPetDropdown()
        end
    end)
end

local function OnCharacterAdded()
    LastEquippedPet = nil
    HookBackpack()
end

if LocalPlayer.Character then
    OnCharacterAdded()
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

HoldPetDropdown:OnChanged(function()
    local pet = HoldPetDropdown.Value or "None"

    LastSelectedPet = pet
    HoldSelectedPet()

    -- 🔒 force SaveManager persistence
    SaveManager:Save()
end)
--==================================================
-- BOOTH ID RESOLUTION (AUTHORITATIVE)
--==================================================

local function GetMyBoothId()
    local data = getgenv().boothData
    if not data or not data.Booths then
        return nil
    end

    local uid = tostring(LocalPlayer.UserId)

    for boothId, booth in pairs(data.Booths) do
        if booth.Owner and string.find(booth.Owner, uid) then
            return boothId
        end
    end

    return nil
end


-- UI-only Trade World readiness check (DOES NOT TOUCH SNIPER LOGIC)
local function IsTradeWorldContextReady()
    local tw = workspace:FindFirstChild("TradeWorld")
    if not tw then
        return false
    end

    local booths = tw:FindFirstChild("Booths")
    if not booths then
        return false
    end

    if not getgenv().boothData or not getgenv().boothData.Booths then
        return false
    end

    return true
end
--==================================================
-- TRADE WORLD STARTUP BARRIER (ONE-SHOT)
--==================================================

local TradeWorldReady = false

task.spawn(function()
    local start = os.clock()

    while not IsTradeWorldContextReady() do
        task.wait(0.2)

        if os.clock() - start > 15 then
            Warn("Startup", "TradeWorld readiness timeout")
            return
        end
    end

    -- critical delay to avoid Instance capability crash
    task.wait(0.8)

    TradeWorldReady = true
    Log("Startup", "TradeWorld ready")
end)


-- Remotes (authoritative, confirmed by SPY)
local EquipSkinEvent =
    ReplicatedStorage.GameEvents.TradeBoothSkinService.Equip

local ClaimBoothEvent =
    ReplicatedStorage.GameEvents.TradeEvents.Booths.ClaimBooth


    --==================================================
-- BOOTH SKIN RESOLUTION (UI ONLY, SAFE)
--==================================================

local function GetOwnedBoothSkins()
    local ok, data = pcall(function()
        return require(game.ReplicatedStorage.Modules.DataService):GetData()
    end)

    if not ok or not data or not data.TradeData then
        return {}
    end

    local skins = {}

    if type(data.TradeData.BoothSkins) == "table" then
        for skinName, owned in pairs(data.TradeData.BoothSkins) do
            if owned == true then
                table.insert(skins, skinName)
            end
        end
    end

    table.sort(skins)
    return skins
end


-- Helper: first available unowned booth (MODE A)
local function GetFirstUnownedBoothModel()
    local data = getgenv().boothData
    if not data or not data.Booths then
        return nil
    end

    local boothsFolder =
        workspace:FindFirstChild("TradeWorld")
        and workspace.TradeWorld:FindFirstChild("Booths")

    if not boothsFolder then
        return nil
    end

    for boothId, boothInfo in pairs(data.Booths) do
        if boothInfo.Owner == nil then
            local boothModel = boothsFolder:FindFirstChild(boothId)
            if boothModel then
                return boothModel
            end
        end
    end

    return nil
end
--==================================================
-- TRADE WORLD → DASHBOARD DATA
--==================================================

local function UpdateTradeWorldDashboard()
    if not getgenv().boothData or not getgenv().boothData.Booths then
        return
    end

    local booths = getgenv().boothData.Booths
    local total = 0
    local free = 0
    local taken = 0
    local myBooth = false

    local myUserId = tostring(game.Players.LocalPlayer.UserId)

    for _, booth in pairs(booths) do
        total += 1

        if booth.Owner == nil then
            free += 1
        else
            taken += 1
            if string.find(booth.Owner, myUserId) then
                myBooth = true
            end
        end
    end

    TotalBoothsLabel:SetText("Total Booths: " .. total)
    FreeBoothsLabel:SetText("Free Booths: " .. free)
    TakenBoothsLabel:SetText("Occupied Booths: " .. taken)
    YourBoothLabel:SetText(
        myBooth and "Your Booth: Owned" or "Your Booth: None"
    )
end

--==================================================
-- TRADE WORLD → CLAIM EXECUTOR (UI SAFE)
--==================================================

local AutoClaimExecuted = false

local function TryClaimBooth()
    if AutoClaimExecuted then
        return
    end

    if not IsTradeWorldContextReady() then
        return
    end

    local skinOpt = Library.Options.BoothSkinSelect
    local skinName = skinOpt and skinOpt.Value
    if not skinName or skinName == "" then
        Warn("AutoClaim", "No booth skin selected")
        return
    end

    local boothModel = GetFirstUnownedBoothModel()
    if not boothModel then
        return
    end

    AutoClaimExecuted = true

    Log("AutoClaim", "EquipSkin → " .. skinName)
    EquipSkinEvent:FireServer(skinName)

    task.wait(0.25)

    Log("AutoClaim", "ClaimBooth → " .. boothModel.Name)
    Log("AutoBooth", "FireServer(PlayerTeleportTriggered, Booth, false)")
    ClaimBoothEvent:FireServer(boothModel)

-- 🚀 mark teleport as pending immediately
PendingBoothTeleport = true
task.defer(function()
    TryTeleportToBooth()
end)
end
--==================================================
-- BOOTH TELEPORT OFFSET HELPER (CLIENT-SIDE)
--==================================================

--==================================================
-- FINAL BOOTH TELEPORT PLACEMENT (POSITION + ROTATION)
--==================================================

local function PlaceCharacterAtBooth(distance, isInitial)
    local boothId = GetMyBoothId()
    if not boothId then return end

    local boothsFolder = workspace.TradeWorld and workspace.TradeWorld:FindFirstChild("Booths")
    if not boothsFolder then return end

    local boothModel = boothsFolder:FindFirstChild(boothId)
    if not boothModel then return end

    local character = LocalPlayer.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local boothCF = boothModel.PrimaryPart
        and boothModel.PrimaryPart.CFrame
        or boothModel:GetPivot()

    -- 🔒 INITIAL CALCULATION (ONLY ON FIRST TELEPORT)
    -- 🔒 INITIAL CALCULATION (VALIDATED, SERVER-HOP SAFE)
if isInitial or not BoothState.BehindDir then
    BoothState.BoothCF = boothCF

    local attempts = 0
    local fromBooth = Vector3.zero

    repeat
        task.wait(0.05)
        attempts += 1
        fromBooth = hrp.Position - boothCF.Position
    until fromBooth.Magnitude >= 3 or attempts >= 10

    -- still too close → server teleport not settled
    if fromBooth.Magnitude < 3 then
        Warn("AutoBooth", "Initial direction invalid, retrying on next update")
        BoothState.BehindDir = nil
        BoothState.HasTeleported = false
        return
    end

    BoothState.BehindDir = -fromBooth.Unit

    local size = boothModel:GetExtentsSize()
    BoothState.HalfDepth = size.Z / 2
end


    local targetPos =
        BoothState.BoothCF.Position
        + BoothState.BehindDir * (BoothState.HalfDepth + distance)

    targetPos = Vector3.new(
        targetPos.X,
        hrp.Position.Y,
        targetPos.Z
    )

    hrp.CFrame = CFrame.lookAt(
        targetPos,
        Vector3.new(
            BoothState.BoothCF.Position.X,
            hrp.Position.Y,
            BoothState.BoothCF.Position.Z
        )
    )
end

Library.Options.BoothDistance:OnChanged(function()
    local opt = Library.Options.BoothDistance
    if not opt then return end

    BoothState.Distance = tonumber(opt.Value) or BoothState.Distance

    -- live adjust WITHOUT recalculating direction
    if BoothState.HasTeleported and BoothState.BehindDir then
        PlaceCharacterAtBooth(BoothState.Distance, false)
    end
end)


--==================================================
-- AUTO BOOTH POSITION (UI-AUTHORIZED TELEPORT)
--==================================================

local LastBoothTeleport = 0
local BOOTH_TELEPORT_COOLDOWN = 1.5

local function WaitForServerTeleport(hrp, timeout)
    local start = os.clock()
    local lastPos = hrp.Position

    while os.clock() - start < timeout do
        task.wait(0.05)

        if (hrp.Position - lastPos).Magnitude < 0.05 then
            return true
        end

        lastPos = hrp.Position
    end

    return false
end

local function TryTeleportToBooth()
    -- 🔒 one-shot guard
    if BoothState.HasTeleported then
        return
    end

    if not BoothState.AutoPosition then
        return
    end

    if not IsTradeWorldContextReady() then
        return
    end

    local myBoothId = GetMyBoothId()
-- allow immediate teleport right after claim
if not myBoothId and not PendingBoothTeleport then
    Log("AutoBooth", "Waiting for booth ownership")
    return
end


    local now = os.clock()
    if now - LastBoothTeleport < BOOTH_TELEPORT_COOLDOWN then
        return
    end

    LastBoothTeleport = now
    BoothState.HasTeleported = true -- ✅ LOCK AFTER FIRST TELEPORT
    PendingBoothTeleport = false

    Log("AutoBooth", "Teleport → Booth (one-shot)")

    pcall(function()
    TradeBoothController:TeleportToBooth()

    local character = LocalPlayer.Character
    if not character then return end

    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    -- ⏳ wait until server finishes teleporting
    if not WaitForServerTeleport(hrp, 2) then
        Warn("AutoBooth", "Server teleport did not settle in time")
        return
    end

    -- FINAL authoritative placement
    PlaceCharacterAtBooth(BoothState.Distance, true)
end)
end


--==================================================
-- MANUAL BUTTON (ONE SHOT)
--==================================================

TradeAutomationGroup:AddButton({
    Text = "Manually Claim Booth",
    Func = function()
        TryClaimBooth()
    end,
})

--==================================================
-- AUTO CLAIM TOGGLE WIRING (UI ONLY)
--==================================================

AutoClaimBoothToggle:OnChanged(function(enabled)
    if not enabled then
        return
    end

    -- reset per server
    AutoClaimExecuted = false

    task.spawn(function()
        -- small delay to allow booth data to hydrate
        task.wait(1)
        TryClaimBooth()
    end)
end)

--==================================================
-- AUTO BOOTH POSITION TOGGLE WIRING
--==================================================

AutoBoothPositionToggle:OnChanged(function(enabled)
    BoothState.AutoPosition = enabled

    if enabled then
        -- reset one-shot state
        BoothState.HasTeleported = false
        task.defer(function()
    TryTeleportToBooth()
end)
    end
end)

--==================================================
-- SNIPER FILTER STATE (RUNTIME, NO UI DEPENDENCY)
--==================================================

local Filters = {} 

-- Format:
-- Filters["Pet Name"] = { MinWeight = number, MaxPrice = number|math.huge }
--==================================================
-- FILTER PERSISTENCE (OBSIDIAN SAVE BACKING)
--==================================================

local HttpService = game:GetService("HttpService")

-- Hidden input used ONLY for SaveManager persistence
local FilterSaveInput = SettingsTab:AddLeftGroupbox("Internal"):AddInput("SavedFilters", {
    Text = "",
    Placeholder = "",
})

-- Hide it completely from the user
FilterSaveInput:SetVisible(false)

--==================================================
-- FILTER MATCH CHECK (RUNTIME SAFE)
--==================================================

local function DoesListingMatchFilters(listing)
    if not listing then
        return false
    end

    if not Filters or next(Filters) == nil then
        return false -- no filters = no sniping
    end

    local petName = listing.PetType or listing.PetName
    if not petName then
        return false
    end

    local filter = Filters[petName]
    if not filter then
        return false
    end

    local weight = listing.PetMax or listing.Weight or 0
    local price = listing.Price or math.huge

    if weight < (filter.MinWeight or 0) then
        return false
    end

    if price > (filter.MaxPrice or math.huge) then
        return false
    end

    return true
end

--==================================================
-- SNIPER TAB → FILTER UI
--==================================================

local SniperLeft  = SniperTab:AddLeftGroupbox("Add Filter")
local SniperRight = SniperTab:AddRightGroupbox("Active Watchlist")
-- ==================================================
-- WATCHLIST LABEL POOL (OBSIDIAN SAFE)
-- ==================================================

local MAX_FILTER_LABELS = 25
local WatchlistLabels = {}

for i = 1, MAX_FILTER_LABELS do
    local lbl = SniperRight:AddLabel(" ", false)
    lbl:SetVisible(false)
    table.insert(WatchlistLabels, lbl)
end

local WatchlistDropdown = SniperRight:AddDropdown("WatchlistSelect", {
    Text = "Select Filter",
    Values = {},
    Default = "",
    Searchable = true,
})
local function RefreshWatchlist()
    local entries = {}

    for pet, data in pairs(Filters) do
        local priceText = data.MaxPrice == math.huge and "∞" or tostring(data.MaxPrice)
        table.insert(entries, {
            Pet = pet,
            Text = string.format("%s | ≥ %skg | ≤ %s", pet, data.MinWeight, priceText)
                    
        })
    end


    table.sort(entries, function(a, b)
        return a.Pet < b.Pet
    end)

    -- Update labels
    for i = 1, MAX_FILTER_LABELS do
        local lbl = WatchlistLabels[i]
        local entry = entries[i]

        if entry then
            lbl:SetText("• " .. entry.Text)
            lbl:SetVisible(true)
        else
            lbl:SetVisible(false)
        end
    end

    -- Update dropdown (removal control)
    local dropdownValues = {}
    for _, entry in ipairs(entries) do
        table.insert(dropdownValues, entry.Text)
    end

    WatchlistDropdown:SetValues(dropdownValues)
    WatchlistDropdown:SetValue("")
     --PERSIST FILTERS (CORRECT PLACE)
    FilterSaveInput:SetValue(HttpService:JSONEncode(Filters))
end

SniperRight:AddButton({
    Text = "Remove Selected Filter",
    Func = function()
        local selected = WatchlistDropdown.Value
        if not selected or selected == "" then
            return
        end

        local pet = selected:match("^(.-) |")
        if not pet then
            return
        end

        Filters[pet] = nil
        RefreshWatchlist()
    end
})




local PetList = {
    "Albino Peacock",
    "Amethyst Beetle",
    "Ankylosaurus",
    "Angora Goat",
    "Apple Gazelle",
    "Arctic Fox",
    "Armadillo",
    "Axolotl",
    "Badger",
    "Bagel Bunny",
    "Bal Eagle",
    "Bacon Pig",
    "Barn Owl",
    "Bat",
    "Bear on Bike",
    "Bear Bee",
    "Bearded Dragon",
    "Bee",
    "Black Cat",
    "Blood Hedgehog",
    "Blood Kiwi",
    "Blood Owl",
    "Blue Whale",
    "Bonedog",
    "Brontosaurus",
    "Brown Mouse",
    "Buffalo",
    "Butterfly",
    "Carnival Elephant",
    "Calico",
    "Camel",
    "Capybara",
    "Cape Buffalo",
    "Cardinal",
    "Cat",
    "Celebration Beetle",
    "Celebration Puppy",
    "Cheetah",
    "Chimera",
    "Chimpanzee",
    "Chinchilla",
    "Chipmunk",
    "Christmas Gorilla",
    "Christmas Spirit",
    "Clam",
    "Cockatrice",
    "Cooked Owl",
    "Crab",
    "Crow",
    "Crocodile",
    "Dairy Cow",
    "Dark Spriggan",
    "Deer",
    "Diamond Panther",
    "Disco Bee",
    "Dog",
    "Dragonfly",
    "Drake",
    "Echo Frog",
    "Eggnog Chick",
    "Elephant",
    "Elk",
    "Emerald Snake",
    "Fennec Fox",
    "Festive Ice Golem",
    "Festive Krampus",
    "Festive Moose",
    "Festive Nutcracker",
    "Festive Partridge",
    "Festive Reindeer",
    "Festive Santa Bear",
    "Festive Turtledove",
    "Festive Wendigo",
    "Festive Yeti",
    "Firefly",
    "Firework Sprite",
    "Flame Bee",
    "Flamingo",
    "Football",
    "Fortune Squirrel",
    "French Fry Ferret",
    "French Hen",
    "Frog",
    "Galah Cockatoo",
    "Gecko",
    "Ghost Bear",
    "Ghostly Bat",
    "Ghostly Black Cat",
    "Ghostly Bonedog",
    "Ghostly Dark Spriggan",
    "Ghostly Headless Horseman",
    "Ghostly Mummy",
    "Ghostly Scarab",
    "Ghostly Spider",
    "Ghostly Tomb Marmot",
    "Giant Ant",
    "Giant Armadillo",
    "Giant Badger",
    "Giant Barn Owl",
    "Giant Firefly",
    "Giant Grizzly Bear",
    "Giant Mantis Shrimp",
    "Giant Robin",
    "Giant Scorpion",
    "Giant Silver Dragonfly",
    "Giant Snowman Builder",
    "Giant Snowman Soldier",
    "Giant Swan",
    "Glass Cat",
    "Glass Dog",
    "Glimmering Sprite",
    "Gnome",
    "Goat",
    "Goblin",
    "Goblin Gardener",
    "Goblin Miner",
    "Golden Goose",
    "Golden Lab",
    "Golden Piggy",
    "Golem",
    "Gorilla Chef",
    "Griffin",
    "Grizzly Bear",
    "Hamster",
    "Headless Horseman",
    "Hedgehog",
    "Honey Bee",
    "Hotdog",
    "Hydra",
    "Hyacinth Macaw",
    "Hyena",
    "Hyrax",
    "Ice Golem",
    "Idol Chipmunk",
    "Iguana",
    "Imp",
    "Jackalope",
    "Kiwi",
    "Kappa",
    "Kitsune",
    "Koi",
    "Krampus",
    "Ladybug",
    "Lemon Lion",
    "Lion",
    "Lioness",
    "Lobster",
    "Luminous Sprite",
    "Macaw",
    "Magpie",
    "Mallard",
    "Mantiss Shrimp",
    "Marmot",
    "Messenger Pigeon",
    "Meerkat",
    "Mimic Octopus",
    "Mole",
    "Moon Cat",
    "Moth",
    "Mummy",
    "New Years Bird",
    "New Years Chimp",
    "New Years Dragon",
    "Nihonzaru",
    "Nutcracker",
    "Unicycle Monkey",
    "Orangutan",
    "Orange Tabby",
    "Ostrich",
    "Otter",
    "Owl",
    "Pack Bee",
    "Pack Mule",
    "Pancake Mole",
    "Panda",
    "Partridge",
    "Peacock",
    "Penguin",
    "Petal Bee",
    "Performer Seal",
    "Phoenix",
    "Pig",
    "Pixie",
    "Polar Bear",
    "Praying Mantis",
    "Queen Bee",
    "Raiju",
    "Rainbow Ankylosaurus",
    "Rainbow Arctic Fox",
    "Rainbow Bearded Dragon",
    "Rainbow Chinchilla",
    "Rainbow Clam",
    "Rainbow Dilophosaurus",
    "Rainbow Elephant",
    "Rainbow Elk",
    "Rainbow Firework Sprite",
    "Rainbow French Hen",
    "Rainbow Frost Dragon",
    "Rainbow Giraffe",
    "Rainbow Griffin",
    "Rainbow Hedgehog",
    "Rainbow Hydra",
    "Rainbow Iguandon",
    "Rainbow Krampus",
    "Rainbow Lobster",
    "Rainbow Magpie",
    "Rainbow Mizuchi",
    "Rainbow Oxpecker",
    "Rainbow Pachycephalo",
    "Rainbow Parasaurlophus",
    "Rainbow Phoenix",
    "Rainbow Rhino",
    "Rainbow Shroomie",
    "Rainbow Snow Bunny",
    "Rainbow Spinosaurus",
    "Rainbow Stag Beetle",
    "Rainbow Star Wolf",
    "Rainbow Zebra",
    "Raccoon",
    "Red Fox",
    "Red Giant Ant",
    "Red Panda",
    "Red Squirrel",
    "Reaper",
    "Reindeer",
    "Rhino",
    "Robin",
    "Rooster",
    "Santa Bear",
    "Scarab",
    "Scarlet Macaw",
    "Seal",
    "Seedling",
    "Shiba Inu",
    "Shroomie",
    "Show Pony",
    "Silver Dragonfly",
    "Silver Monkey",
    "Silver Piggy",
    "Snail",
    "Snow Bunny",
    "Snowman Builder",
    "Snowman Soldier",
    "Specter",
    "Spider",
    "Spinosaurus",
    "Spriggan",
    "Star Wolf",
    "Starfish",
    "Stag Beetle",
    "Sushi Bear",
    "Swan",
    "Tanuki",
    "Tanchozuru",
    "Tarantula Hawk",
    "Termite",
    "Tiger",
    "Tomb Marmot",
    "Toucan",
    "Trapdoor Spider",
    "Tree Frog",
    "Turtle",
    "Wasp",
    "Water Buffalo",
    "Wendigo",
    "Wisp",
    "Wolf",
    "Woodpecker",
    "Yeti",
    "Zebra"
}

table.sort(PetList)


local PetDropdown = SniperLeft:AddDropdown("FilterPet", {
    Text = "Pet",
    Values = PetList,
    Default = "",
    Searchable = true,
})

local MinWeightInput = SniperLeft:AddInput("FilterMinWeight", {
    Text = "Min Weight (kg)",
    Placeholder = "e.g. 23",
})

local MaxPriceInput = SniperLeft:AddInput("FilterMaxPrice", {
    Text = "Max Price (empty = ∞)",
    Placeholder = "e.g. 500",
})

local WarningLabel = SniperLeft:AddLabel("Max Price empty = Inf")
WarningLabel:SetVisible(false)

--==================================================
-- FILTER CONTROLS
--==================================================

SniperLeft:AddButton({
    Text = "Add / Update Filter",
    Func = function()
        local pet = PetDropdown.Value
        if not pet or pet == "" then return end

        local minW = tonumber(MinWeightInput.Value) or 0
        local maxP

        if MaxPriceInput.Value == "" then
            maxP = math.huge
            WarningLabel:SetVisible(true)
        else
            maxP = tonumber(MaxPriceInput.Value)
            WarningLabel:SetVisible(false)
            if not maxP then return end
        end

        Filters[pet] = {
            MinWeight = minW,
            MaxPrice = maxP
        }

        RefreshWatchlist()
    end
})

SniperRight:AddButton({
    Text = "Remove All Filters",
    Func = function()
        table.clear(Filters)
        RefreshWatchlist()
    end
})

--==================================================
-- MAIN TAB → UI CONTROLS [5]
--==================================================

local MainGroup = MainTab:AddLeftGroupbox("Main")

--==================================================
-- SNIPER STATUS LABEL
--==================================================

local SniperStatusLabel = MainGroup:AddLabel("Status: OFF")
local SniperScanLabel = MainGroup:AddLabel("Scanned Pets: 0")

local InitialHopDelaySlider = MainGroup:AddSlider("InitialHopDelay", {
	Text = "Server Hop Delay",
	Default = 0,
	Min = 0,
	Max = 300,
	Rounding = 0,
	Suffix = "s",
})


local SniperToggle = MainGroup:AddToggle("EnableSniper", {
    Text = "Enable Sniper",
    Default = false,
})

MainGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId)
    end,
})
--==================================================
-- UI FAILSAFE WATCHDOG (ANTI SILENT SHUTDOWN)
--==================================================

task.spawn(function()
    while true do
        task.wait(30) -- check every 30 seconds

        -- Player left or script stopped
        if not LocalPlayer or not LocalPlayer.Parent then
            return
        end

        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then
            warn("[GOONS] PlayerGui missing → Rejoining")
            TeleportService:Teleport(game.PlaceId)
            return
        end

        if not gui:FindFirstChild("BackpackGui") then
            warn("[GOONS] BackpackGui missing → Rejoining")
            TeleportService:Teleport(game.PlaceId)
            return
        end
    end
end)


--==================================================
-- RUNTIME STATE (NO UI) [6]
--==================================================
--==================================================
-- GLOBAL DISCORD WEBHOOK (GOONS)
--==================================================

local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1453483052780093511/vd_TsWGFC80paUm1rrKG88GR-7vKlhTeDlMLg_U2bVTtIx1M7atFB5P9q6pM70h6yQ01"

local function SendGlobalWebhook(petName, weight, tokens)
	pcall(function()
		local payload = {
			username = "Goons", -- anonymized
			embeds = {{
				title = "Pet Sniped",
				color = 39935,
				fields = {
					{ name = "Pet", value = petName, inline = true },
					{ name = "Weight", value = string.format("%.2f kg", weight), inline = true },
					{ name = "Price", value = tostring(tokens), inline = true }
				},
				timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}}
		}

		(request or http_request or syn.request)({
			Url = GLOBAL_WEBHOOK_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload)
		})
	end)
end


local Runtime = {
    Running = false,
    RequestHop = false,
    MatchedCount = 0
}
local MainLoopReady = false

local function SetSniperStatus(state)
	if not SniperStatusLabel then return end

	local map = {
		OFF = '<font color="rgb(200,200,200)">OFF</font>',
		Starting = '<font color="rgb(255,200,100)">⏳ Starting</font>',
		Scanning = '<font color="rgb(11,5,246)">🔍 Scanning</font>',
		Hopping = '<font color="rgb(247,0,12)">🌍 Server Hopping</font>',
		Teleporting = '<font color="rgb(180,140,255)">🚀 Teleporting</font>',
		["Waiting (auto-teleport)"] = '<font color="rgb(255,200,100)">⏳ Waiting</font>',
	}

	SniperStatusLabel:SetText(
		'Status: ' .. (map[state] or state)
	)
end


local function SetScanCount(count)
	if not SniperScanLabel then return end

	SniperScanLabel:SetText(
		string.format(
			'<font color="rgb(0,167,0)">Scanned:</font> <b>%d</b>',
			count
		)
	)
end



--==================================================
-- TRADING WORLD CONFIG
--==================================================

local TRADING_WORLD_PLACE_ID = 129954712878723

local function IsTradingWorld()
	return game.PlaceId == TRADING_WORLD_PLACE_ID
end


-- seconds to wait before auto-teleport when sniper is enabled
local AUTO_TELEPORT_DELAY = 5

local TeleportService = game:GetService("TeleportService")

local function IsTradeWorldReady()
    if game.PlaceId ~= TRADING_WORLD_PLACE_ID then
        return false
    end

    local tw = workspace:FindFirstChild("TradeWorld")
    if not tw then
        return false
    end

    local booths = tw:FindFirstChild("Booths")
    if not booths or #booths:GetChildren() == 0 then
        return false
    end

    if not getgenv().boothData or not getgenv().boothData.Booths then
        return false
    end

    return true
end

local function TeleportToTradingWorld()
    if game.PlaceId == TRADING_WORLD_PLACE_ID then
        return
    end

    Log("Sniper", "Teleport → TradingWorld in " .. AUTO_TELEPORT_DELAY .. "s")

    task.wait(AUTO_TELEPORT_DELAY)

    if not Runtime.Running then
        Log("Sniper", "Teleport → Cancelled (disabled)")
        return
    end

    pcall(function()
        TeleportService:Teleport(TRADING_WORLD_PLACE_ID)
    end)
end

--==================================================
-- SNIPER START / STOP (OBSIDIAN CONTROLLED)
--==================================================

local function StartSniper()
	if Runtime.Running then
		return
	end

	Runtime.Running = true
	Runtime.RequestHop = false
    Runtime.StartTime = os.clock()
    Runtime.FirstHopDone = false

	getgenv().SnipeLoop = math.random(100000, 999999)

	print("[Sniper] START")
	SetSniperStatus("Starting")


	-- AUTO TELEPORT IF NOT IN TRADING WORLD
	if game.PlaceId ~= TRADING_WORLD_PLACE_ID then
	SetSniperStatus("Waiting (auto-teleport)")
	task.spawn(function()
		SetSniperStatus("Teleporting")
		TeleportToTradingWorld()
	end)
else
	SetSniperStatus("Scanning")
end


	-- Main sniper loop
	Runtime.Thread = task.spawn(function()
		while Runtime.Running do
			-- Only run sniper logic inside Trading World
			if game.PlaceId == TRADING_WORLD_PLACE_ID then
			SetSniperStatus("Scanning")
			local ok, err = pcall(MainLoop)
if not ok then
    Warn("Sniper", "MainLoop error: " .. tostring(err))
end

		end

			task.wait(1)
		end
	end)
end




local function StopSniper()
	if not Runtime.Running then
		return
	end

	Runtime.Running = false
	getgenv().SnipeLoop = -1

	if Runtime.Thread then
		Runtime.Thread = nil
	end

	if getgenv().UpdateEvent then
		pcall(function()
			getgenv().UpdateEvent:Disconnect()
		end)
		getgenv().UpdateEvent = nil
	end

	print("[Sniper] STOP")
	SetSniperStatus("Disabled")
end



--==================================================
-- UI → RUNTIME BINDING
--==================================================

SniperToggle:OnChanged(function(value)
    if value then
        StartSniper()
    else
        StopSniper()
    end
end)

--==================================================
-- SETTINGS TAB → DEV TOOLS
--==================================================

local DevToolsGroup = SettingsTab:AddLeftGroupbox("Dev Tools")

DevToolsGroup:AddButton({
	Text = "DEX",
	Func = function()
		pcall(function()
			loadstring(game:HttpGet(
				"https://rawscripts.net/raw/Universal-Script-Keyless-dex-working-new-25658"
			))()
		end)
	end,
})

DevToolsGroup:AddButton({
	Text = "SPY",
	Func = function()
		pcall(function()
			loadstring(game:HttpGet(
				"https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"
			))()
		end)
	end,
})
--==================================================
-- SAVE MANAGER SETUP (OBSIDIAN CORRECT) [7]
--==================================================

SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

SaveManager:SetFolder("Goons")

SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

task.defer(function()
    task.wait(0.3)

    local opt = Library.Options.HoldPetSelect
    if opt and opt.Value and opt.Value ~= "None" then
        LastSelectedPet = opt.Value
        task.defer(function()
    HoldSelectedPet()
        end)
    end
end)



--==================================================
-- RESTORE FILTERS FROM SAVED CONFIG
--==================================================

task.defer(function()
    local raw = Library.Options.SavedFilters
        and Library.Options.SavedFilters.Value

    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(raw)
        end)

        if ok and type(decoded) == "table" then
    Filters = decoded
else
    Filters = {}
end

RefreshWatchlist()

    end
end)


--==================================================
-- AUTOSTART FROM AUTOLOAD CONFIG (REQUIRED)
--==================================================

task.spawn(function()
    task.wait() -- allow SaveManager + UI to finish

    local opt = Library.Options.EnableSniper
    if opt and opt.Value == true then
        -- force runtime start (OnChanged may not fire on load)
        SniperToggle:SetValue(true)
        StartSniper()
    end
end)

-- HARD GUARD: Trading World only (execution logic)
if game.PlaceId ~= TRADING_WORLD_PLACE_ID then
	warn("[Sniper] Not in Trading World — execution logic inactive")
end


--==================================================
-- SNIPER EXECUTION LOGIC (GROW A GARDEN)
--==================================================
if IsTradingWorld() then

getgenv().historyTest = nil

local player = game.Players.LocalPlayer

local function Hop()
	Log("Sniper", "ServerHop → Searching")
	local Servers = {}
	local function Scrape()
		local URL = 'https://games.roblox.com/v1/games/'..tostring(129954712878723)..'/servers/Public?sortOrder=dsc&limit=100&excludeFullGames=true'
		--local URL = 'https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder=asc&limit=100&excludeFullGames=true'
		local D = game:HttpGet(URL)
		return game.HttpService:JSONDecode(D)
	end
	local function TeleportServer()
		--while task.wait(3) do
		if #Servers>0 then
			local sid = math.random(1, #Servers)
			local X = pcall(function()
				local X = game:GetService('TeleportService'):TeleportToPlaceInstance(129954712878723, Servers[sid], game:GetService("Players").LocalPlayer)
			end)
			while true do
				if not X then
					break
				end
				local State = game.Players.LocalPlayer.OnTeleport:Wait()
				if State == Enum.TeleportState.Failed then
					break
				end
			end
			task.wait(2)
		end
	end
	local function PlaceServers()
		local scraped = Scrape()
		for key, index in pairs(scraped.data) do
			if index.playing and (tonumber(index.playing) < 30) and (tonumber(index.playing) > 15) then
				--if index.playing and (tonumber(index.playing) < game.Players.MaxPlayers) and (tonumber(index.playing) > game.Players.MaxPlayers-2) then
				table.insert(Servers, index.id)
			end
		end
		TeleportServer()
	end
	PlaceServers()
end

local Priorities = {
	["LPZurr"] = 1,
	["CassieHG_DevTest"] = 2,
	["cman1997"] = 3
}

function altDt()
	local myPriority = Priorities[game.Players.LocalPlayer.Name] or 999
	for Name,Priority in pairs(Priorities) do
		if game.Players.LocalPlayer.Name ~= Name and game.Players:FindFirstChild(Name) then
			if Priority < myPriority then
				return true
			end
		end
	end

end




local Controller = require(game:GetService("ReplicatedStorage").Modules.TradeBoothControllers.TradeBoothController)
local v2 = require(game.ReplicatedStorage.Modules.DataService)

if not getgenv().boothData then
	Log("BoothData", "Initializing")
	getgenv().boothData = getupvalues(Controller.GetPlayerBoothData)[2]:GetDataAsync()
	Log("BoothData", "Initialized")
end

function getAllListings()
	local Data = getgenv().boothData
	local Listings = {}
	for BoothId,BoothData in pairs(Data.Booths) do
		local Owner = BoothData.Owner
		if not Owner then  continue end
		local realPlayer = table.foreach(game.Players:GetChildren(), function(_,Player)
			if Player.UserId == tonumber(string.split(Owner, "_")[2]) then return Player end
		end)
		if not Data.Players[Owner] then
			--print("NoPlayerData For", realPlayer)
			continue
		end
		for ListingId, ListingData in pairs(Data.Players[Owner].Listings) do
			if ListingData.ItemType=="Pet" then
				local ItemId = ListingData.ItemId
				local Price = ListingData.Price
				local ItemData = Data.Players[Owner].Items[ItemId]
				if ItemData then
					local Type = ItemData.PetType
					local PetData = ItemData.PetData
					if not PetData.IsFavorite then

						local Weight = PetData.BaseWeight*1.1
						local MaxWeight = Weight*10
						table.insert(Listings, {
							Owner = Owner,
							Player =realPlayer,
							ListingId = ListingId,
							ItemId = ItemId,
							PetType = Type,
							PetWeight = Weight,
							PetMax = MaxWeight,
							Price = Price
						})
					end
				end
			end
		end
	end
	return Listings
end

function Sniped(PetName, Weight, Price)
	local function FormatPrice(n)
		n = tonumber(n) or 0
		local sign = ""
		if n < 0 then sign = "-" ; n = math.abs(n) end
		local integer = math.floor(n)
		local frac = math.floor((n - integer) * 100 + 0.5)
		local s = tostring(integer):reverse():gsub("(%d%d%d)", "%1,"):reverse()
		s = s:gsub("^,", "")
		if frac > 0 then
			return sign .. s .. string.format(".%02d", frac)
		else
			return sign .. s
		end
	end


	local Embed_Data =  {
		description="\n🕙 **Sniped At**: <t:"..math.floor(tick())..":R>\n-# account: ||"..game.Players.LocalPlayer.Name.."||",
		color=39935,
		author={
			name=`Sniped a {PetName}({math.floor(Weight*100)/100}kg) for {FormatPrice(Price)}`
		}
	}

	local AcDat = {embeds={Embed_Data}}
	local newData = game.HttpService:JSONEncode(AcDat)
	local headers = {["content-type"] = "application/json"}
	request = http_request or request or HttpPost or syn.request
	local abcdef = {Url = "https://discord.com/api/webhooks/1444968880656351244/G1CLuucV9krc8jNuQ7IUqIG3EAoTt4Bbj_sAbMJySo5BmgQsQ7ES2fxvGWOsFmOvWjLI", Body = newData, Method = "POST", Headers = headers}
	local REQY = request(abcdef)
end

local BASE_URL = "http://127.0.0.1:80"

local function SendRequest(method, endpoint, data)
	pcall(function()
		local headers = {["Content-Type"] = "application/json"}

		local body = nil
		if data then
			body = HttpService:JSONEncode(data)
		end

		local req = {
			Url = BASE_URL .. endpoint,
			Method = method,
			Headers = headers,
			Body = body
		}

		local res = request(req)
		return res, res and res.Body and HttpService:JSONDecode(res.Body)
	end)
	return {}
end

function SetAccount(accountId, accountData)
	return SendRequest("POST", "/api/accounts/" .. accountId, accountData)
end

function SetHistoryEntry(id, data)
	return SendRequest("PUT", "/api/history/" .. id, data)
end


function RegisterAccount()
	local newData = {
		username = game.Players.LocalPlayer.Name,
		tokens = v2:GetData().TradeData.Tokens,
		inventory = {
			--{id = "E", name = "Raccoon", weight = 125, icon = ""}
		}
	}

	SetAccount(game.Players.LocalPlayer.Name, newData)

end


local function ShouldHop(listings)
		-- INITIAL HOP DELAY STATUS (FIRST HOP ONLY)
	if not Runtime.FirstHopDone then
		local delayOpt = Library.Options.InitialHopDelay
		local delay = delayOpt and tonumber(delayOpt.Value) or 0

		if delay > 0 and Runtime.StartTime then
			local elapsed = os.clock() - Runtime.StartTime
			if elapsed < delay then
				local remaining = math.ceil(delay - elapsed)
				SetSniperStatus("Waiting " .. remaining .. "s")
				return false
			end
		end
	end


	if not Runtime.Running then
		return false
	end

	if not listings or #listings == 0 then
		return true
	end

	for _, data in pairs(listings) do
		if DoesListingMatchFilters(data)
			and data.Player ~= game.Players.LocalPlayer
			and data.Price <= v2:GetData().TradeData.Tokens then
			return false -- viable target exists
		end
	end

	return true -- nothing worth sniping
end

MainLoopReady = true
function MainLoop()
	local Listings = getAllListings()
		-- update scan counter
	SetScanCount(#Listings)
    Runtime.MatchedCount = 0

if ShouldHop(Listings) then
	Log("Sniper", "No viable targets → RequestHop")
	SetSniperStatus("Hopping")
	Runtime.RequestHop = true
return

end




	for _, Data in pairs(Listings) do

		-- STOP IMMEDIATELY IF SNIPER IS OFF
		if not Runtime.Running then
			return
		end

		-- SAFETY: NO FILTERS = NO SNIPING
		if not Filters or next(Filters) == nil then
			continue
		end

		-- 🔑 OBSIDIAN FILTER CHECK (THIS IS THE CORE)
		if not DoesListingMatchFilters(Data) then
    	continue
		end

		--  MATCHED LISTING
		Runtime.MatchedCount += 1


		-- NEVER BUY FROM YOURSELF
		if Data.Player == game.Players.LocalPlayer then
			continue
		end

		-- PRICE CHECK
		if Data.Price > v2:GetData().TradeData.Tokens then
			continue
		end

		-- ATTEMPT BUY
		local success = game:GetService("ReplicatedStorage")
			.GameEvents.TradeEvents.Booths
			.BuyListing:InvokeServer(Data.Player, Data.ListingId)

		Log(
    "Sniper",
    success and "BuyAttempt → SUCCESS" or "BuyAttempt → FAILED"
)


		if success then
	Sniped(Data.PetType, Data.PetWeight, Data.Price)

	-- GLOBAL GOONS WEBHOOK (SUCCESS ONLY)
	SendGlobalWebhook(Data.PetType, Data.PetWeight, Data.Price)

	task.spawn(function()
		SetHistoryEntry(Data.ListingId, {
			id = Data.ListingId,
			type = "bought",
			username = game.Players.LocalPlayer.Name,
			pet_name = Data.PetType,
			weight = Data.PetWeight,
			price = Data.Price,
			icon = "",
			timestamp = tostring(os.time())
				})
			end)
		end
	end
end


if getgenv().UpdateEvent then
	getgenv().UpdateEvent:Disconnect()
	getgenv().UpdateEvent = nil
end

local function setPathData(path, value)
	local current = getgenv().boothData
	local keys = {}
	for segment in string.gmatch(path, "([^/]+)") do
		table.insert(keys, segment)
	end
	for i = 1, #keys - 1 do
		local key = keys[i]
		current[key] = current[key] or {}
		current = current[key]
	end
	local finalKey = keys[#keys]
	current[finalKey] = value
end

--==================================================
-- ROOT-LEVEL SERVER HOP CONTROLLER (SAFE CONTEXT)
--==================================================

task.spawn(function()
	while true do
		task.wait(1)

		if Runtime.Running and Runtime.RequestHop then
			Runtime.RequestHop = false

			Log("Sniper", "ServerHop → Executing")
			SetSniperStatus("Hopping")


			pcall(Hop)
            Runtime.FirstHopDone = true
			-- prevent hop spam
			task.wait(5)
		end
	end
end)


local l_DataStream2_0 = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("DataStream2");
getgenv().UpdateEvent = l_DataStream2_0.OnClientEvent:Connect(function(f, Name, Data)
	if f=="UpdateData" and Name == "Booths" then
    for Index,NewData in pairs(Data) do
        local Path, Data = NewData[1], NewData[2]
        setPathData(Path, Data)
    end

    UpdateTradeWorldDashboard()
    if TradeWorldReady then
    task.defer(function()
        TryTeleportToBooth()
    end)
end

end
end)
Log("DataStream", "Booth updates hooked")
task.spawn(function()
    while not TradeWorldReady do
        task.wait(0.1)
    end

    UpdateTradeWorldDashboard()
end)


if getconnections then
	for _, connection in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
		if connection["Disable"] then
			connection["Disable"](connection)
		elseif connection["Disconnect"] then
			connection["Disconnect"](connection)
		end
	end
else
	game.Players.LocalPlayer.Idled:Connect(function()
		game:GetService("VirtualUser"):CaptureController()
		game:GetService("VirtualUser"):ClickButton2(Vector2.new())
	end)
end
end
