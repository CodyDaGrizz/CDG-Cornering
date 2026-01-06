Config = {}

Config.UseTarget = true

Config.MinimumCops = 0
Config.CopJobNames = { 'lspd', 'bcso', 'sast', 'police' }

Config.PlayerCooldown = 8
Config.PedCooldown = 45
Config.OfferExpireSeconds = 25

Config.MaxInteractDistance = 2.2
Config.IgnorePedsInVehicles = true

Config.RefuseChance = 0.20
Config.CallCopsChance = 0.10
Config.CallCopsOnFail = true

Config.Payout = {
  Type = 'cash', -- 'cash' | 'markedbills' | 'item'
  MarkedBillsItem = 'markedbills',
  ItemName = 'dirtymoney',
}

-- Each entry can optionally define propModel for the handoff.
Config.Drugs = {
  { item = 'kq_weed_bag_og_kush', label = 'Baggie of OG Kush', amtMin = 1, amtMax = 3, priceMin = 15,  priceMax = 30, weight = 50, propModel = `xm3_prop_xm3_bag_weed_01a` },
  { item = 'kq_weed_bag_purple_haze', label = 'Baggie of Purple Haze', amtMin = 1, amtMax = 3, priceMin = 15,  priceMax = 30, weight = 50, propModel = `xm3_prop_xm3_bag_weed_01a` },
  { item = 'kq_weed_bag_white_widow', label = 'Baggie of White Widow', amtMin = 1, amtMax = 3, priceMin = 15,  priceMax = 30, weight = 50, propModel = `xm3_prop_xm3_bag_weed_01a` },
  { item = 'kq_weed_bag_blue_dream', label = 'Baggie of Blue Dream', amtMin = 1, amtMax = 3, priceMin = 15,  priceMax = 30, weight = 50, propModel = `xm3_prop_xm3_bag_weed_01a` },

  { item = 'kq_weed_brick_og_kush', label = 'Brick of OG Kush', amtMin = 1, amtMax = 2, priceMin = 210, priceMax = 500, weight = 20, propModel = `hei_prop_heist_weed_block_01b` },
  { item = 'kq_weed_brick_purple_haze', label = 'Brick of Purple Haze', amtMin = 1, amtMax = 2, priceMin = 210, priceMax = 500, weight = 20, propModel = `hei_prop_heist_weed_block_01b` },
  { item = 'kq_weed_brick_white_widow', label = 'Brick of White Widow', amtMin = 1, amtMax = 2, priceMin = 210, priceMax = 500, weight = 20, propModel = `hei_prop_heist_weed_block_01b` },
  { item = 'kq_weed_brick_blue_dream', label = 'Brick of Blue Dream', amtMin = 1, amtMax = 2, priceMin = 210, priceMax = 500, weight = 20, propModel = `hei_prop_heist_weed_block_01b` },
}


Config.Exchange = {
  animDict = 'mp_common',
  animGive = 'givetake1_a',

  defaultDrugPropModel = `prop_meth_bag_01`,
  cashPropModel = `prop_cash_pile_02`,

  playerHandBone = 57005,
  pedHandBone = 18905,

  propOffset = vec3(0.12, 0.02, -0.02),
  propRot = vec3(10.0, 90.0, 0.0),

  durationMs = { min = 1800, max = 2600 },
}

Config.BlacklistedPeds = {
  `s_m_y_cop_01`,
  `s_f_y_cop_01`,
  `s_m_y_sheriff_01`,
  `s_f_y_sheriff_01`,
  `s_m_y_hwaycop_01`,
}
