local offers = {}           -- offers[src] = offer table
local lastTry = {}          -- lastTry[src] = os.time()
local lastPedUse = {}       -- lastPedUse[src][pedNetId] = os.time()

local function now() return os.time() end

local function hasValue(t, v)
  for _, x in ipairs(t or {}) do
    if x == v then return true end
  end
  return false
end

local function countCops()
  local cops = 0
  local players = exports.qbx_core:GetQBPlayers()
  for _, p in pairs(players) do
    local job = p.PlayerData?.job?.name
    if job and hasValue(Config.CopJobNames, job) then
      cops += 1
    end
  end
  return cops
end

local function weightedPick(list)
  local total = 0
  for _, d in ipairs(list) do
    total += (d.weight or 1)
  end
  local r = math.random() * total
  local acc = 0
  for _, d in ipairs(list) do
    acc += (d.weight or 1)
    if r <= acc then return d end
  end
  return list[#list]
end

local function newToken()
  return ('%06d%06d%06d'):format(math.random(0, 999999), math.random(0, 999999), now() % 1000000)
end

lib.callback.register('cdg-cornering:server:getOffer', function(src, pedNetId)
  local t = now()

  if lastTry[src] and (t - lastTry[src]) < (Config.PlayerCooldown or 0) then
    return { ok = false, reason = 'Slow down.' }
  end
  lastTry[src] = t

  local needed = Config.MinimumCops or 0
  if needed > 0 and countCops() < needed then
    return { ok = false, reason = 'Not enough police around.' }
  end

  lastPedUse[src] = lastPedUse[src] or {}
  if lastPedUse[src][pedNetId] and (t - lastPedUse[src][pedNetId]) < (Config.PedCooldown or 0) then
    return { ok = false, reason = 'This customer already talked to you.' }
  end

  if math.random() < (Config.RefuseChance or 0.0) then
    lastPedUse[src][pedNetId] = t
    return { ok = false, reason = 'They are not interested.', refused = true }
  end

  local chosen, haveCount
  for _ = 1, 10 do
    local d = weightedPick(Config.Drugs or {})
    local have = exports.ox_inventory:Search(src, 'count', d.item) or 0
    if have and have > 0 then
      chosen, haveCount = d, have
      break
    end
  end

  if not chosen then
    return { ok = false, reason = 'You have nothing to sell.' }
  end

  local amt = math.random(chosen.amtMin or 1, chosen.amtMax or 1)
  if amt > haveCount then amt = haveCount end
  if amt <= 0 then
    return { ok = false, reason = 'You have nothing to sell.' }
  end

  local unit = math.random(chosen.priceMin or 10, chosen.priceMax or 20)
  local payout = unit * amt

  local token = newToken()
  offers[src] = {
    token = token,
    expires = t + (Config.OfferExpireSeconds or 25),
    item = chosen.item,
    label = chosen.label or chosen.item,
    amt = amt,
    unit = unit,
    payout = payout,
    pedNetId = pedNetId,
    propModel = chosen.propModel, -- optional per-drug prop
  }

  return { ok = true, offer = offers[src] }
end)

lib.callback.register('cdg-cornering:server:acceptOffer', function(src, token)
  local t = now()
  local o = offers[src]

  if not o or o.token ~= token then
    return { ok = false, reason = 'Offer invalid.' }
  end

  if t > o.expires then
    offers[src] = nil
    return { ok = false, reason = 'Offer expired.' }
  end

  local have = exports.ox_inventory:Search(src, 'count', o.item) or 0
  if have < o.amt then
    offers[src] = nil
    return { ok = false, reason = 'You no longer have enough.' }
  end

  local removed = exports.ox_inventory:RemoveItem(src, o.item, o.amt)
  if not removed then
    offers[src] = nil
    return { ok = false, reason = 'Inventory error.' }
  end

  if Config.Payout.Type == 'cash' then
    exports.ox_inventory:AddItem(src, 'money', o.payout)
  elseif Config.Payout.Type == 'markedbills' then
    exports.ox_inventory:AddItem(src, Config.Payout.MarkedBillsItem, 1, { worth = o.payout })
  else
    exports.ox_inventory:AddItem(src, Config.Payout.ItemName, o.payout)
  end

  lastPedUse[src] = lastPedUse[src] or {}
  lastPedUse[src][o.pedNetId] = t
  offers[src] = nil

  return { ok = true, payout = o.payout, amt = o.amt, label = o.label }
end)

RegisterNetEvent('cdg-cornering:server:declineOffer', function()
  offers[source] = nil
end)
