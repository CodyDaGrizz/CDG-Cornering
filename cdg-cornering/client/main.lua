local busy = false
local currentPed = nil
local currentOffer = nil

local function notify(msg, t)
  lib.notify({ title = 'Cornering', description = msg, type = t or 'inform' })
end

local function isBlacklistedPed(ped)
  local model = GetEntityModel(ped)
  for _, m in ipairs(Config.BlacklistedPeds or {}) do
    if model == m then return true end
  end
  return false
end

local function lockPed(ped, state)
  if not DoesEntityExist(ped) then return end
  FreezeEntityPosition(ped, state)
  SetBlockingOfNonTemporaryEvents(ped, state)
  SetPedFleeAttributes(ped, 0, false)
  SetPedCanRagdoll(ped, not state)
  if state then
    ClearPedTasksImmediately(ped)
    TaskStandStill(ped, 10000)
    TaskLookAtEntity(ped, PlayerPedId(), 3000, 2048, 3)
    TaskTurnPedToFaceEntity(ped, PlayerPedId(), 1000)
  else
    ClearPedTasks(ped)
    TaskLookAtEntity(ped, PlayerPedId(), 1, 0, 2)
  end
end

local function loadModel(model)
  if not IsModelInCdimage(model) then return false end
  RequestModel(model)
  local timeout = GetGameTimer() + 3000
  while not HasModelLoaded(model) do
    Wait(0)
    if GetGameTimer() > timeout then return false end
  end
  return true
end

local function loadAnim(dict)
  RequestAnimDict(dict)
  local timeout = GetGameTimer() + 3000
  while not HasAnimDictLoaded(dict) do
    Wait(0)
    if GetGameTimer() > timeout then return false end
  end
  return true
end

local function attachPropToEntity(ent, model, bone, offset, rot)
  if not model then return nil end
  if not loadModel(model) then return nil end
  local obj = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
  AttachEntityToEntity(
    obj,
    ent,
    GetPedBoneIndex(ent, bone),
    offset.x, offset.y, offset.z,
    rot.x, rot.y, rot.z,
    true, true, false, true, 1, true
  )
  SetModelAsNoLongerNeeded(model)
  return obj
end

local function runExchangeAnim(playerPed, targetPed, drugPropModel)
  local ex = Config.Exchange
  if not loadAnim(ex.animDict) then return end

  local drugModel = drugPropModel or ex.defaultDrugPropModel

  local drugObj = attachPropToEntity(playerPed, drugModel, ex.playerHandBone, ex.propOffset, ex.propRot)
  local cashObj = attachPropToEntity(targetPed, ex.cashPropModel, ex.pedHandBone, ex.propOffset, ex.propRot)

  TaskTurnPedToFaceEntity(targetPed, playerPed, 800)
  TaskTurnPedToFaceEntity(playerPed, targetPed, 800)
  Wait(150)

  TaskPlayAnim(playerPed, ex.animDict, ex.animGive, 8.0, -8.0, -1, 49, 0, false, false, false)
  TaskPlayAnim(targetPed, ex.animDict, ex.animGive, 8.0, -8.0, -1, 49, 0, false, false, false)

  Wait(math.random(ex.durationMs.min, ex.durationMs.max))

  ClearPedTasks(playerPed)
  ClearPedTasks(targetPed)

  if drugObj then DeleteObject(drugObj) end
  if cashObj then DeleteObject(cashObj) end
end

local function closeOfferUI()
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })
end

local function openOfferUI(offer)
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = 'open',
    offer = {
      payout = offer.payout,
      amt = offer.amt,
      label = offer.label,
      unit = offer.unit,
    }
  })
end

RegisterNUICallback('cdg_corner_accept', function(_, cb)
  cb({ ok = true })
  if not busy or not currentOffer or not currentPed then
    closeOfferUI()
    return
  end

  local playerPed = PlayerPedId()
  local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(currentPed))
  if dist > (Config.MaxInteractDistance or 2.2) then
    notify('They walked away.', 'error')
    lockPed(currentPed, false)
    busy = false
    currentPed = nil
    currentOffer = nil
    closeOfferUI()
    return
  end

  closeOfferUI()

  -- Keep them locked during the exchange
  lockPed(currentPed, true)

  runExchangeAnim(playerPed, currentPed, currentOffer.propModel)

  local res = lib.callback.await('cdg-cornering:server:acceptOffer', false, currentOffer.token)
  if not res or not res.ok then
    notify(res and res.reason or 'Sale failed.', 'error')
  else
    notify(('Sold %dx %s for $%d'):format(res.amt, res.label, res.payout), 'success')
  end

  lockPed(currentPed, false)
  busy = false
  currentPed = nil
  currentOffer = nil
end)

RegisterNUICallback('cdg_corner_decline', function(_, cb)
  cb({ ok = true })
  TriggerServerEvent('cdg-cornering:server:declineOffer')
  closeOfferUI()

  if currentPed then
    lockPed(currentPed, false)
  end

  busy = false
  currentPed = nil
  currentOffer = nil
end)

local function tryOffer(targetPed)
  if busy then return end
  busy = true

  local playerPed = PlayerPedId()

  if IsPedInAnyVehicle(playerPed, false) then
    notify('Get out of the vehicle.', 'error')
    busy = false
    return
  end

  if Config.IgnorePedsInVehicles and IsPedInAnyVehicle(targetPed, false) then
    notify('They won\'t buy from a car.', 'error')
    busy = false
    return
  end

  if isBlacklistedPed(targetPed) or IsPedAPlayer(targetPed) or IsPedDeadOrDying(targetPed, true) then
    busy = false
    return
  end

  local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
  if dist > (Config.MaxInteractDistance or 2.2) then
    notify('Get closer.', 'error')
    busy = false
    return
  end

  -- Lock ped immediately so they don\'t wander off while the offer UI is opening
  lockPed(targetPed, true)

  local pedNetId = NetworkGetNetworkIdFromEntity(targetPed)
  local data = lib.callback.await('cdg-cornering:server:getOffer', false, pedNetId)

  if not data or not data.ok then
    notify(data and data.reason or 'No offer.', 'error')
    lockPed(targetPed, false)
    busy = false
    return
  end

  currentPed = targetPed
  currentOffer = data.offer

  openOfferUI(currentOffer)
end

CreateThread(function()
  if not Config.UseTarget then
    notify('This version requires ox_target (Config.UseTarget=true).', 'error')
    return
  end

  if not GetResourceState('ox_target'):find('start') then
    notify('ox_target is not started.', 'error')
    return
  end

  exports.ox_target:addGlobalPed({
    {
      name = 'cdg_corner_offer',
      icon = 'fa-solid fa-handshake',
      label = 'Offer Drugs',
      distance = 2.0,
      canInteract = function(entity)
        if busy then return false end
        if not DoesEntityExist(entity) then return false end
        if IsPedAPlayer(entity) then return false end
        if IsPedDeadOrDying(entity, true) then return false end
        if isBlacklistedPed(entity) then return false end
        return true
      end,
      onSelect = function(data)
        tryOffer(data.entity)
      end
    }
  })
end)
