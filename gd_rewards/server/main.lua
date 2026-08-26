local claimLocks = {}

local function getRewardSet(rewardType)
    if rewardType ~= "male" and rewardType ~= "female" then return nil end
    return Config.RewardSets[rewardType]
end

local function getCharacterGender(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.PlayerData.charinfo then return nil end
    return tonumber(player.PlayerData.charinfo.gender)
end

local function isAllowedGender(source, rewardType)
    local gender = getCharacterGender(source)
    return (rewardType == "male" and gender == 0) or (rewardType == "female" and gender == 1)
end

local function getRemainingSeconds(source, rewardType)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local row = MySQL.single.await(("SELECT claimed_at FROM `%s` WHERE citizenid = ? AND reward_type = ?"):format(Config.DatabaseTable), {
        player.PlayerData.citizenid,
        rewardType,
    })
    if not row then return 0 end

    local remaining = Config.CooldownSeconds - (os.time() - tonumber(row.claimed_at))
    return math.max(0, remaining)
end

local function serializeItems(rewardSet)
    local items = {}
    for index, item in ipairs(rewardSet.items) do
        items[index] = {
            index = index,
            label = item.label,
            description = item.description,
            amount = item.amount,
            image = item.image,
        }
    end
    return items
end

CreateThread(function()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            citizenid VARCHAR(50) NOT NULL,
            reward_type VARCHAR(10) NOT NULL,
            claimed_at BIGINT NOT NULL,
            PRIMARY KEY (citizenid, reward_type)
        )
    ]]):format(Config.DatabaseTable))
end)

lib.callback.register("dailyrewards:server:getData", function(source, rewardType)
    local rewardSet = getRewardSet(rewardType)
    if not rewardSet or not isAllowedGender(source, rewardType) then return { ok = false, message = "This reward set is not available to your character." } end

    return {
        ok = true,
        title = rewardSet.title,
        subtitle = Config.MenuSubtitle,
        claimAllLabel = Config.ClaimAllLabel,
        accent = rewardSet.accent,
        items = serializeItems(rewardSet),
        remaining = getRemainingSeconds(source, rewardType),
    }
end)

lib.callback.register("dailyrewards:server:claim", function(source, rewardType, itemIndex)
    local rewardSet = getRewardSet(rewardType)
    local player = exports.qbx_core:GetPlayer(source)
    itemIndex = tonumber(itemIndex)

    if not player or not rewardSet or not isAllowedGender(source, rewardType) then
        return { ok = false, message = "You are not eligible for this reward." }
    end
    if not itemIndex or itemIndex % 1 ~= 0 or not rewardSet.items[itemIndex] then
        return { ok = false, message = "Invalid reward selection." }
    end
    if claimLocks[source] then return { ok = false, message = "Please wait a moment and try again." } end

    claimLocks[source] = true
    local remaining = getRemainingSeconds(source, rewardType)
    if remaining == nil or remaining > 0 then
        claimLocks[source] = nil
        return { ok = false, remaining = remaining or Config.CooldownSeconds, message = "You have already claimed a reward recently." }
    end

    local item = rewardSet.items[itemIndex]
    local canCarry = exports.ox_inventory:CanCarryItem(source, item.name, item.amount)
    if not canCarry then
        claimLocks[source] = nil
        return { ok = false, message = "You do not have enough inventory space." }
    end

    local added = exports.ox_inventory:AddItem(source, item.name, item.amount)
    if not added then
        claimLocks[source] = nil
        return { ok = false, message = "The reward could not be added to your inventory." }
    end

    local citizenid = player.PlayerData.citizenid
    MySQL.insert.await(([[
        INSERT INTO `%s` (citizenid, reward_type, claimed_at) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE claimed_at = VALUES(claimed_at)
    ]]):format(Config.DatabaseTable), { citizenid, rewardType, os.time() })
    claimLocks[source] = nil

    return { ok = true, message = ("You received %sx %s."):format(item.amount, item.label), remaining = Config.CooldownSeconds }
end)

lib.callback.register("dailyrewards:server:claimAll", function(source, rewardType)
    local rewardSet = getRewardSet(rewardType)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or not rewardSet or not isAllowedGender(source, rewardType) then
        return { ok = false, message = "You are not eligible for this reward." }
    end
    if claimLocks[source] then return { ok = false, message = "Please wait a moment and try again." } end

    claimLocks[source] = true
    local remaining = getRemainingSeconds(source, rewardType)
    if remaining == nil or remaining > 0 then
        claimLocks[source] = nil
        return { ok = false, remaining = remaining or Config.CooldownSeconds, message = "You have already claimed your daily rewards." }
    end

    local totals = {}
    for _, item in ipairs(rewardSet.items) do
        totals[item.name] = (totals[item.name] or 0) + item.amount
    end

    for itemName, amount in pairs(totals) do
        if not exports.ox_inventory:CanCarryItem(source, itemName, amount) then
            claimLocks[source] = nil
            return { ok = false, message = "You do not have enough inventory space for all rewards." }
        end
    end

    local addedItems = {}
    for _, item in ipairs(rewardSet.items) do
        local added = exports.ox_inventory:AddItem(source, item.name, item.amount)
        if not added then
            for _, addedItem in ipairs(addedItems) do
                exports.ox_inventory:RemoveItem(source, addedItem.name, addedItem.amount)
            end
            claimLocks[source] = nil
            return { ok = false, message = "The rewards could not be added to your inventory." }
        end
        addedItems[#addedItems + 1] = { name = item.name, amount = item.amount }
    end

    MySQL.insert.await(([[
        INSERT INTO `%s` (citizenid, reward_type, claimed_at) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE claimed_at = VALUES(claimed_at)
    ]]):format(Config.DatabaseTable), { player.PlayerData.citizenid, rewardType, os.time() })
    claimLocks[source] = nil

    return { ok = true, message = "You received all rewards from the collection.", remaining = Config.CooldownSeconds }
end)

AddEventHandler("playerDropped", function()
    claimLocks[source] = nil
end)
