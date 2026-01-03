--==================================================
-- GOONS — Obsidian Clean Base
-- Purpose: Minimal, stable foundation
--==================================================

--==================================================
-- BOOTSTRAP [1]
--==================================================
if not game:IsLoaded() then
    game.Loaded:Wait()
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
    Title = "Goons",
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


local function SetSniperStatus(state)
	if not SniperStatusLabel then return end

	local map = {
		OFF = '<font color="rgb(200,200,200)">OFF</font>',
		Starting = '<font color="rgb(255,200,100)">⏳ Starting</font>',
		Scanning = '<font color="rgb(120,200,255)">🔍 Scanning</font>',
		Hopping = '<font color="rgb(255,120,120)">🌍 Hopping</font>',
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
			'📦 <font color="rgb(160,220,160)">Scanned:</font> <b>%d</b>',
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

local function TeleportToTradingWorld()
	if game.PlaceId == TRADING_WORLD_PLACE_ID then
		return -- already there
	end

	print("[Sniper] Teleporting to Trading World in", AUTO_TELEPORT_DELAY, "seconds")

	task.wait(AUTO_TELEPORT_DELAY)

	-- Sniper might have been disabled during delay
	if not Runtime.Running then
		print("[Sniper] Teleport cancelled (sniper disabled)")
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
			pcall(MainLoop)
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
	SetSniperStatus("OFF")
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
-- SAVE MANAGER SETUP (OBSIDIAN CORRECT) [7]
--==================================================

SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

SaveManager:SetFolder("Goons")

SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

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
	print("Init_ServerHop")
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
	print("InitBoothData")
	getgenv().boothData = getupvalues(Controller.GetPlayerBoothData)[2]:GetDataAsync()
	print("INIT!")
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

function MainLoop()
	local Listings = getAllListings()
		-- update scan counter
	SetScanCount(#Listings)
    Runtime.MatchedCount = 0

if ShouldHop(Listings) then
	print("[Sniper] No viable targets, requesting hop")
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

		print("ATTEMPTBUY:", success)

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

			print("[Sniper] Executing server hop (root thread)")
			SetSniperStatus("Hopping")


			pcall(Hop)

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
	end
end)
print("UpdateEvent Hooked")

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
