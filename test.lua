-- GROW A GARDEN BOOTH SNIPER - WORKING VERSION (UI CONTROLLED)

-- =========================
-- GLOBAL CONTROL
-- =========================
getgenv().PetSniperEnabled = false
getgenv().PetSniperThread = nil

-- =========================
-- FILTERS
-- =========================
local Filters = {
	["Koi"] = {23, 50},
	["Mimic Octopus"] = {63.2, 1000},
	["Peacock"] = {62, 1000},
	["Raccoon"] = {0, 300},
	["Kitsune"] = {0, 500},
	["Rainbow Dilophosaurus"] = {0, 50000},

	-- Gourmet Egg
	["French Fry Ferret"] = {0,2},
	["Pancake Mole"] = {0,2},
	["Sushi Bear"] = {0,2},
	["Spaghetti Sloth"] = {0,2},
	["Bagel Bunny"] = {0,2},

	-- Night Egg
	["Frog"] = {0,2},
	["Mole"] = {0,2},
	["Echo Frog"] = {0,2},

	-- Zen Egg
	["Shiba Inu"] = {0,2},
	["Nihonzaru"] = {0,2},
	["Tanuki"] = {0,2},
	["Tanchozuru"] = {0,2},
	["Kappa"] = {0,2},

	-- Paradise Egg
	["Ostrich"] = {0,2},
	["Capybara"] = {0,2},
	["Scarlet Macaw"] = {0,2},

	-- Anti-Bee Egg
	["Wasp"] = {0,2},
	["Tarantula Hawk"] = {0,2},
	["Moth"] = {0,2},
	["Butterfly"] = {0,2},
	["Disco Bee"] = {0,2},

	-- Bee Egg
	["Bee"] = {0,2},
	["Honey Bee"] = {0,2},
	["Bear Bee"] = {0,2},
	["Petal Bee"] = {0,2},
	["Queen Bee"] = {0,2}
}

-- =========================
-- GAME LOAD
-- =========================
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
repeat task.wait() until Players.LocalPlayer
local player = Players.LocalPlayer

-- =========================
-- SERVER HOP
-- =========================
local SnipeLoop = math.random(1000,9999)
getgenv().SnipeLoop = SnipeLoop

local function Hop()
	local Servers = {}

	local function Scrape()
		local URL = "https://games.roblox.com/v1/games/129954712878723/servers/Public?sortOrder=dsc&limit=100&excludeFullGames=true"
		local D = game:HttpGet(URL)
		return game.HttpService:JSONDecode(D)
	end

	local function TeleportServer()
		if #Servers > 0 then
			local sid = math.random(1, #Servers)
			pcall(function()
				game:GetService("TeleportService"):TeleportToPlaceInstance(
					129954712878723,
					Servers[sid],
					player
				)
			end)
		end
	end

	local function PlaceServers()
		local scraped = Scrape()
		for _, index in pairs(scraped.data) do
			if index.playing and index.playing < 30 and index.playing > 15 then
				table.insert(Servers, index.id)
			end
		end
		TeleportServer()
	end

	PlaceServers()
end

task.spawn(function()
	repeat task.wait(1)
	until #game:GetService("NetworkClient"):GetChildren() == 0
	pcall(Hop)
end)

-- =========================
-- BOOTH DATA
-- =========================
local Controller = require(game.ReplicatedStorage.Modules.TradeBoothControllers.TradeBoothController)
local v2 = require(game.ReplicatedStorage.Modules.DataService)

if not getgenv().boothData then
	getgenv().boothData = getupvalues(Controller.GetPlayerBoothData)[2]:GetDataAsync()
end

-- =========================
-- LISTINGS
-- =========================
local function getAllListings()
	local Data = getgenv().boothData
	local Listings = {}

	for BoothId, BoothData in pairs(Data.Booths) do
		local Owner = BoothData.Owner
		if not Owner or not Data.Players[Owner] then continue end

		for ListingId, ListingData in pairs(Data.Players[Owner].Listings) do
			if ListingData.ItemType == "Pet" then
				local ItemData = Data.Players[Owner].Items[ListingData.ItemId]
				if ItemData and not ItemData.PetData.IsFavorite then
					local Weight = ItemData.PetData.BaseWeight * 1.1
					table.insert(Listings, {
						Player = nil,
						ListingId = ListingId,
						PetType = ItemData.PetType,
						PetMax = Weight * 10,
						Price = ListingData.Price
					})
				end
			end
		end
	end

	return Listings
end

-- =========================
-- MAIN LOOP (UNCHANGED)
-- =========================
function MainLoop()
	local Listings = getAllListings()

	for _, Data in pairs(Listings) do
		local Filter = Filters[Data.PetType]
		if Filter then
			local MinWeight, MaxPrice = Filter[1], Filter[2]
			if Data.PetMax >= MinWeight and Data.Price <= MaxPrice then
				if Data.Price <= v2:GetData().TradeData.Tokens then
					game.ReplicatedStorage.GameEvents.TradeEvents.Booths.BuyListing:InvokeServer(
						Data.Player,
						Data.ListingId
					)
				end
			end
		end
	end
end

-- =========================
-- CONTROLLED START / STOP
-- =========================
local function StartPetSniper()
	if getgenv().PetSniperThread then return end

	getgenv().PetSniperThread = task.spawn(function()
		while getgenv().PetSniperEnabled do
			pcall(MainLoop)
			task.wait(0.5)
		end
		getgenv().PetSniperThread = nil
	end)
end

-- =========================
-- UI HOOK (ADD TO SECTION)
-- =========================
-- Paste ONLY this part into your UI section:
--
-- PetSniperSection:AddToggle("EnablePetSniper", {
--     Text = "Enable Pet Sniper",
--     Default = false,
--     Callback = function(state)
--         getgenv().PetSniperEnabled = state
--         if state then
--             StartPetSniper()
--         end
--     end
-- })
