--==================================================
-- GROW A GARDEN BOOTH SNIPER + OBSIDIAN UI
--==================================================

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game.Players.LocalPlayer

--==================================================
-- FILTER DATA (UNCHANGED)
--==================================================

local Filters = {
	["Koi"] = {23, 50},
	["Mimic Octopus"] = {63.2, 1000},
	["Peacock"] = {62, 1000}, 
	["Raccoon"] = {0, 300},
	["Kitsune"] = {0, 500},
	["Rainbow Dilophosaurus"] = {0, 50000},

	["French Fry Ferret"] = {0,2},
	["Pancake Mole"] = {0,2},
	["Sushi Bear"] = {0,2},
	["Spaghetti Sloth"] = {0,2},
	["Bagel Bunny"] = {0,2},

	["Frog"] = {0,2},
	["Mole"] = {0,2},
	["Echo Frog"] = {0,2},

	["Shiba Inu"] = {0,2},
	["Nihonzaru"] = {0,2},
	["Tanuki"] = {0,2},
	["Tanchozuru"] = {0,2},
	["Kappa"] = {0,2},

	["Ostrich"] = {0,2},
	["Capybara"] = {0,2},
	["Scarlet Macaw"] = {0,2},

	["Wasp"] = {0,2},
	["Tarantula Hawk"] = {0,2},
	["Moth"] = {0,2},
	["Butterfly"] = {0,2},
	["Disco Bee"] = {0,2},

	["Bee"] = {0,2},
	["Honey Bee"] = {0,2},
	["Bear Bee"] = {0,2},
	["Petal Bee"] = {0,2},
	["Queen Bee"] = {0,2}
}

--==================================================
-- OBSIDIAN UI
--==================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "Goons Hub",
	Footer = "Obsidian UI",
	Icon = "target",
	Center = true,
	AutoShow = true
})

local Tabs = {
	Main = Window:AddTab("Main", "rocket"),
	Webhook = Window:AddTab("Webhook", "link"),
	UI = Window:AddTab("UI Settings", "settings")
}

local MainBox = Tabs.Main:AddLeftGroupbox("Sniper Control", "crosshair")
local FilterBox = Tabs.Main:AddRightGroupbox("Pet Filters", "paw-print")

local WebhookBox = Tabs.Webhook:AddLeftGroupbox("Discord", "link")

--==================================================
-- UI STATE
--==================================================

getgenv().SniperEnabled = false
getgenv().ScanDelay = 0.5
getgenv().WebhookURL = ""

--==================================================
-- MAIN CONTROLS
--==================================================

MainBox:AddToggle("EnableSniper", {
	Text = "Enable Booth Sniper",
	Default = false,
	Callback = function(v)
		getgenv().SniperEnabled = v
	end
})

MainBox:AddSlider("ScanDelay", {
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
-- FILTER EDITOR
--==================================================

local PetNames = {}
for k in pairs(Filters) do table.insert(PetNames, k) end
table.sort(PetNames)

FilterBox:AddDropdown("SelectedPet", {
	Text = "Pet Type",
	Values = PetNames,
	Default = 1
})

FilterBox:AddSlider("MinWeight", {
	Text = "Min Weight",
	Default = 0,
	Min = 0,
	Max = 114.44,
	Rounding = 1
})

FilterBox:AddSlider("MaxPrice", {
	Text = "Max Price",
	Default = 0,
	Min = 0,
	Max = 114.44,
	Rounding = 0
})

Library.Options.SelectedPet:OnChanged(function()
	local pet = Library.Options.SelectedPet.Value
	if Filters[pet] then
		Library.Options.MinWeight:SetValue(Filters[pet][1])
		Library.Options.MaxPrice:SetValue(Filters[pet][2])
	end
end)

Library.Options.MinWeight:OnChanged(function(v)
	local pet = Library.Options.SelectedPet.Value
	if Filters[pet] then Filters[pet][1] = v end
end)

Library.Options.MaxPrice:OnChanged(function(v)
	local pet = Library.Options.SelectedPet.Value
	if Filters[pet] then Filters[pet][2] = v end
end)

--==================================================
-- WEBHOOK
--==================================================

WebhookBox:AddInput("WebhookURL", {
	Text = "Discord Webhook",
	Placeholder = "https://discord.com/api/webhooks/...",
	Callback = function(v)
		getgenv().WebhookURL = v
	end
})

WebhookBox:AddButton({
	Text = "Test Webhook",
	Func = function()
		if getgenv().WebhookURL == "" then return end
		local data = {
			content = "✅ Booth Sniper Webhook Connected"
		}
		local headers = {["content-type"] = "application/json"}
		(request or http_request)({
			Url = getgenv().WebhookURL,
			Method = "POST",
			Headers = headers,
			Body = game.HttpService:JSONEncode(data)
		})
	end
})

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
-- SNIPER LOOP (GATED)
--==================================================

task.spawn(function()
	while true do
		task.wait(getgenv().ScanDelay)
		if not getgenv().SniperEnabled then continue end
		pcall(MainLoop)
	end
end)

Library:Notify("Booth Sniper Loaded", 4)
