GOON MAIN

-- GOON SNIPER - PUBLIC RELEASE (v3.3)
-- [ADDED] Key System, Delta Support & Auto-Click Loading Screen
local LogoID = "rbxassetid://0" 
local Version = "v3.3"

-- [0] INITIALIZATION
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(2) 
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local Player = Players.LocalPlayer

-- [NEW] DETECT DELTA EXECUTOR
local IsDelta = false
if identifyexecutor and string.find(string.lower(identifyexecutor()), "delta") then
    IsDelta = true
end

local PlayerGui = Player:WaitForChild("PlayerGui", 10)
if not PlayerGui then PlayerGui = Player:WaitForChild("PlayerGui") end

local ConfigFile = "goon_config_dev.json"
local KeyFile = "goon_auth_key.txt" -- Saves the user's key
local WarnFile = "goon_delta_warned.txt" -- Saves that warning was seen
local TradeWorldID = 129954712878723 

-- [1] PET DATABASE
local PetList = {
    "Amethyst Beetle", "Ankylosaurus", "Apple Gazelle", "Archling", "Arctic Fox", "Asteris", "Axolotl", 
    "Bacon Pig", "Badger", "Bagel Bunny", "Bald Eagle", "Barn Owl", "Bat", "Bear Bee", 
    "Bearded Dragon", "Bee", "Black Bunny", "Blood Hedgehog", "Blood Kiwi", "Blood Owl", 
    "Blue Jay", "Bone Dog", "Brontosaurus", "Brown Mouse", "Bunny", "Butterfly", "Camel", 
    "Cape Buffalo", "Capybara", "Cardinal", "Cat", "Caterpillar", "Chicken", "Chicken Zombie", "Chimera",
    "Chimpanzee", "Chipmunk", "Christmas Gorilla", "Chubby Chipmunk", "Cockatrice", 
    "Cocoa Cat", "Cooked Owl", "Corrupted Kitsune", "Corrupted Kodama", "Cow", "Crab", 
    "Crocodile", "Crow", "Dairy Cow", "Dark Spriggan", "Deer", "Diamond Panther", 
    "Dilophosaurus", "Disco Bee", "Dog", "Dragonfly", "Echo Frog", "Eggnog Chick", "Elk", 
    "Emerald Snake", "Faestar", "Farmer Chipmunk", "Fennec Fox", "Festive Frost Squirrel",
    "Festive Ice Golem", "Festive Moose", "Festive Nutcracker", "Festive Partridge", "Festive Reindeer",
    "Festive Santa Bear", "Festive Turtle Dove", "Festive Wendigo", "Flamingo", "Flower Spider", "Football", 
    "Fortune Squirrel", "French Fry Ferret", "French Hen", "Frog", "Frost Dragon", 
    "Frost Squirrel", "Gecko", "Ghost Bear", "Ghostly Bat", "Ghostly Black Cat", "Ghostly Bone Dog", 
    "Ghostly Dark Spriggan", "Ghostly Headless Horseman", "Ghostly Mummy", "Ghostly Scarab", 
    "Ghostly Spider", "Ghostly Tomb Marmot", "Giant Ant", "Gift Rat", "Giraffe", "Glass Cat", "Glass Dog", 
    "Glimmering Sprite", "Gnome", "Goat", "Goblin", "Goblin Miner", "Golden Goose", "Golden Lab", 
    "Gorilla Chef", "Greenbloom Bird", "Grey Mouse", "Griffin", "Grizzly Bear", "Hamster", 
    "Headless Horseman", "Hedgehog", "Hex Serpent", "Hippo", "Honey Bee", "Hotdog Daschund", 
    "Hummingbird", "Hyacinth Macaw", "Hyena", "Hyrax", "Idol Chipmunk", "Iguana", "Iguanodon", 
    "Imp", "Jackalope", "Junkbot", "Kappa", "Kitsune", "Kiwi", "Kodama", "Koi", "Krampus", 
    "Ladybug", "Lemon Lion", "Lich", "Lion", "Lobster Thermidor", "Luminous Sprite", "Mallard", 
    "Mandrake", "Maneki-neko", "Marmot", "Meerkat", "Mimic Octopus", "Mistletoad", "Mizuchi", 
    "Mole", "Monkey", "Moon Cat", "Moss Leopard", "Moth", "Mummy", "Night Owl", "Nihonzaru", 
    "Nutcracker", "Orange Tabby", "Orangutan", "Ostrich", "Owl", "Oxpecker", "Pachycephalosaurus", 
    "Pack Bee", "Pancake Mole", "Panda", "Parasaurolophus", "Peacock", "Penguin", "Petal Bee", 
    "Phoenix", "Pig", "Pixie", "Polar Bear", "Praying Mantis", "Pterodactyl", "Pumpkin Rat", 
    "Queen Bee", "Raccoon", "Raiju", "Rainbow Ankylosaurus", "Rainbow Arctic Fox", "Rainbow Bearded Dragon", 
    "Rainbow Chinchilla", "Rainbow Christmas Gorilla", "Rainbow Clam", "Rainbow Corrupted Kitsune", 
    "Rainbow Dilophosaurus", "Rainbow Elephant", "Rainbow Elk", "Rainbow French Hen", "Rainbow Frost Dragon", 
    "Rainbow Giraffe", "Rainbow Griffin", "Rainbow Hotdog", "Rainbow Hydra", "Rainbow Iguanodon", 
    "Rainbow Krampus", "Rainbow Lobster", "Rainbow Magpie", "Rainbow Mizuchi", "Rainbow Oxpecker", 
    "Rainbow Pachycephalosaurus", "Rainbow Parasaurolophus", "Rainbow Phoenix", "Rainbow Rhino", 
    "Rainbow Shroomie", "Rainbow Snow Bunny", "Rainbow Spinosaurus", "Rainbow Stag Beetle", 
    "Rainbow Zebra", "Rake", "Raptor", "Reaper", "Red Fox", "Red Giant Ant", "Red Panda", 
    "Red-Nosed Reindeer", "Rhino", "Robin", "Rooster", "Ruby Squid", "Salmon", "Sand Snake", 
    "Sapphire Macaw", "Scarab", "Scarlet Macaw", "Sea Otter", "Sea Turtle", "Seagull", "Seal", 
    "Seedling", "Shiba Inu", "Shroomie", "Silver Dragonfly", "Silver Monkey", "Snail", "Snow Bunny", 
    "Snowman Builder", "Snowman Soldier", "Space Squirrel", "Spaghetti Sloth", "Specter", "Spider", 
    "Spinosaurus", "Spotted Deer", "Spriggan", "Squirrel", "Starfish", "Stegosaurus", "Sugar Glider", 
    "Summer Kiwi", "Suncoil", "Sunny-Side Chicken", "Sushi Bear", "Swan", "T-Rex", "Tanchozuru", 
    "Tanuki", "Tarantula Hawk", "Tiger", "Tomb Marmot", "Topaz Snail", "Toucan", "Tree Frog", 
    "Triceratops", "Tsuchinoko", "Turtle", "Verdant Goose", "Verdant Lion", "Verdant Sunlion", 
    "Wasp", "Water Buffalo", "Wendigo", "Wisp", "Wolf", "Woodpecker", "Woody", "Worm", "Yeti", "Zebra"
}
table.sort(PetList)

-- [2] GLOBAL VARIABLES
getgenv().SniperEnabled = false
getgenv().CurrentFilters = {}
getgenv().LastFound = tick()
getgenv().WebhookURL = "https://discord.com/api/webhooks/1453157686467367085/YwXMx09qDmAEnKYk_7KhtvAYWLPYWLc2fynfiGwPxyUoCcIBUwDUZkk9M3_PJ4DBim0w"
getgenv().HopDelay = 60
local SeenListings = {}

-- [3] CONFIGURATION
local function SaveConfig()
    if writefile then
        local data = { 
            Enabled = getgenv().SniperEnabled, 
            Filters = getgenv().CurrentFilters,
            Webhook = getgenv().WebhookURL,
            HopDelay = getgenv().HopDelay
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
        end)
    end
end

-- [4] SNIPER FUNCTIONS
local function GCScan()
    if not getgc then return nil end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if rawget(v, "Booths") and rawget(v, "Players") and rawget(v, "Active") == nil then
                if type(v.Booths) == "table" and type(v.Players) == "table" then return v end
            end
        end
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
    local success, err = pcall(function()
        local Api = "https://games.roblox.com/v1/games/"..TradeWorldID.."/servers/Public?sortOrder=Desc&limit=100"
        local Raw = game:HttpGet(Api)
        local Servers = HttpService:JSONDecode(Raw).data
        for i = #Servers, 2, -1 do local j = math.random(i); Servers[i], Servers[j] = Servers[j], Servers[i] end
        for _, v in pairs(Servers) do
            if v.playing and (v.maxPlayers - v.playing) >= 2 and v.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(TradeWorldID, v.id, Player)
                task.wait(5)
                return
            end
        end
    end)
    if not success then TeleportService:Teleport(TradeWorldID, Player) end
end
local function SendTestWebhook(url)
    if not url or url == "" or not url:find("discord.com/api/webhooks") then
        return false, "Invalid webhook URL"
    end

    local data = {
        embeds = {{
            title = "GOON SNIPER — Webhook Test",
            description = "✅ Webhook connected successfully.\nThis is a test message.",
            color = 65280,
            footer = { text = "GOON SNIPER v3.3" }
        }}
    }

    local request = http_request or request or HttpPost or syn.request
    if not request then
        return false, "Executor does not support HTTP requests"
    end

    local success, err = pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if success then
        return true
    else
        return false, err
    end
end

-- [5] MAIN LOOP
local function MainLoop()
    local DataService 
    pcall(function() DataService = require(ReplicatedStorage.Modules.DataService) end)
    local MyTokens = 0
    if DataService then pcall(function() MyTokens = DataService:GetData().TradeData.Tokens end) end

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

-- [6] UI BUILDER
local function LoadSniperUI()
    if getgenv().GoonGUI then getgenv().GoonGUI:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GoonSniperUI"
    ScreenGui.Parent = PlayerGui
    getgenv().GoonGUI = ScreenGui

    -- Colors
    local NeonGreen = Color3.fromRGB(0, 255, 127)
    local NeonRed = Color3.fromRGB(255, 50, 50)
    local DarkBg = Color3.fromRGB(15, 15, 15)
    local ButtonBg = Color3.fromRGB(20, 20, 20)

    -- [NEW] DELTA WARNING NOTIFICATION (ONCE ONLY)
    if IsDelta then
        local HasSeenWarning = isfile and isfile(WarnFile)
        if not HasSeenWarning then
            if writefile then writefile(WarnFile, "seen") end

            local WarnFrame = Instance.new("Frame")
            WarnFrame.Parent = ScreenGui
            WarnFrame.BackgroundColor3 = NeonRed
            WarnFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
            WarnFrame.Size = UDim2.new(0, 300, 0, 60)
            WarnFrame.ZIndex = 100 
            Instance.new("UICorner", WarnFrame).CornerRadius = UDim.new(0, 8)
            
            local WarnLbl = Instance.new("TextLabel")
            WarnLbl.Parent = WarnFrame
            WarnLbl.Size = UDim2.new(1, -10, 1, -10)
            WarnLbl.Position = UDim2.new(0, 5, 0, 5)
            WarnLbl.BackgroundTransparency = 1
            WarnLbl.Text = "⚠️ DELTA DETECTED ⚠️\nDisable 'Anti-Scam' and 'Verify Teleports'\nin Delta settings or Auto-Hop will fail!"
            WarnLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            WarnLbl.Font = Enum.Font.GothamBold
            WarnLbl.TextSize = 13
            WarnLbl.TextWrapped = true
            WarnLbl.ZIndex = 101
            
            task.delay(15, function() 
                if WarnFrame then WarnFrame:Destroy() end 
            end)
        end
    end

    -- [NEW] CIRCULAR OPEN BUTTON (Hidden by default)
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenButton"
    OpenBtn.Parent = ScreenGui
    OpenBtn.BackgroundColor3 = DarkBg
    OpenBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    OpenBtn.Size = UDim2.new(0, 50, 0, 50)
    OpenBtn.Text = "G"
    OpenBtn.TextColor3 = NeonGreen
    OpenBtn.Font = Enum.Font.GothamBlack
    OpenBtn.TextSize = 32
    OpenBtn.Visible = false -- Hidden initially
    OpenBtn.Active = true; OpenBtn.Draggable = true
    Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0) -- Make it a circle
    local OpenStroke = Instance.new("UIStroke"); OpenStroke.Parent = OpenBtn; OpenStroke.Color = NeonGreen; OpenStroke.Thickness = 2; OpenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- MAIN FRAME
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = DarkBg
    MainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    MainFrame.Size = UDim2.new(0, 450, 0, 400)
    MainFrame.Active = true; MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true 
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke"); MainStroke.Parent = MainFrame; MainStroke.Color = NeonGreen; MainStroke.Thickness = 2.5; MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.Text = "GOON SNIPER"
    Title.TextColor3 = Color3.fromRGB(50, 255, 100)
    Title.Size = UDim2.new(1, -70, 0, 25)
    Title.Position = UDim2.new(0, 15, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBlack
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextSize = 18

    local VerLabel = Instance.new("TextLabel")
    VerLabel.Parent = MainFrame
    VerLabel.Text = Version
    VerLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    VerLabel.Size = UDim2.new(0, 40, 0, 25)
    VerLabel.Position = UDim2.new(1, -75, 0, 10)
    VerLabel.BackgroundTransparency = 1
    VerLabel.Font = Enum.Font.GothamBold
    VerLabel.TextSize = 12
    VerLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- [GEAR / SETTINGS BUTTON]
    local SettingsBtn = Instance.new("TextButton")
    SettingsBtn.Parent = MainFrame
    SettingsBtn.Text = "⚙️" 
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.Position = UDim2.new(1, -110, 0, 10)
    SettingsBtn.Size = UDim2.new(0, 30, 0, 25)
    SettingsBtn.Font = Enum.Font.GothamBold
    SettingsBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    SettingsBtn.TextSize = 18

    -- [MINIMIZE BUTTON LOGIC]
    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = MainFrame
    MinBtn.Text = "-"
    MinBtn.BackgroundTransparency = 1
    MinBtn.Position = UDim2.new(1, -30, 0, 10)
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.TextSize = 20
    
    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        OpenBtn.Visible = true
        OpenBtn.Position = MainFrame.Position 
    end)

    -- [OPEN BUTTON LOGIC]
    OpenBtn.MouseButton1Click:Connect(function()
        OpenBtn.Visible = false
        MainFrame.Visible = true
        MainFrame.Position = OpenBtn.Position 
    end)

    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Parent = MainFrame
    StatusLbl.Text = "STATUS: IDLE"
    StatusLbl.TextColor3 = Color3.fromRGB(150,150,150)
    StatusLbl.Size = UDim2.new(1, -30, 0, 20)
    StatusLbl.Position = UDim2.new(0, 15, 0, 35)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Font = Enum.Font.Code
    StatusLbl.TextSize = 12
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

    local DropdownBtn = Instance.new("TextButton")
    DropdownBtn.Parent = MainFrame
    DropdownBtn.Text = "Select Pet >"
    DropdownBtn.Size = UDim2.new(1, -30, 0, 35)
    DropdownBtn.Position = UDim2.new(0, 15, 0, 65)
    DropdownBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    DropdownBtn.TextColor3 = Color3.fromRGB(200,200,200)
    DropdownBtn.Font = Enum.Font.GothamBold
    DropdownBtn.TextSize = 16 
    Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0,6)

    local DropdownFrame = Instance.new("ScrollingFrame")
    DropdownFrame.Parent = MainFrame
    DropdownFrame.Size = UDim2.new(1, -30, 0, 150)
    DropdownFrame.Position = UDim2.new(0, 15, 0, 100)
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
    DropdownFrame.Visible = false
    DropdownFrame.ZIndex = 10 
    DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, #PetList * 35) 
    DropdownFrame.ScrollBarThickness = 6
    Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0,6)
    
    local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = DropdownFrame
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local WeightBox = Instance.new("TextBox")
    WeightBox.Parent = MainFrame
    WeightBox.Text = "" 
    WeightBox.PlaceholderText = "Min Weight"
    WeightBox.Size = UDim2.new(0.45, 0, 0, 35)
    WeightBox.Position = UDim2.new(0, 15, 0, 110)
    WeightBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    WeightBox.TextColor3 = Color3.fromRGB(255,255,255)
    WeightBox.TextSize = 14
    Instance.new("UICorner", WeightBox).CornerRadius = UDim.new(0,6)

    local PriceBox = Instance.new("TextBox")
    PriceBox.Parent = MainFrame
    PriceBox.Text = "" 
    PriceBox.PlaceholderText = "Max Price"
    PriceBox.Size = UDim2.new(0.45, 0, 0, 35)
    PriceBox.Position = UDim2.new(0.55, -5, 0, 110)
    PriceBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    PriceBox.TextColor3 = Color3.fromRGB(255,255,255)
    PriceBox.TextSize = 14
    Instance.new("UICorner", PriceBox).CornerRadius = UDim.new(0,6)

    local AddBtn = Instance.new("TextButton")
    AddBtn.Parent = MainFrame
    AddBtn.Text = "ADD TARGET"
    AddBtn.Size = UDim2.new(1, -30, 0, 35)
    AddBtn.Position = UDim2.new(0, 15, 0, 155)
    AddBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    AddBtn.Font = Enum.Font.GothamBold
    AddBtn.TextSize = 16
    Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0,6)

    local TargetList = Instance.new("ScrollingFrame")
    TargetList.Parent = MainFrame
    TargetList.Size = UDim2.new(1, -30, 0, 100)
    TargetList.Position = UDim2.new(0, 15, 0, 200)
    TargetList.BackgroundColor3 = Color3.fromRGB(20,20,20)
    TargetList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TargetList.ScrollBarThickness = 6
    Instance.new("UICorner", TargetList).CornerRadius = UDim.new(0,4)
    
    local TargetLayout = Instance.new("UIListLayout"); TargetLayout.Parent = TargetList
    TargetLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TargetLayout.Padding = UDim.new(0, 2)

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = MainFrame
    ToggleBtn.Text = "ACTIVATE SNIPER"
    ToggleBtn.Size = UDim2.new(1, -30, 0, 40)
    ToggleBtn.Position = UDim2.new(0, 15, 0, 310)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    ToggleBtn.TextColor3 = Color3.fromRGB(50,255,100)
    ToggleBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0,6)
    local Stroke = Instance.new("UIStroke"); Stroke.Parent = ToggleBtn; Stroke.Color = Color3.fromRGB(50,255,100); Stroke.Thickness = 1; Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local HopBtn = Instance.new("TextButton")
    HopBtn.Parent = MainFrame
    HopBtn.Text = "FORCE HOP"
    HopBtn.Size = UDim2.new(1, -30, 0, 25)
    HopBtn.Position = UDim2.new(0, 15, 0, 360)
    HopBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    HopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    HopBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", HopBtn).CornerRadius = UDim.new(0,6)

    -- [SETTINGS FRAME OVERLAY]
    local SettingsFrame = Instance.new("Frame")
    SettingsFrame.Parent = MainFrame
    SettingsFrame.Size = UDim2.new(1, 0, 1, 0)
    SettingsFrame.BackgroundColor3 = DarkBg
    SettingsFrame.Visible = false
    SettingsFrame.ZIndex = 20
    Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 8)

    local SettTitle = Instance.new("TextLabel")
    SettTitle.Parent = SettingsFrame
    SettTitle.Text = "ADVANCED OPTIONS"
    SettTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    SettTitle.Size = UDim2.new(1, 0, 0, 40)
    SettTitle.BackgroundTransparency = 1
    SettTitle.Font = Enum.Font.GothamBlack
    SettTitle.TextSize = 18
    SettTitle.ZIndex = 21

    -- Webhook Input
    local WebhookLbl = Instance.new("TextLabel")
    WebhookLbl.Parent = SettingsFrame
    WebhookLbl.Text = "Discord Webhook URL:"
    WebhookLbl.Size = UDim2.new(1, -30, 0, 20)
    WebhookLbl.Position = UDim2.new(0, 15, 0, 50)
    WebhookLbl.TextColor3 = Color3.fromRGB(150,150,150)
    WebhookLbl.BackgroundTransparency = 1
    WebhookLbl.Font = Enum.Font.Gotham
    WebhookLbl.TextXAlignment = Enum.TextXAlignment.Left
    WebhookLbl.ZIndex = 21

    local WebhookBox = Instance.new("TextBox")
    WebhookBox.Parent = SettingsFrame
    WebhookBox.Text = getgenv().WebhookURL or ""
    WebhookBox.PlaceholderText = "Paste Webhook Here..."
    WebhookBox.Size = UDim2.new(1, -30, 0, 35)
    WebhookBox.Position = UDim2.new(0, 15, 0, 75)
    WebhookBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    WebhookBox.TextColor3 = Color3.fromRGB(255,255,255)
    WebhookBox.TextXAlignment = Enum.TextXAlignment.Left
    WebhookBox.TextSize = 12
    WebhookBox.ClipsDescendants = true
    WebhookBox.ZIndex = 21
    Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0,6)

local TestWebhookBtn = Instance.new("TextButton")
TestWebhookBtn.Parent = SettingsFrame
TestWebhookBtn.Text = "TEST WEBHOOK"
TestWebhookBtn.Size = UDim2.new(1, -30, 0, 32)
TestWebhookBtn.Position = UDim2.new(0, 15, 0, 115)
TestWebhookBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TestWebhookBtn.TextColor3 = Color3.fromRGB(0, 255, 127)
TestWebhookBtn.Font = Enum.Font.GothamBold
TestWebhookBtn.TextSize = 14
TestWebhookBtn.ZIndex = 21
Instance.new("UICorner", TestWebhookBtn).CornerRadius = UDim.new(0, 6)
local TestStroke = Instance.new("UIStroke")
TestStroke.Parent = TestWebhookBtn
TestStroke.Color = Color3.fromRGB(0, 255, 127)
TestStroke.Thickness = 1
TestWebhookBtn.MouseButton1Click:Connect(function()
    TestWebhookBtn.Text = "SENDING..."

    local success, msg = SendTestWebhook(WebhookBox.Text)

    if success then
        TestWebhookBtn.Text = "SUCCESS ✓"
        TestWebhookBtn.TextColor3 = Color3.fromRGB(50, 255, 100)
        TestStroke.Color = Color3.fromRGB(50, 255, 100)
    else
        TestWebhookBtn.Text = "FAILED ✗"
        TestWebhookBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        TestStroke.Color = Color3.fromRGB(255, 80, 80)
        warn("[GOON SNIPER] Webhook test failed:", msg)
    end

    task.delay(2, function()
        TestWebhookBtn.Text = "TEST WEBHOOK"
        TestWebhookBtn.TextColor3 = Color3.fromRGB(0, 255, 127)
        TestStroke.Color = Color3.fromRGB(0, 255, 127)
    end)
end)

    -- Hop Delay Input
    local HopLbl = Instance.new("TextLabel")
    HopLbl.Parent = SettingsFrame
    HopLbl.Text = "Server Hop Delay (Seconds):"
    HopLbl.Size = UDim2.new(1, -30, 0, 20)
    HopLbl.Position = UDim2.new(0, 15, 0, 120)
    HopLbl.TextColor3 = Color3.fromRGB(150,150,150)
    HopLbl.BackgroundTransparency = 1
    HopLbl.Font = Enum.Font.Gotham
    HopLbl.TextXAlignment = Enum.TextXAlignment.Left
    HopLbl.ZIndex = 21

    local HopBox = Instance.new("TextBox")
    HopBox.Parent = SettingsFrame
    HopBox.Text = tostring(getgenv().HopDelay)
    HopBox.PlaceholderText = "60"
    HopBox.Size = UDim2.new(1, -30, 0, 35)
    HopBox.Position = UDim2.new(0, 15, 0, 145)
    HopBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    HopBox.TextColor3 = Color3.fromRGB(255,255,255)
    HopBox.TextSize = 14
    HopBox.ZIndex = 21
    Instance.new("UICorner", HopBox).CornerRadius = UDim.new(0,6)

    -- Save/Close Button
    local CloseSettBtn = Instance.new("TextButton")
    CloseSettBtn.Parent = SettingsFrame
    CloseSettBtn.Text = "SAVE & CLOSE"
    CloseSettBtn.Size = UDim2.new(1, -30, 0, 40)
    CloseSettBtn.Position = UDim2.new(0, 15, 1, -55)
    CloseSettBtn.BackgroundColor3 = NeonGreen
    CloseSettBtn.TextColor3 = DarkBg
    CloseSettBtn.Font = Enum.Font.GothamBlack
    CloseSettBtn.TextSize = 16
    CloseSettBtn.ZIndex = 21
    Instance.new("UICorner", CloseSettBtn).CornerRadius = UDim.new(0,6)

    -- Settings Logic
    SettingsBtn.MouseButton1Click:Connect(function()
        SettingsFrame.Visible = true
        WebhookBox.Text = getgenv().WebhookURL
        HopBox.Text = tostring(getgenv().HopDelay)
    end)

    CloseSettBtn.MouseButton1Click:Connect(function()
        getgenv().WebhookURL = WebhookBox.Text
        local delayNum = tonumber(HopBox.Text)
        if delayNum then getgenv().HopDelay = delayNum end
        SaveConfig()
        SettingsFrame.Visible = false
    end)

    -- Logic
    local SelectedPet = nil
    
    local function RefreshList()
        for _,v in pairs(TargetList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        for pet, cfg in pairs(getgenv().CurrentFilters) do
            local Row = Instance.new("Frame"); Row.Parent = TargetList; Row.Size = UDim2.new(1,0,0,35); Row.BackgroundTransparency = 1
            local Lbl = Instance.new("TextLabel"); Lbl.Parent = Row; 
            Lbl.Text = pet.." ("..cfg[1].."kg / $"..cfg[2]..")"; 
            Lbl.Size = UDim2.new(0.8,0,1,0); 
            Lbl.TextColor3 = Color3.fromRGB(200,200,200); 
            Lbl.BackgroundTransparency = 1; Lbl.Font = Enum.Font.Gotham; 
            Lbl.TextSize = 16; 
            Lbl.TextXAlignment = Enum.TextXAlignment.Left; 
            Lbl.Position = UDim2.new(0,5,0,0)
            
            local Del = Instance.new("TextButton"); Del.Parent = Row; Del.Text = "X"; Del.Size = UDim2.new(0.2,0,1,0); Del.Position = UDim2.new(0.8,0,0,0); Del.TextColor3 = Color3.fromRGB(255,50,50); Del.BackgroundTransparency = 1; Del.Font = Enum.Font.GothamBold
            Del.MouseButton1Click:Connect(function() getgenv().CurrentFilters[pet] = nil; RefreshList(); SaveConfig() end)
        end
    end

    for _,p in ipairs(PetList) do
        local b = Instance.new("TextButton"); b.Parent = DropdownFrame; 
        b.Size = UDim2.new(1,0,0,35); 
        b.Text = p; 
        b.BackgroundColor3 = Color3.fromRGB(25,25,25); b.TextColor3 = Color3.fromRGB(255,255,255) 
        b.Font = Enum.Font.Gotham
        b.TextSize = 16 
        b.ZIndex = 11 
        b.MouseButton1Click:Connect(function() SelectedPet = p; DropdownBtn.Text = p; DropdownFrame.Visible = false end)
    end

    DropdownBtn.MouseButton1Click:Connect(function() DropdownFrame.Visible = not DropdownFrame.Visible end)
    AddBtn.MouseButton1Click:Connect(function() 
        if SelectedPet and tonumber(WeightBox.Text) and tonumber(PriceBox.Text) then
            getgenv().CurrentFilters[SelectedPet] = {tonumber(WeightBox.Text), tonumber(PriceBox.Text)}
            RefreshList(); SaveConfig()
        end
    end)

    ToggleBtn.MouseButton1Click:Connect(function()
        getgenv().SniperEnabled = not getgenv().SniperEnabled
        SaveConfig()
        if getgenv().SniperEnabled then
            ToggleBtn.Text = "DEACTIVATE"; ToggleBtn.TextColor3 = Color3.fromRGB(255,50,50); Stroke.Color = Color3.fromRGB(255,50,50); StatusLbl.Text = "STATUS: ACTIVE"
        else
            ToggleBtn.Text = "ACTIVATE SNIPER"; ToggleBtn.TextColor3 = Color3.fromRGB(50,255,100); Stroke.Color = Color3.fromRGB(50,255,100); StatusLbl.Text = "STATUS: IDLE"
        end
    end)
    HopBtn.MouseButton1Click:Connect(Hop)

    RefreshList()
    if getgenv().SniperEnabled then 
        ToggleBtn.Text = "DEACTIVATE"; ToggleBtn.TextColor3 = Color3.fromRGB(255,50,50); Stroke.Color = Color3.fromRGB(255,50,50); StatusLbl.Text = "STATUS: AUTO-RESUMED"
    end
    
    task.spawn(function()
        while true do
            task.wait()
            if getgenv().SniperEnabled then
                if game.PlaceId ~= TradeWorldID then
                    StatusLbl.TextColor3 = Color3.fromRGB(255, 200, 50) -- Orange warning color
                    local Aborted = false
                    for i = 60, 1, -1 do
                        if not getgenv().SniperEnabled then Aborted = true; break end
                        StatusLbl.Text = "TELEPORTING IN " .. i .. "s..."
                        task.wait(1)
                    end
                    if not Aborted and getgenv().SniperEnabled then
                        StatusLbl.Text = "TELEPORTING..."
                        TeleportService:Teleport(TradeWorldID, Player)
                        task.wait(10) 
                    elseif Aborted then
                        StatusLbl.Text = "STATUS: IDLE"; StatusLbl.TextColor3 = Color3.fromRGB(150,150,150)
                    end
                else
                    pcall(MainLoop)
                    -- [HOP DELAY LOGIC]
                    local delay = getgenv().HopDelay or 60
                    if tick() - getgenv().LastFound > delay then
                        StatusLbl.Text = "SERVER DRY - HOPPING..."
                        Hop()
                        getgenv().LastFound = tick() + delay
                    end
                end
            end
        end
    end)
    
    -- [UPDATED] Auto Close Loading Logic (Aggressive)
    task.spawn(function()
        -- 1. FORCE CLICKER: Runs immediately on startup to dismiss overlays
        task.wait(3) -- Wait for initial load
        for i = 1, 3 do
            pcall(function()
                local Viewport = workspace.CurrentCamera.ViewportSize
                VirtualInputManager:SendMouseButtonEvent(Viewport.X/2, Viewport.Y/2, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(Viewport.X/2, Viewport.Y/2, 0, false, game, 1)
            end)
            task.wait(1)
        end

        -- 2. PASSIVE LISTENER: Checks for "loading" GUIs constantly
        while true do
            task.wait(0.5)
            pcall(function()
                local PGui = Player:WaitForChild("PlayerGui", 5)
                if not PGui then return end
                local FoundLoading = false
                for _, g in pairs(PGui:GetChildren()) do
                    if g:IsA("ScreenGui") and g.Enabled then
                        local name = g.Name:lower()
                        -- Detects "Loading" bars or "Intro" screens
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
end

-- [7] KEY AUTHENTICATION
local function StartAuthentication()
    -- >>> SETUP: REPLACE THIS LINK WITH YOUR GITHUB RAW LINK <<<
    local KeyListURL = "https://raw.githubusercontent.com/visualaiinfo-hue/goonbot/main/keys.json" 
    
    -- >>> TESTING: ADD KEYS HERE FOR LOCAL TESTING <<<
    local DevKeys = {"TEST-KEY-123"} 
    
    -- HELPER: VALIDATE KEY FUNCTION
    local function ValidateKey(input)
        -- 1. Check Local Dev Keys
        for _, k in pairs(DevKeys) do
            if input == k then return true end
        end
        -- 2. Check Web Keys
        local success, result = pcall(function()
            local content = game:HttpGet(KeyListURL)
            local keys = HttpService:JSONDecode(content)
            for _, k in pairs(keys) do
                if input == k then return true end
            end
            return false
        end)
        
        if success and result == true then return true end
        return false
    end

    -- [FIX] AUTO-LOGIN LOGIC
    if isfile and isfile(KeyFile) then
        local SavedKey = readfile(KeyFile)
        if ValidateKey(SavedKey) then
            LoadSniperUI() -- Key is good, load main script
            return -- Stop here, do not create Auth UI
        end
    end

    -- IF WE ARE HERE, NO VALID KEY WAS FOUND. BUILD UI.
    if getgenv().AuthGui then getgenv().AuthGui:Destroy() end
    local AuthGui = Instance.new("ScreenGui")
    AuthGui.Name = "GoonAuth"
    AuthGui.Parent = PlayerGui
    getgenv().AuthGui = AuthGui

    local Frame = Instance.new("Frame")
    Frame.Parent = AuthGui
    Frame.Size = UDim2.new(0, 300, 0, 150)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke"); Stroke.Parent = Frame; Stroke.Color = Color3.fromRGB(0, 255, 127); Stroke.Thickness = 2
    
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
    KeyBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    KeyBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    KeyBox.TextColor3 = Color3.fromRGB(255,255,255)
    KeyBox.PlaceholderText = "Enter Key..."
    KeyBox.TextSize = 14
    Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0,6)

    -- Pre-fill key if it exists (even if invalid, so user can edit it)
    if isfile and isfile(KeyFile) then
        KeyBox.Text = readfile(KeyFile)
    end

    local LoginBtn = Instance.new("TextButton")
    LoginBtn.Parent = Frame
    LoginBtn.Text = "LOGIN"
    LoginBtn.Size = UDim2.new(0.8, 0, 0, 35)
    LoginBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
    LoginBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
    LoginBtn.TextColor3 = Color3.fromRGB(15,15,15)
    LoginBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", LoginBtn).CornerRadius = UDim.new(0,6)

    LoginBtn.MouseButton1Click:Connect(function()
        LoginBtn.Text = "CHECKING..."
        if ValidateKey(KeyBox.Text) then
            if writefile then writefile(KeyFile, KeyBox.Text) end
            AuthGui:Destroy()
            LoadSniperUI() -- START MAIN UI
        else
            LoginBtn.Text = "INVALID KEY"
            task.wait(1)
            LoginBtn.Text = "LOGIN"
        end
    end)
end

-- [8] START
LoadData()
LoadConfig()
StartAuthentication()
