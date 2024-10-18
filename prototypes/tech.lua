
local tech_ingredients = {}
local tech_prerequisites = {}

if mods["Krastorio2"] then
  tech_ingredients = {
    { "production-science-pack", 1 },
    { "utility-science-pack", 1 },
    { "space-science-pack", 1 },
    { "matter-tech-card", 1 },
    { "advanced-tech-card", 1 },
    { "singularity-tech-card", 1 }
  }
  tech_prerequisites = {"kr-planetary-teleporter"}
else
  tech_ingredients = {
    { "automation-science-pack", 1 },
    { "logistic-science-pack", 1 },
    { "chemical-science-pack", 1 },
    { "production-science-pack", 1 },
    { "utility-science-pack", 1 },
    { "space-science-pack", 1 }
  }
tech_prerequisites = {
  "logistic-science-pack",
  "chemical-science-pack",
  "production-science-pack",
  "space-science-pack"
  }
end


data:extend(
{
  {
    type = "technology",
    name = "interplanetary-teleporter",
    icons = {
      {
          icon = "__interplanetary-krastorio__/graphics/technologies/planetary-teleporter.png",
      }
    },
    icon_size = 256,
    icon_mipmaps = 4,
    effects = {
      {
        type = "unlock-recipe",
        recipe = "interplanetary-teleporter",
      }
    },
    prerequisites = tech_prerequisites,
    unit = {
      count = 5000,
      ingredients = tech_ingredients,
      time = 60,
    },
  }
})
