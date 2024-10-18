local table = require("__flib__.table")

-- Make characters be targeted by the teleporter turrets
for _, character in pairs(data.raw["character"]) do
  local mask = character.trigger_target_mask or { "common", "ground-unit" }
  character.trigger_target_mask = mask

  -- FIXME: Use a proper name
  table.insert(mask, "character")
end

-- if space exploration override mod change
if mods["space-exploration"] then
  
  data.raw["recipe"]["interplanetary-teleporter"].category = "space-crafting"

  if settings.startup["Cheaper-Teleporter"].value then 
   
    --make interplanetary teleporter cheaper
    data.raw["technology"]["interplanetary-teleporter"].prerequisites = {
      "kr-planetary-teleporter",
      "se-astronomic-science-pack-2",
      "se-energy-science-pack-2",
      "se-material-science-pack-2",
      "se-holmium-solenoid",
      "se-heavy-bearing",
      "se-aeroframe-scaffold",
    }
    data.raw["technology"]["interplanetary-teleporter"].unit = {
      count_formula = 1000,
      ingredients= {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
        {"production-science-pack", 1},
        {"utility-science-pack", 1},
        {"space-science-pack", 1},
        {"se-astronomic-science-pack-2",1},
        {"se-energy-science-pack-2",1},
        {"se-material-science-pack-2",1},
      },
      time = 60
    }
    data.raw["recipe"]["interplanetary-teleporter"].ingredients = {
      {"se-holmium-solenoid", 100},
      {"se-heavy-bearing", 100},
      {"se-aeroframe-scaffold", 100},
    }


  else

    --expansive/default recipe and tech
    data.raw["technology"]["interplanetary-teleporter"].prerequisites = {
      "se-linked-container",
    }
    data.raw["technology"]["interplanetary-teleporter"].unit = {
      count_formula = "5000",
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
        {"production-science-pack", 1},
        {"utility-science-pack", 1},
        {"space-science-pack", 1},
        {"se-astronomic-science-pack-4",1},
        {"se-energy-science-pack-4",1},
        {"se-material-science-pack-4",1},
        {"se-deep-space-science-pack-4",1}
      },
      time = 60
    }

    data.raw["recipe"]["interplanetary-teleporter"].ingredients = {
      { "se-nanomaterial",50},
      { "se-naquium-processor",10},
      { "se-naquium-plate",500},
      { "se-heavy-assembly",100},
    }
  end
end
