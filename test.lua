-- =====================================
-- G O O N   S N I P E R
-- FULL COPY-PASTE (OBSIDIAN SAFE)
-- =====================================

-- =========================
-- LOAD OBSIDIAN
-- =========================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Obsidian = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

-- =========================
-- CREATE WINDOW
-- =========================
local Window = Obsidian:CreateWindow({
	Title = "Goon Sniper",
	Center = true,
	AutoShow = true
})

-- =========================
-- CREATE MAIN TAB FIRST
-- =========================
local MainTab = Window:AddTab("Main")

-- =========================
-- ACCORDION SYSTEM
-- =========================
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

-- =========================
-- PET SNIPER SECTION
-- =========================
local PetSniperSection = CreateSection("Pet Sniper", "🎯")

-- =========================
-- PET SNIPER CONTROL
-- =========================
getgenv().PetSniperEnabled = false
getgenv().PetSniperThread = nil

-- =========================
-- PET SNIPER TOGGLE
-- =========================
PetSniperSection:AddToggle("EnablePetSniper", {
	Text = "Enable Pet Sniper",
	Default = false,
	Callback = function(state)
		getgenv().PetSniperEnabled = state

		if state and not getgenv().PetSniperThread then
			getgenv().PetSniperThread = task.spawn(function()
				while getgenv().PetSniperEnabled do
					-- PET SNIPER LOGIC GOES HERE
					task.wait(0.5)
				end
				getgenv().PetSniperThread = nil
			end)
		end
	end
})

-- =========================
-- APPLY THEME MANAGER LAST
-- =========================
ThemeManager:SetLibrary(Obsidian)
ThemeManager:SetFolder("GoonSniper")
ThemeManager:ApplyToTab(Window)

print("[Goon Sniper] Loaded successfully")
