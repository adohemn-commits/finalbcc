local Core = exports.vorp_core:GetCore()
---@type BCCWavesDebugLib
local DBG = BCCWavesDebug

-- Use global state exported by server/state.lua
local Missions = rawget(_G, 'Missions') or {}
local ActivePeds = rawget(_G, 'ActivePeds') or {}

-- Register a mission site to a player source
RegisterNetEvent('bcc-waves:RegisterMission', function(site)
    local src = source
    local user = Core.getUser(src)

    -- Validate user exists
    if not user then
        DBG.Error('User not found for source: ' .. tostring(src))
        return
    end

    -- Validate site parameter
    if not site then
        DBG.Error('No site provided for mission registration')
        return
    end

    Missions[tostring(site)] = src
    DBG.Info(string.format("Registered mission site %s to source %s", tostring(site), tostring(src)))
    -- Notify all clients that a mission has started for this site so they can
    -- show local area indicators if they are nearby.
    TriggerClientEvent('bcc-waves:MissionStarted', -1, site)
end)

-- Unregister a mission site after completion or cancellation
RegisterNetEvent('bcc-waves:UnregisterMission', function(site)
    local src = source
    local user = Core.getUser(src)

    -- Validate user exists
    if not user then
        DBG.Error('User not found for source: ' .. tostring(src))
        return
    end

    -- Validate site parameter
    if not site then
        DBG.Error('No site provided for mission unregistration')
        return
    end

    -- only owner can unregister (or if owner disconnected, server cleanup will be automatic)
    if Missions[tostring(site)] ~= src then
        DBG.Warning(string.format("bcc-waves:UnregisterMission: source %s attempted to unregister site %s but owner is %s", tostring(src), tostring(site), tostring(Missions[tostring(site)])))
        return
    end

    -- attempt to delete any active ped entities associated with this site
    local active = ActivePeds or {}
    local removedNetIds = {}
    for netId, s in pairs(active) do
        if s == tostring(site) then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and DoesEntityExist(entity) then
                DBG.Info(string.format("UnregisterMission: deleting entity for netId %s (site=%s)", tostring(netId), tostring(site)))
                -- try to delete the entity server-side
                DeleteEntity(entity)
            end
            -- remove from active map after attempting deletion
            active[netId] = nil
            table.insert(removedNetIds, netId)
        end
    end

    Missions[tostring(site)] = nil
    DBG.Info(string.format("Unregistered mission site %s (by %s) and cleaned %d peds", tostring(site), tostring(src), tostring(#(active) or 0)))
    -- Broadcast mission end so clients can remove any area blips they created.
    TriggerClientEvent('bcc-waves:MissionEnded', -1, site)
    if #removedNetIds > 0 then
        TriggerClientEvent('bcc-waves:RemotePedsRemoved', -1, site, removedNetIds)
    end
end)

-- When a player disconnects, automatically unregister any missions they owned and cleanup associated peds
AddEventHandler('playerDropped', function(reason)
    local src = source
    DBG.Info(string.format("playerDropped: source %s disconnected (%s). Cleaning missions.", tostring(src), tostring(reason)))

    local removed = {}
    for site, owner in pairs(Missions) do
        if owner == src then
            Missions[site] = nil
            table.insert(removed, site)
        end
    end

    if #removed > 0 then
        -- attempt to delete entities for all ActivePeds that belonged to removed sites
        local active = ActivePeds or {}
        local removedBySite = {}
        for netId, s in pairs(active) do
            for _, site in ipairs(removed) do
                if s == tostring(site) then
                    local entity = NetworkGetEntityFromNetworkId(netId)
                    if entity and DoesEntityExist(entity) then
                        DBG.Info(string.format("playerDropped: deleting entity for netId %s (site=%s)", tostring(netId), tostring(site)))
                        DeleteEntity(entity)
                    end
                    active[netId] = nil
                    removedBySite[site] = removedBySite[site] or {}
                    table.insert(removedBySite[site], netId)
                    break
                end
            end
        end
        -- notify clients about removed peds per site
        for site, netIds in pairs(removedBySite) do
            TriggerClientEvent('bcc-waves:RemotePedsRemoved', -1, site, netIds)
        end
        DBG.Info(string.format("Cleaned up missions for disconnected source %s: %s", tostring(src), table.concat(removed, ", ")))
    end
end)
