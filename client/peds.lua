-- peds.lua: enemy ped lifecycle and spawning

local PooledUpdaterStarted = false
EnemyPeds = EnemyPeds or {}
EnemyBlips = EnemyBlips or {}
EnemyPedMeta = EnemyPedMeta or {}

function StartEnemyPed(ctx, pedIndex, coords)
    local siteCfg = ctx.siteCfg
    local hash = ctx.hash

    EnemyPeds[pedIndex] = Citizen.InvokeNative(0xD49F9B0955C367DE, hash, coords.x, coords.y, coords.z,
        0.0, true, false, false, false) -- CreatePed

    local netId = NetworkGetNetworkIdFromEntity(EnemyPeds[pedIndex])

    Citizen.InvokeNative(0x283978A15512B2FE, EnemyPeds[pedIndex], true) -- SetRandomOutfitVariation
    PlaceObjectOnGroundProperly(EnemyPeds[pedIndex], false)

    local enemyGroup = `REL_PLAYER_ENEMY`
    local playerGroup = `PLAYER`
    SetPedRelationshipGroupDefaultHash(EnemyPeds[pedIndex], enemyGroup)
    SetRelationshipBetweenGroups(6, enemyGroup, playerGroup)
    SetRelationshipBetweenGroups(6, playerGroup, enemyGroup)

    local attributeIdx = {
        0,  -- CA_USE_COVER
        5,  -- CA_ALWAYS_FIGHT
        14, -- CA_CAN_INVESTIGATE
        21, -- CA_CAN_CHASE_TARGET_ON_FOOT
        42, -- CA_CAN_FLANK
        43, -- CA_SWITCH_TO_ADVANCE_IF_CANT_FIND_COVER
        46, -- CA_CAN_FIGHT_ARMED_PEDS_WHEN_NOT_ARMED
        50, -- CA_CAN_CHARGE
        54, -- CA_ALWAYS_EQUIP_BEST_WEAPON
        58, -- CA_DISABLE_FLEE_FROM_COMBAT
        114 -- CA_CAN_EXECUTE_TARGET
    }
    for _, attr in ipairs(attributeIdx) do
        Citizen.InvokeNative(0x9F7794730795E019, EnemyPeds[pedIndex], attr, true) -- SetPedCombatAttributes
    end

    Citizen.InvokeNative(0x4D9CA1009AFBD057, EnemyPeds[pedIndex], 2)                            -- SetPedCombatMovement / Offensive
    Citizen.InvokeNative(0x3C606747B23E497B, EnemyPeds[pedIndex], 1)                            -- SetPedCombatRange / Medium

    Citizen.InvokeNative(0x7AEFB85C1D49DEB6, EnemyPeds[pedIndex], siteCfg.bandits.accuracy)     -- SetPedAccuracy
    Citizen.InvokeNative(0xF29CF591C4BF6CEE, EnemyPeds[pedIndex], siteCfg.bandits.seeingRange)  -- SetPedSeeingRange
    Citizen.InvokeNative(0x33A8F7F7D5F7F33C, EnemyPeds[pedIndex], siteCfg.bandits.hearingRange) -- SetPedHearingRange

    -- BlipAddForEntity
    EnemyBlips[pedIndex] = Citizen.InvokeNative(0x23F74C2FDA6E7C61, siteCfg.bandits.blipSprite, EnemyPeds[pedIndex])

    -- Initialize meta for throttling task reassignments
    EnemyPedMeta[pedIndex] = { lastTaskTime = 0, lastTarget = nil }

    -- Force immediate combat tasks so the ped starts engaging the player.
    -- Use the closest player as the initial target (falls back to local player in the updater).
    local initTarget = GetClosestPlayer()
    if not DoesEntityExist(initTarget) or IsEntityDead(initTarget) then
        initTarget = PlayerPedId()
    end

    Citizen.Wait(50)
    Citizen.InvokeNative(0xF166E48407BAC484, EnemyPeds[pedIndex], initTarget, 0, 16)              -- TaskCombatPed
    Citizen.InvokeNative(0x6A071245EB0D1882, EnemyPeds[pedIndex], initTarget, -1, 2.0, 2.0, 0, 0) -- TaskGoToEntity

    return netId
end

function CleanupEnemyPed(pedIndex)
    local ent = EnemyPeds[pedIndex]
    if ent and DoesEntityExist(ent) then
        if EnemyBlips[pedIndex] and DoesBlipExist(EnemyBlips[pedIndex]) then
            RemoveBlip(EnemyBlips[pedIndex])
            EnemyBlips[pedIndex] = nil
        end

        if NetworkHasControlOfEntity(ent) then
            DeleteEntity(ent)
        else
            NetworkRequestControlOfEntity(ent)
            local t0 = GetGameTimer()
            while not NetworkHasControlOfEntity(ent) and GetGameTimer() - t0 < 1000 do
                Wait(10)
            end
            if NetworkHasControlOfEntity(ent) then
                DeleteEntity(ent)
            else
                SetEntityAsNoLongerNeeded(ent)
            end
        end
    end

    EnemyPeds[pedIndex] = nil
    EnemyBlips[pedIndex] = nil
end

function SpawnWave(ctx, waveIndex)
    if not EnsureMissionActive() then
        return 0
    end

    local waves = ctx.waves
    local npcCoords = ctx.npcCoords
    local totalEnemies = ctx.totalEnemies or 0
    local wavePeds = ctx.wavePeds
    local site = ctx.site
    local waveSize = waves[waveIndex]
    local spawned = 0
    local spawnNetIds = {}
    wavePeds[waveIndex] = {}

    for i = totalEnemies + 1, #npcCoords do
        if spawned >= waveSize then break end

        local coords = npcCoords[i]
        local pedIndex = totalEnemies + spawned + 1
        local netId = StartEnemyPed(ctx, pedIndex, coords)
        if netId and netId ~= 0 then
            table.insert(spawnNetIds, netId)
        end

        table.insert(wavePeds[waveIndex], pedIndex)
        spawned = spawned + 1
    end

    if site and #spawnNetIds > 0 then
        TriggerServerEvent('bcc-waves:RegisterPeds', site, spawnNetIds)
    end

    return spawned
end

-- Pooled updater to manage ped behavior and cleanup in a single thread.
local function StartPooledPedUpdater()
    if PooledUpdaterStarted then return end
    PooledUpdaterStarted = true

    CreateThread(function()
        local updaterIndex = 1
        -- dynamic updater config
        local cfg = {
            frameBudgetMs = (Config and Config.PedUpdater and Config.PedUpdater.frameBudgetMs) or 10,
            costPerPedMs = (Config and Config.PedUpdater and Config.PedUpdater.costPerPedMs) or 2,
            minSlices = (Config and Config.PedUpdater and Config.PedUpdater.minSlices) or 1,
            maxSlices = (Config and Config.PedUpdater and Config.PedUpdater.maxSlices) or 16,
            sliceWaitMs = (Config and Config.PedUpdater and Config.PedUpdater.sliceWaitMs) or 200,
            taskReassignMs = (Config and Config.PedUpdater and Config.PedUpdater.taskReassignMs) or 1000,
        }

        while true do
            if not InMission then
                updaterIndex = 1
                Wait(2000)
            else
                local keys = {}
                for k, _ in pairs(EnemyPeds) do table.insert(keys, k) end
                local total = #keys
                if total == 0 then
                    Wait(500)
                else
                    -- desired batch size based on frame budget and estimated cost per ped
                    local desiredBatch = math.max(1, math.floor(cfg.frameBudgetMs / cfg.costPerPedMs))
                    -- compute slices to split total peds into; clamp to configured bounds
                    local slices = math.min(cfg.maxSlices, math.max(cfg.minSlices, math.ceil(total / desiredBatch)))
                    local batch = math.max(1, math.ceil(total / slices))

                    for i = 0, batch - 1 do
                        local idx = ((updaterIndex + i - 1) % total) + 1
                        local pedIndex = keys[idx]
                        local ped = EnemyPeds[pedIndex]
                        if ped and DoesEntityExist(ped) then
                            if IsEntityDead(ped) then
                                if EnemyBlips[pedIndex] and DoesBlipExist(EnemyBlips[pedIndex]) then
                                    RemoveBlip(EnemyBlips[pedIndex])
                                    EnemyBlips[pedIndex] = nil
                                end
                            else
                                local curTarget = GetClosestPlayer()
                                if not DoesEntityExist(curTarget) or IsEntityDead(curTarget) then
                                    curTarget = PlayerPedId()
                                end

                                local now = GetGameTimer()
                                local meta = EnemyPedMeta[pedIndex]
                                if not meta then
                                    meta = { lastTaskTime = 0, lastTarget = nil }
                                    EnemyPedMeta[pedIndex] = meta
                                end

                                -- ensure we have control before assigning local tasks
                                if not NetworkHasControlOfEntity(ped) then
                                    NetworkRequestControlOfEntity(ped)
                                else
                                    local targetChanged = (meta.lastTarget ~= curTarget)
                                    if targetChanged or (now - (meta.lastTaskTime or 0) >= cfg.taskReassignMs) then
                                        Citizen.InvokeNative(0xF166E48407BAC484, ped, curTarget, 0, 16) -- TaskCombatPed
                                        meta.lastTaskTime = now
                                        meta.lastTarget = curTarget
                                    end

                                    local pedCoords = GetEntityCoords(ped)
                                    local targetCoords = GetEntityCoords(curTarget)
                                    local distance = #(pedCoords - targetCoords)
                                    if distance > 2.0 and not IsPedWalking(ped) and not IsPedRunning(ped) and not IsPedSprinting(ped) then
                                        -- only re-issue movement if enough time has passed or if target changed
                                        if targetChanged or (now - (meta.lastTaskTime or 0) >= cfg.taskReassignMs) then
                                            Citizen.InvokeNative(0x6A071245EB0D1882, ped, curTarget, -1, 2.0, 2.0, 0, 0) -- TaskGoToEntity
                                            meta.lastTaskTime = now
                                            meta.lastTarget = curTarget
                                        end
                                    end
                                end
                            end
                        else
                            EnemyPeds[pedIndex] = nil
                            if EnemyBlips[pedIndex] and DoesBlipExist(EnemyBlips[pedIndex]) then
                                RemoveBlip(EnemyBlips[pedIndex])
                                EnemyBlips[pedIndex] = nil
                            end
                        end
                    end

                    updaterIndex = ((updaterIndex + batch - 1) % total) + 1
                    Wait(cfg.sliceWaitMs)
                end
            end
        end
    end)
end

-- start pooled updater immediately
StartPooledPedUpdater()
