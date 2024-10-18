

local not_showed = true

if mods["space-exploration"] then
	not_showed = false
end



data:extend{
	{   
        type = "bool-setting",
        name = "Cheaper-Teleporter",
		order = "b",
		hidden = not_showed,
		setting_type = "startup",
		default_value = false
	},
}