-- =====================================
-- G O O N   S N I P E R
-- FULL COPY-PASTE (OBSIDIAN CLICKABLE)
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
-- CREATE MAIN TAB
-- =========================
local MainTab = Window:AddTab("Main")

-- =========================
-- ACCORDION SYSTEM (OBSIDIAN SAFE)
-- =========================
local OpenSection = nil

local function CreateAccordion(title, icon)
    -- 1️⃣ CLICKABLE HEADER (THIS is what you click)
    MainTab:AddButton(icon .. " " .. title, function()
        if OpenSection and OpenSection ~= Content then
            OpenSection:SetVisible(false)
        end

        if Content:GetVisible() then
            Content:SetVisible(false)
            OpenSection = nil
        else
            Content:SetVisible(true)
            OpenSection = Content
        end
    end)

    -- 2️⃣ CONTENT BOX (NOT CLICKABLE)
    local Content = MainTab:AddLeftGroupbox(title .. " Settings")
    Content:SetVisible(false)

    return Content
end

-- =========================
-- PET SNIPER SECTION
-- =========================
local PetSniperSection = CreateAccordion("Pet Sniper", "🎯")

-- =========================
-- PET SNIPER STATE
-- =========================
getgenv().PetSniperEnabled = false
getgenv().PetSniperThread = nil

-- =========================
-- PET SNIPER TOGGLE (INSIDE CONTENT)
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
-- APPLY THEME (LAST)
-- =========================
ThemeManager:SetLibrary(Obsidian)
ThemeManager:SetFolder("GoonSniper")
ThemeManager:ApplyToTab(Window)

print("[Goon Sniper] UI Loaded & Clickable")
