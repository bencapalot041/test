-- =====================================
-- O B S I D I A N   U I   L O A D
-- =====================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Obsidian = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Obsidian:CreateWindow({
	Title = "Goon Sniper",
	Center = true,
	AutoShow = true
})

ThemeManager:SetLibrary(Obsidian)
SaveManager:SetLibrary(Obsidian)

ThemeManager:SetFolder("GoonSniper")
SaveManager:SetFolder("GoonSniper")

SaveManager:BuildConfigSection(Window)
ThemeManager:ApplyToTab(Window)

-- =====================================
-- M A I N   T A B   +   A C C O R D I O N
-- =====================================

local MainTab = Window:AddTab("Main")
local OpenSection = nil

local function CreateSection(title, icon)
	local SectionBox = MainTab:AddLeftGroupbox(title)
	SectionBox:SetVisible(false)

	MainTab:AddButton(icon .. " " .. title, function()
		if OpenSection and OpenSection ~= SectionBox then
			OpenSection:SetVisible(false)
		end

		if SectionBox:GetVisible() then
			SectionBox:SetVisible(false)
			OpenSection = nil
		else
			SectionBox:SetVisible(true)
			OpenSection = SectionBox
		end
	end)

	return SectionBox
end

local PetSniperSection = CreateSection("Pet Sniper", "🎯")

-- =====================================
-- P E T   S N I P E R   C O N T R O L
-- =====================================

getgenv().PetSniperEnabled = false
getgenv().PetSniperThread = nil

-- =====================================
-- F I L T E R S  (UNCHANGED)
-- =====================================

local Filters = {
	["Koi"] = {23, 50},
	["Mimic Octopus"] = {63.2, 1000},
	["Peacock"] = {62, 1000},
	["Raccoon"] = {0, 300},
	["Kitsune"] = {0, 500},
	["Rainbow Dilophosaurus"] = {0, 50000}
}

-- =====================================
-- G A M E   R E A D Y
-- =====================================

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
repeat task.wait() until Players.LocalPlayer
local player = Players.LocalPlayer

-- =====================================
-- B O O T H   D A T A
-- =====================================

local Controller = require(game.ReplicatedStorage.Modules.TradeBoothControllers.TradeBoothController)
local DataService = require(game.ReplicatedStorage.Modules.DataService)

if not getgenv().boothData then
	getgenv().boothData = getupvalues(Controller.GetPlayerBoothData)[2]:GetDataAsync()
end

-- =====================================
-- L I S T I N G S
-- =====================================

local function getAllListings()
	local Data = getgenv().boothData
	local Listings = {}

	for _, BoothData in pairs(Data.Booths) do
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

-- =====================================
-- M A I N   S N I P E   L O O P
-- =====================================

function MainLoop()
	local Listings = getAllListings()

	for _, Data in pairs(Listings) do
		local Filter = Filters[Data.PetType]
		if Filter then
			local MinWeight, MaxPrice = Filter[1], Filter[2]
			if Data.PetMax >= MinWeight and Data.Price <= MaxPrice then
				if Data.Price <= DataService:GetData().TradeData.Tokens then
					game.ReplicatedStorage.GameEvents.TradeEvents.Booths.BuyListing:InvokeServer(
						Data.Player,
						Data.ListingId
					)
				end
			end
		end
	end
end

-- =====================================
-- S T A R T / S T O P
-- =====================================

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

-- =====================================
-- U I   T O G G L E
-- =====================================

PetSniperSection:AddToggle("EnablePetSniper", {
	Text = "Enable Pet Sniper",
	Default = false,
	Callback = function(state)
		getgenv().PetSniperEnabled = state
		if state then
			StartPetSniper()
		end
	end
})

print("[Goon Sniper] Loaded successfully.")
