-- GOON SNIPER - PUBLIC RELEASE (v4.9 - VOLCANO FIX)
-- [FIX] Added Retry Logic to GCScan (Fixes "Fallback Listener" issue on Volcano)
-- [FIX] Replaced hardcoded list with Dynamic Scanner (Auto-updates with game)
-- [NEW] Added "Remove ALL Filters" button to Filter Manager
-- UI Framework: Obsidian

local Version = "v4.9"

-- [0] INITIALIZATION
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(2) 
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local GuiService = game:GetService("GuiService") 
local Player = Players.LocalPlayer

-- [NEW] DETECT DELTA EXECUTOR
local IsDelta = false
if identifyexecutor and string.find(string.lower(identifyexecutor()), "delta") then
    IsDelta = true
end

local PlayerGui = Player:WaitForChild("PlayerGui", 10)
if not PlayerGui then PlayerGui = Player:WaitForChild("PlayerGui") end

local ConfigFile = "goon_config_dev.json"
local KeyFile = "goon_auth_key.txt" 
local WarnFile = "goon_delta_warned.txt" 
local TradeWorldID = 129954712878723 

-- [NEW] TELEPORT ERROR HANDLER (Anti-Stuck Logic)
TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
    if player == Player then
        warn("⚠️ [GOON SNIPER] Teleport Failed ("..tostring(result).."). Retrying...")
        pcall(function() GuiService:ClearError() end)
        pcall(function()
            local Viewport = workspace.CurrentCamera.ViewportSize
            VirtualInputManager:SendMouseButtonEvent(Viewport.X/2, Viewport.Y/2 + 50, 0, true, game, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(Viewport.X/2, Viewport.Y/2 + 50, 0, false, game, 1)
        end)
        task.wait(1.5)
        if getgenv().ForceHop then getgenv().ForceHop() end
    end
end)

-- [1] PET DATABASE (DYNAMIC SCANNER)
local PetList = {}

local function RefreshPetList()
    table.clear(PetList)
    
    local Success, Result = pcall(function()
        
        -- [[ 🔴 PASTE PATH FROM DEX HERE ]] --
        -- Replace the line below with the path you copied from Dex
        local ModulePath = game:GetService("ReplicatedStorage").Data.PetRegistry.PetList
    
        local Data = require(ModulePath)

        -- Smart Scanner: Detects format automatically
        for Key, Value in pairs(Data) do
            if type(Key) == "string" then
                -- Case A: Key is the name (["Void Dragon"] = {...})
                table.insert(PetList, Key)
            elseif type(Value) == "string" then
                -- Case B: Value is the name ("Void Dragon", "Cat")
                table.insert(PetList, Value)
            elseif type(Value) == "table" and Value.Name then
                -- Case C: Name is inside property ({Name = "Void Dragon"})
                table.insert(PetList, Value.Name)
            end
        end
    end)

    if not Success then
        warn("⚠️ [GOON SNIPER] Scanner Failed! Check the path on line 44.")
        warn("Error: " .. tostring(Result))
        
        -- Fallback: Manual list just in case scanner fails
        PetList = {"Dragon", "Cat", "Dog", "Void Dragon"} 
    end

    table.sort(PetList)
    print("✅ [GOON SNIPER] Database Loaded: " .. #PetList .. " pets found.")
end

-- Run scanner immediately
RefreshPetList()


-- [2] GLOBAL VARIABLES
getgenv().SniperEnabled = false
getgenv().CurrentFilters = {}
getgenv().LastFound = tick()
getgenv().WebhookURL = "https://discord.com/api/webhooks/1453157686467367085/YwXMx09qDmAEnKYk_7KhtvAYWLPYWLc2fynfiGwPxyUoCcIBUwDUZkk9M3_PJ4DBim0w"
getgenv().HopDelay = 60
getgenv().AutoShowUI = true 
getgenv().AutoHopEnabled = true 
local SeenListings = {}

-- Variables for Pagination
getgenv().WatchlistPage = 1
local ItemsPerPage = 10 

-- [3] CONFIGURATION
local function SaveConfig()
    if writefile then
        local data = { 
            Enabled = getgenv().SniperEnabled, 
            Filters = getgenv().CurrentFilters,
            Webhook = getgenv().WebhookURL,
            HopDelay = getgenv().HopDelay,
            AutoShow = getgenv().AutoShowUI,
            AutoHop = getgenv().AutoHopEnabled
        }
       writefile(ConfigFile, HttpService:JSONEncode(data))
    end
end

local function LoadConfig()
    if isfile and isfile(ConfigFile) then
        pcall(function()
            local result = HttpService:JSONDecode(readfile(ConfigFile))
            getgenv().SniperEnabled = result.Enabled
            getgenv().CurrentFilters = result.Filters or {}
            if result.Webhook and result.Webhook ~= "" then getgenv().WebhookURL = result.Webhook end
            if result.HopDelay then getgenv().HopDelay = tonumber(result.HopDelay) end
            if result.AutoShow ~= nil then getgenv().AutoShowUI = result.AutoShow end
            if result.AutoHop ~= nil then getgenv().AutoHopEnabled = result.AutoHop end 
        end)
    end
end

-- [4] SNIPER FUNCTIONS

-- [UPDATED GCScan] Added retry loop for Volcano/Slower Executors
local function GCScan()
    if not getgc then return nil end
    print("⏳ [GOON SNIPER] Scanning memory... (This may take a moment)")
    
    -- Try to find the table 10 times (10 seconds max)
    for i = 1, 10 do
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "Booths") and rawget(v, "Players") and rawget(v, "Active") == nil then
                    if type(v.Booths) == "table" and type(v.Players) == "table" then 
                        return v 
                    end
                end
            end
        end
        task.wait(1) -- Wait 1s before trying again
    end
    return nil
end

local function LoadData()
    local liveData = GCScan()
    if liveData then
        print("✅ [GOON SNIPER] Data Source: Direct Memory Scan (GC)")
        getgenv().boothData = liveData
    else
        print("⚠️ [GOON SNIPER] Data Source: Fallback Listener (DataStream2)")
        getgenv().boothData = {Booths = {}, Players = {}}
        local l_DataStream2_0 = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DataStream2")
    
        if getgenv().UpdateEvent then getgenv().UpdateEvent:Disconnect() end
        getgenv().UpdateEvent = l_DataStream2_0.OnClientEvent:Connect(function(f, Name, Data)
            if f=="UpdateData" and Name == "Booths" then end
        end)
    end
end

local function Sniped(PetName, Weight, Price)
    local function FormatPrice(n)
        return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end
    local Embed_Data = {
        description="\n🕙 **Sniped At**: <t:"..math.floor(tick())..":R>\n-# account: ||"..Player.Name.."||",
        color=65280, 
        author={name=`GOON SNIPER: Got {PetName}({math.floor(Weight*100)/100}kg) for {FormatPrice(Price)}`}
    }
  
    local newData = HttpService:JSONEncode({embeds={Embed_Data}})
    local request = http_request or request or HttpPost or syn.request
    
    local url = getgenv().WebhookURL
    if url and url ~= "" and url:find("http") then
        request({Url = url, Body = newData, Method = "POST", Headers = {["content-type"] = "application/json"}})
    end
end

local function Hop()
    SaveConfig() 
    local success, err = pcall(function()
        local Api = "https://games.roblox.com/v1/games/"..TradeWorldID.."/servers/Public?sortOrder=Desc&limit=100"
        local Raw = game:HttpGet(Api)
        local Servers = HttpService:JSONDecode(Raw).data
        for i = #Servers, 2, -1 do local j = math.random(i);
            Servers[i], Servers[j] = Servers[j], Servers[i] end
        
        for _, v in pairs(Servers) do
            if v.playing and (v.maxPlayers - v.playing) >= 2 and v.id ~= game.JobId then
                print("🚀 [GOON SNIPER] Hopping to server with " .. (v.maxPlayers - v.playing) .. " slots...")
                TeleportService:TeleportToPlaceInstance(TradeWorldID, v.id, Player)
                task.wait(5)
                return
            end
        end
    end)
    if not success then TeleportService:Teleport(TradeWorldID, Player) end
end
getgenv().ForceHop = Hop 

-- [5] MAIN LOOP
local function MainLoop()
    local DataService 
    pcall(function() DataService = require(ReplicatedStorage.Modules.DataService) end)
    local MyTokens = 0
    if DataService then 
        pcall(function() MyTokens = DataService:GetData().TradeData.Tokens end) end

    local Data = getgenv().boothData
    if not Data or not Data.Booths then return end 

    for BoothId, BoothData in pairs(Data.Booths) do
        if not getgenv().SniperEnabled then break end

        local Owner = BoothData.Owner
        if Owner and Data.Players[Owner] and Data.Players[Owner].Listings then
            local realPlayer = nil
            for _, Plr in pairs(Players:GetChildren()) do
                if Plr.UserId == tonumber(string.split(Owner, "_")[2]) then realPlayer = Plr break end
            end
            
            for ListingId, ListingData in pairs(Data.Players[Owner].Listings) do
                if not getgenv().SniperEnabled then break end
        
                if ListingData.ItemType == "Pet" then
                    local ItemData = Data.Players[Owner].Items[ListingData.ItemId]
                    if ItemData then
                        local Type = ItemData.PetType
                        local PetData = ItemData.PetData
                        local Price = ListingData.Price
                        local Weight = PetData.BaseWeight * 1.1
                        local MaxWeight = Weight * 10
                        local Settings = getgenv().CurrentFilters[Type]
                        
                        if Settings then
                            local MinW = Settings[1] or 0
                            local MaxP = Settings[2] or 9999999
                        
                            if not SeenListings[ListingId] then
                                print("🔎 FOUND:", Type, "| Price:", Price, "| Weight:", math.floor(MaxWeight).."kg")
                                SeenListings[ListingId] = true
                            end
                            
                            if MaxWeight >= MinW and Price <= MaxP and realPlayer ~= Player then
                                if Price <= MyTokens then
                                    if getgenv().SniperEnabled then
                                        local X,Y = ReplicatedStorage.GameEvents.TradeEvents.Booths.BuyListing:InvokeServer(realPlayer, ListingId)
                                        if X then
                                            Sniped(Type, MaxWeight, Price)
                                            task.wait(5)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- [6] OBSIDIAN UI BUILDER
local function LoadObsidianUI()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    local Window = Library:CreateWindow({
        Title = "GOON SNIPER " .. Version,
        Footer = "Obsidian UI Edition",
        Icon = "target",
        Center = true,
        AutoShow = getgenv().AutoShowUI 
    })

    local Tabs = {
        Main = Window:AddTab("Main", "rocket"),
        Settings = Window:AddTab("Settings", "settings"),
    }

    -- [LEFT] SNIPER CONTROL
    local SniperBox = Tabs.Main:AddLeftGroupbox("Sniper Control", "crosshair")

    SniperBox:AddToggle("EnableSniper", {
        Text = "Enable Booth Sniper",
        Default = getgenv().SniperEnabled,
        Callback = function(v)
           getgenv().SniperEnabled = v
            SaveConfig()
        end
    })

    SniperBox:AddToggle("AutoHop", {
        Text = "Auto Server Hop",
        Default = getgenv().AutoHopEnabled,
        Tooltip = "If enabled, will automatically hop servers after the hop delay.",
        Callback = function(v)
            getgenv().AutoHopEnabled = v
            SaveConfig()
        end
    })

    SniperBox:AddButton("Force Hop", function()
        Hop()
    end)

    local StatusLabel = SniperBox:AddLabel("Status: IDLE")

    -- [LEFT] ACTIVE WATCHLIST
    local WatchlistBox = Tabs.Main:AddLeftGroupbox("Active Watchlist", "list")
    
    local PageLabel = WatchlistBox:AddLabel("Page 1/1")
    WatchlistBox:AddDivider()
    
    local WatchlistSlots = {}
    for i = 1, ItemsPerPage do
        WatchlistSlots[i] = WatchlistBox:AddLabel(" ") 
    end
    
    WatchlistBox:AddButton("Previous Page", function()
        if getgenv().WatchlistPage > 1 then
             getgenv().WatchlistPage = getgenv().WatchlistPage - 1
            getgenv().UpdateWatchlistFunc()
        end
    end)
    
    WatchlistBox:AddButton("Next Page", function()
        getgenv().WatchlistPage = getgenv().WatchlistPage + 1
        getgenv().UpdateWatchlistFunc()
    end)

    local DevBox = Tabs.Settings:AddRightGroupbox("Developer Tools", "wrench")
    DevBox:AddButton("Open Dex Explorer", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()
    end)

    getgenv().UpdateWatchlistFunc = function()
        local allFilters = {}
        for pet, settings in pairs(getgenv().CurrentFilters) do
            table.insert(allFilters, {Name = pet, Min = settings[1], Max = settings[2]})
        end
        
        table.sort(allFilters, function(a,b) return a.Name < b.Name end)
        
        local totalItems = #allFilters
        local maxPages = math.ceil(totalItems / ItemsPerPage)
        if maxPages == 0 then maxPages = 1 end
        
        if getgenv().WatchlistPage > maxPages then getgenv().WatchlistPage = maxPages end
        if getgenv().WatchlistPage < 1 then getgenv().WatchlistPage = 1 end
        
        PageLabel:SetText("Page " .. getgenv().WatchlistPage .. "/" .. maxPages)
        local startIndex = (getgenv().WatchlistPage - 1) * ItemsPerPage + 1
        
        for i = 1, ItemsPerPage do
            local itemIndex = startIndex + (i - 1)
            local item = allFilters[itemIndex]
            if item then
                 local minW = item.Min or 0
                 local maxP = item.Max or "ANY"
                 WatchlistSlots[i]:SetText("• " .. item.Name .. " (" .. minW .. "kg | $" .. maxP .. ")")
            else
                 WatchlistSlots[i]:SetText(" ") 
            end
        end
    end

    -- [RIGHT] PET FILTER MANAGER
    local FilterBox = Tabs.Main:AddRightGroupbox("Filter Manager", "filter")

    local ValPet = PetList[1]
    local ValWeight = 0
    local ValPrice = 999999999

    FilterBox:AddDropdown("PetSelector", {
        Text = "Select Pet",
        Values = PetList,
        Default = 1,
        Multi = false,
        Searchable = true,
        Callback = function(v)
            ValPet = v
        end
    })

    FilterBox:AddInput("MinKG", {
        Text = "Min Weight (kg)",
        Default = "",
        Placeholder = "e.g. 60",
        Numeric = true,
        Finished = false,
        Callback = function(v)
            ValWeight = tonumber(v) or 0
        end
    })

    FilterBox:AddInput("MaxPrice", {
        Text = "Max Price",
        Default = "",
        Placeholder = "e.g. 5000",
        Numeric = true,
        Finished = false, 
        Callback = function(v)
            ValPrice = tonumber(v) or 999999999
        end
    })
    
    local ActiveBox = Tabs.Main:AddRightGroupbox("Manage Filters", "list")
    local function GetActiveFilterNames()
        local list = {}
        for k, v in pairs(getgenv().CurrentFilters) do table.insert(list, k) end
        table.sort(list)
        return list
    end
    
    local RemoveDropdown = ActiveBox:AddDropdown("RemoveSelector", {
        Text = "Select to Remove",
        Values = GetActiveFilterNames(),
        Multi = false,
        Searchable = true,
    })

    FilterBox:AddButton("Add / Update Filter", function()
        if ValPet then
            getgenv().CurrentFilters[ValPet] = {ValWeight, ValPrice}
            Library:Notify("✅ Added: " .. ValPet .. " | " .. ValWeight .. "kg | $" .. ValPrice, 4)
            SaveConfig()
            RemoveDropdown:SetValues(GetActiveFilterNames())
            RemoveDropdown:SetValue(nil)
            getgenv().UpdateWatchlistFunc() 
        else
            Library:Notify("⚠️ Error: No pet selected", 3)
        end
    end)

    ActiveBox:AddButton("Remove Selected", function()
        local val = RemoveDropdown.Value
        if val and getgenv().CurrentFilters[val] then
            getgenv().CurrentFilters[val] = nil
            Library:Notify("Removed " .. val, 3)
            RemoveDropdown:SetValues(GetActiveFilterNames())
            RemoveDropdown:SetValue(nil)
            SaveConfig()
            getgenv().UpdateWatchlistFunc() 
        end
    end)
    
    -- [NEW] BUTTON TO REMOVE ALL
    ActiveBox:AddButton("Remove ALL Filters", function()
        getgenv().CurrentFilters = {}
        SaveConfig()
        Library:Notify("🗑️ All filters have been cleared!", 3)
        RemoveDropdown:SetValues(GetActiveFilterNames())
        RemoveDropdown:SetValue(nil)
        getgenv().UpdateWatchlistFunc()
    end)
    
    ActiveBox:AddButton("Refresh List", function()
         RemoveDropdown:SetValues(GetActiveFilterNames())
         getgenv().UpdateWatchlistFunc()
    end)

    -- [SETTINGS TAB]
    local SettingsBox = Tabs.Settings:AddLeftGroupbox("Configuration", "database")

    SettingsBox:AddToggle("AutoShowSetting", {
        Text = "Auto-Show UI on Launch",
        Default = getgenv().AutoShowUI,
        Tooltip = "If disabled, UI stays hidden when server hopping (Press RightCtrl to open)",
        Callback = function(v)
            getgenv().AutoShowUI = v
            SaveConfig()
        end
    })
    
    SettingsBox:AddInput("Webhook", {
        Text = "Discord Webhook",
        Default = getgenv().WebhookURL or "",
        Placeholder = "https://discord.com/...",
        Finished = false, 
        Callback = function(v)
            getgenv().WebhookURL = v
        end
    })

    SettingsBox:AddInput("HopDelay", {
        Text = "Hop Delay (Seconds)",
        Default = tostring(getgenv().HopDelay),
        Numeric = true,
        Finished = false, 
        Callback = function(v)
            getgenv().HopDelay = tonumber(v) or 60
        end
    })

    SettingsBox:AddButton("Save Config Manually", function()
        SaveConfig()
        Library:Notify("Configuration Saved!", 3)
    end)

    if IsDelta then
        local HasSeenWarning = isfile and isfile(WarnFile)
        if not HasSeenWarning then
            if writefile then writefile(WarnFile, "seen") end
            Library:Notify("⚠️ DELTA DETECTED: Disable 'Anti-Scam' & 'Verify Teleports' in Delta settings!", 10)
        end
    end

    getgenv().UpdateWatchlistFunc()

    -- STATUS UPDATE LOOP
    task.spawn(function()
        while true do
            task.wait(1)
            if getgenv().SniperEnabled then
                if game.PlaceId ~= TradeWorldID then
                    StatusLabel:SetText("Status: TELEPORTING...")
                    for i = 10, 1, -1 do
                        if not getgenv().SniperEnabled then break end
                        StatusLabel:SetText("Status: Teleporting in " .. i .. "s")
                        task.wait(1)
                    end
      
                    if getgenv().SniperEnabled then
                        TeleportService:Teleport(TradeWorldID, Player)
                        task.wait(10)
                    else
                        StatusLabel:SetText("Status: IDLE")
                    end
            
                else
                    pcall(MainLoop)
                    local delay = getgenv().HopDelay or 60
                    if tick() - getgenv().LastFound > delay then
                         if getgenv().AutoHopEnabled then
                             StatusLabel:SetText("Status: HOPPING (Server Dry)")
                             Hop()
                             getgenv().LastFound = tick() + delay
                        else
                             StatusLabel:SetText("Status: SCANNING (Auto-Hop Disabled)")
                        end
                    else
                        StatusLabel:SetText("Status: SCANNING... (" .. math.floor(delay - (tick() - getgenv().LastFound)) .. "s)")
                    end
                end
            else
                StatusLabel:SetText("Status: IDLE")
             end
        end
    end)
   
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local PGui = Player:WaitForChild("PlayerGui", 5)
                if not PGui then return end
                local FoundLoading = false
                for _, g in pairs(PGui:GetChildren()) do
                    if g:IsA("ScreenGui") and g.Enabled then
                        local name = g.Name:lower()
                        if name:find("loading") or name:find("intro") then FoundLoading = true end
                    end
                end
                if FoundLoading then
                    local Viewport = workspace.CurrentCamera.ViewportSize
                    VirtualInputManager:SendMouseButtonEvent(Viewport.X/2, Viewport.Y/2, 0, true, game, 1)
                    task.wait(0.1)
                    VirtualInputManager:SendMouseButtonEvent(Viewport.X/2, Viewport.Y/2, 0, false, game, 1)
                end
            end)
        end
    end)
    
    Library:Notify("Loaded Successfully!", 5)
end

-- [7] KEY AUTHENTICATION
local function StartAuthentication()
    local AuthURL = "https://script.google.com/macros/s/AKfycby5mTLL3T5JINUNIxnabGYFJ7rJP8AsQnDFOWdCPM_ZMQbverIf9mRI0TpEzbc6RJc1/exec" 
    
    local function GetHWID()
        if gethwid then return gethwid() end
        if syn and syn.request then return game:GetService("RbxAnalyticsService"):GetClientId() end
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end

    local function ValidateKey(inputKey)
        if inputKey == "" then return false end
        local userHWID = GetHWID()
        local requestUrl = AuthURL .. "?key=" .. inputKey .. "&hwid=" .. userHWID
        local success, response = pcall(function() return game:HttpGet(requestUrl) end)
        if success then
            local status = string.gsub(response, "%s+", "")
            if status == "AUTHORIZED" or status == "AUTHORIZED_LINKED" then return true
            elseif status == "HWID_MISMATCH" then return "HWID_MISMATCH"
            elseif status == "INVALID_KEY" then return false end
        end
        return false
    end

    if isfile and isfile(KeyFile) then
        local SavedKey = readfile(KeyFile)
        local status = ValidateKey(SavedKey)
        if status == true then LoadObsidianUI() return end
    end

    if getgenv().AuthGui then getgenv().AuthGui:Destroy() end
  
    local AuthGui = Instance.new("ScreenGui")
    AuthGui.Name = "GoonAuth"
    AuthGui.Parent = PlayerGui
    getgenv().AuthGui = AuthGui

    local Frame = Instance.new("Frame")
    Frame.Parent = AuthGui
    Frame.Size = UDim2.new(0, 300, 0, 160)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -80)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke");
    Stroke.Parent = Frame; Stroke.Color = Color3.fromRGB(0, 255, 127); Stroke.Thickness = 2
    
    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Text = "AUTHENTICATION"
    Title.TextColor3 = Color3.fromRGB(0, 255, 127)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 18

    local KeyBox = Instance.new("TextBox")
    KeyBox.Parent = Frame
    KeyBox.Size = UDim2.new(0.8, 0, 0, 35)
    KeyBox.Position = UDim2.new(0.1, 0, 0.25, 0)
    KeyBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    KeyBox.TextColor3 = Color3.fromRGB(255,255,255)
    KeyBox.PlaceholderText = "Enter Key..."
    KeyBox.TextSize = 14
    Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0,6)

    if isfile and isfile(KeyFile) then KeyBox.Text = readfile(KeyFile) end

    local LoginBtn = Instance.new("TextButton")
    LoginBtn.Parent = Frame
    LoginBtn.Text = "LOGIN"
    LoginBtn.Size = UDim2.new(0.8, 0, 0, 35)
    LoginBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
    LoginBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
    LoginBtn.TextColor3 = Color3.fromRGB(15,15,15)
    LoginBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", LoginBtn).CornerRadius = UDim.new(0,6)

    local StatusText = Instance.new("TextLabel")
    StatusText.Parent = Frame
    StatusText.Text = ""
    StatusText.Size = UDim2.new(1, 0, 0, 20)
    StatusText.Position = UDim2.new(0, 0, 0.85, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12

    LoginBtn.MouseButton1Click:Connect(function()
        LoginBtn.Text = "CHECKING..."
        StatusText.Text = ""
        local result = ValidateKey(KeyBox.Text)
        if result == true then
            if writefile then writefile(KeyFile, KeyBox.Text) end
            AuthGui:Destroy()
            LoadObsidianUI()
        elseif result == "HWID_MISMATCH" then
            LoginBtn.Text = "LOGIN FAILED"
            StatusText.Text = "Key linked to another device!"
            task.wait(2)
            LoginBtn.Text = "LOGIN"
        else
            LoginBtn.Text = "INVALID KEY"
            StatusText.Text = "Key does not exist."
            task.wait(2)
            LoginBtn.Text = "LOGIN"
        end
    end)
end

-- [8] START
LoadData()
LoadConfig()
StartAuthentication()
