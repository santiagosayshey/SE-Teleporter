
local recipe_ingredients= {}


if mods["Krastorio2"]	 then
  recipe_ingredients= {
    { "rare-metals", 1000 },
    { "imersium-beam", 200 },
    { "ai-core", 100},
    { "matter-stabilizer", 100 },
    { "kr-planetary-teleporter", 1 },
  }
else
  recipe_ingredients = {
    {"processing-unit", 500},
    {"advanced-circuit", 500},
    {"electric-engine-unit", 200},
    {"rocket-control-unit", 100},
    {"steel-plate", 1000}
  }
end



data:extend({
    {
        type = "recipe",
        name = "interplanetary-teleporter",
        energy_required = 60,
        category = "advanced-crafting",
        enabled = false,
        ingredients = recipe_ingredients,
        result = "interplanetary-teleporter",
      }
})