-- Shared server state for bcc-waves
local state = {
    ActivePeds = {},
    Missions = {},
}

-- Export as globals so other server modules can access state consistently.
-- This intentionally uses two clear global names to be explicit and obvious.
pcall(function()
    if type(_G) == 'table' then
        _G.ActivePeds = state.ActivePeds
        _G.Missions = state.Missions
    end
end)

return state
