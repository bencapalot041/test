--==================================================
-- GROW A GARDEN BOOTH SNIPER (NORMALIZED @ LEVEL 100)
-- OBSIDIAN UI - FINAL
--==================================================

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game.Players.LocalPlayer

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- FILTER DATA
--==================================================

local Filters = {
	["Koi"] = { MinKG = 0, MaxPrice = math.huge },
	["Mimic Octopus"] = { MinKG = 0, MaxPrice = math.huge },
	["Peacock"] = { MinKG = 0, MaxPrice = math.huge },
	["Raccoon"] = { MinKG = 0, MaxPrice = math.huge },
	["Kitsune"] = { MinKG = 0, MaxPrice = math.huge },
	["Rainbow Dilophosaurus"] = { MinKG = 0, MaxPrice = math.huge },
	["French Fry Ferret"] = { MinKG = 0, MaxPrice = math.huge },
	["Pancake Mole"] = { MinKG = 0, MaxPrice = math.huge },
	["Sushi Bear"] = { MinKG = 0, MaxPrice = math.huge },
	["Spaghetti Sloth"] = { MinKG = 0, MaxPrice = math.huge },
	["Bagel Bunny"] = { MinKG = 0, MaxPrice = math.huge },
	["Frog"] = { MinKG = 0, MaxPrice = math.huge },
	["Mole"] = { MinKG = 0, MaxPrice = math.huge },
	["Echo Frog"] = { MinKG = 0, MaxPrice = math.huge },
	["Shiba Inu"] = { MinKG = 0, MaxPrice = math.huge },
	["Nihonzaru"] = { MinKG = 0, MaxPrice = math.huge },
	["Tanuki"] = { MinKG = 0, MaxPrice = math.huge },
	["Tanchozuru"] = { MinKG = 0, MaxPrice = math.huge },
	["Kappa"] = { MinKG = 0, MaxPrice = math.huge },
	["Ostrich"] = { MinKG = 0, MaxPrice = math.huge },
	["Capybara"] = { MinKG = 0, MaxPrice = math.huge },
	["Scarlet Macaw"] = { MinKG = 0, MaxPrice = math.huge },
	["Wasp"] = { MinKG = 0, MaxPrice = math.huge },
	["Tarantula Hawk"] = { MinKG = 0, MaxPrice = math.huge },
	["Moth"] = { MinKG = 0, MaxPrice = math.huge },
	["Butterfly"] = { MinKG = 0, MaxPrice = math.huge },
	["Disco Bee"] = { MinKG = 0, MaxPrice = math.huge },
	["Bee"] = { MinKG = 0, MaxPrice = math.huge },
	["Honey Bee"] = { MinKG = 0, MaxPrice = math.huge },
	["Bear Bee"] = { MinKG = 0, MaxPrice = math.huge },
	["Petal Bee"] = { MinKG = 0, MaxPrice = math.huge },
	["Queen Bee"] = { MinKG = 0, MaxPrice = math.huge },
}

--==================================================
-- OBSIDIAN UI
--==================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "Goons Hub",
	Footer = "Normalized @ Level 100",
	Icon = "target",
	Center = true,
	AutoShow = true
})

local Tabs = {
	Main = Window:AddTab("Main", "rocket"),
	UI = Window:AddTab("UI Settings", "settings")
}

local SniperBox = Tabs.Main:AddLeftGroupbox("Sniper Control", "crosshair")
local FilterBox = Tabs.Main:AddRightGroupbox("Pet Filters", "paw-print")
local DataBox = Tabs.Main:AddLeftGroupbox("DATA", "database")
--==================================================
-- STATE
--==================================================

getgenv().SniperEnabled = false
getgenv().ScanDelay = 0.5

local SelectedPets = {}
local MinKG = 0
local MaxPrice = math.huge

--==================================================
-- SNIPER CONTROLS
--==================================================

SniperBox:AddToggle("EnableSniper", {
	Text = "Enable Booth Sniper",
	Default = false,
	Callback = function(v)
		getgenv().SniperEnabled = v
	end
})

SniperBox:AddSlider("ScanDelay", {
	Text = "Scan Delay",
	Default = 0.5,
	Min = 0.1,
	Max = 3,
	Rounding = 1,
	Suffix = "s",
	Callback = function(v)
		getgenv().ScanDelay = v
	end
})

--==================================================
-- FILTER UI
--==================================================

local PetNames = {}
for name in pairs(Filters) do
	table.insert(PetNames, name)
end
table.sort(PetNames)

FilterBox:AddDropdown("PetSelector", {
	Text = "Pet To List",
	Values = PetNames,
	Multi = true,
	Searchable = true
})

FilterBox:AddInput("MinKGInput", {
	Text = "Min Weight (KG)",
	Placeholder = "e.g. 60",
	Numeric = true,
	Callback = function(v)
		MinKG = tonumber(v) or 0
	end
})

FilterBox:AddInput("MaxPriceInput", {
	Text = "Max Price (Tokens)",
	Placeholder = "e.g. 500",
	Numeric = true,
	Callback = function(v)
		MaxPrice = tonumber(v) or math.huge
	end
})

Library.Options.PetSelector:OnChanged(function()
	SelectedPets = {}
	for pet, enabled in pairs(Library.Options.PetSelector.Value or {}) do
		if enabled then
			SelectedPets[pet] = true
		end
	end
end)

--==================================================
-- SNIPER LOGIC
--==================================================

local Controller = require(ReplicatedStorage.Modules.TradeBoothControllers.TradeBoothController)
local DataService = require(ReplicatedStorage.Modules.DataService)

getgenv().boothData = getupvalues(Controller.GetPlayerBoothData)[2]:GetDataAsync()

local function NormalizeWeight(weight, level)
	return (weight / level) * 100
end

local function GetAllListings()
	local Listings = {}
	local Data = getgenv().boothData

	for BoothId, Booth in pairs(Data.Booths) do
		local Owner = Booth.Owner
		if not Owner then continue end

		if not Data.Players[Owner] then continue end

		for ListingId, Listing in pairs(Data.Players[Owner].Listings) do
			if Listing.ItemType ~= "Pet" then continue end

			local Item = Data.Players[Owner].Items[Listing.ItemId]
			if not Item or Item.PetData.IsFavorite then continue end

			table.insert(Listings, {
				Player = Owner,
				ListingId = ListingId,
				PetType = Item.PetData.PetType,
				Weight = Item.PetData.BaseWeight * 10,
				Level = Item.PetData.Level,
				Price = Listing.Price
			})
		end
	end

	return Listings
end

local function MainLoop()
	if not getgenv().SniperEnabled then return end

	local Listings = GetAllListings()
	local Tokens = DataService:GetData().TradeData.Tokens

	for _, pet in pairs(Listings) do
		if not SelectedPets[pet.PetType] then continue end
		if pet.Price > MaxPrice or pet.Price > Tokens then continue end

		local normalized = NormalizeWeight(pet.Weight, pet.Level)

		if normalized >= MinKG then
			ReplicatedStorage.GameEvents.TradeEvents.Booths.BuyListing:InvokeServer(
				Players:GetPlayerByUserId(tonumber(string.split(pet.Player, "_")[2])),
				pet.ListingId
			)
		end
	end
end

--==================================================
-- THEME / SAVE
--==================================================

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)

ThemeManager:LoadDefault()
SaveManager:LoadAutoloadConfig()

--==================================================
-- LOOP
--==================================================

task.spawn(function()
	while true do
		task.wait(getgenv().ScanDelay)
		pcall(MainLoop)
	end
end)
local DataService = require(game:GetService("ReplicatedStorage").Modules.DataService)
local PlayerData = DataService:GetData()

local DataKeys = {}
for key in pairs(PlayerData) do
	table.insert(DataKeys, key)
end
table.sort(DataKeys)

DataBox:AddDropdown("DataKeySelector", {
	Text = "Select Key",
	Values = DataKeys,
	Searchable = true,
	AllowNull = true
})

Library.Options.DataKeySelector:OnChanged(function()
	local selectedKey = Library.Options.DataKeySelector.Value
	if not selectedKey then return end

	-- For now: just print (safe, no side effects)
	print("[DATA]", selectedKey, PlayerData[selectedKey])
end)

Library:Notify("Booth Sniper Loaded (Normalized @ Level 100)", 5)
