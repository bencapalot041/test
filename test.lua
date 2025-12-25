-- =====================================
-- G O O N   S N I P E R
-- CLEAN BASELINE UI
-- =====================================

-- =========================
-- LOAD OBSIDIAN
-- =========================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Obsidian = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- =========================
-- CREATE WINDOW
-- =========================
local Window = Obsidian:CreateWindow({
    Title = "Goon Sniper",
    Center = true,
    AutoShow = true
})

-- =========================
-- CREATE MAIN TAB
-- =========================
local MainTab = Window:AddTab("Main")

-- =========================
-- PET SNIPER GROUP
-- =========================
local PetSniperGroup = MainTab:AddLeftGroupbox("Pet Sniper")

-- =========================
-- PET SNIPER TOGGLE
-- =========================
PetSniperGroup:AddToggle("PetSniperToggle", {
    Text = "Enable Pet Sniper",
    Default = false,
    Callback = function(state)
        print("Pet Sniper toggled:", state)
    end
})

print("[Goon Sniper] Baseline UI loaded")
