local currentRewardType

local function openRewards(rewardType)
    local result = lib.callback.await("dailyrewards:server:getData", false, rewardType)
    if not result or not result.ok then
        lib.notify({ title = "Rewards unavailable", description = result and result.message or "Try again later.", type = "error" })
        return
    end

    currentRewardType = rewardType
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", data = result })
end

RegisterCommand(Config.CommandMale, function()
    openRewards("male")
end, false)

RegisterCommand(Config.CommandFemale, function()
    openRewards("female")
end, false)

RegisterNUICallback("close", function(_, callback)
    SetNuiFocus(false, false)
    currentRewardType = nil
    SendNUIMessage({ action = "close" })
    callback({ ok = true })
end)

RegisterNUICallback("claimAll", function(_, callback)
    if not currentRewardType then
        callback({ ok = false, message = "The reward menu is closed." })
        return
    end

    local result = lib.callback.await("dailyrewards:server:claimAll", false, currentRewardType)
    if result and result.ok then
        lib.notify({ title = "Rewards claimed", description = result.message, type = "success" })
        SendNUIMessage({ action = "claimed", data = result })
    else
        lib.notify({ title = "Rewards unavailable", description = result and result.message or "Try again later.", type = "error" })
        SendNUIMessage({ action = "claimFailed", data = result or {} })
    end
    callback(result or { ok = false })
end)

RegisterNUICallback("claim", function(data, callback)
    if not currentRewardType then
        callback({ ok = false, message = "The reward menu is closed." })
        return
    end

    local result = lib.callback.await("dailyrewards:server:claim", false, currentRewardType, data.index)
    if result and result.ok then
        lib.notify({ title = "Reward claimed", description = result.message, type = "success" })
        SendNUIMessage({ action = "claimed", data = result })
    else
        lib.notify({ title = "Reward unavailable", description = result and result.message or "Try again later.", type = "error" })
        SendNUIMessage({ action = "claimFailed", data = result or {} })
    end
    callback(result or { ok = false })
end)
