local gui = require("__flib__.gui")
local on_tick_n = require("__flib__.on-tick-n")


local interplanetary_teleporter = require("scripts.interplanetary-teleporter")

-- BOOTSTRAP

script.on_init(function()
  -- Initialize libraries
  on_tick_n.init()

  -- Initialize `global` table
  interplanetary_teleporter.init()

  -- Initialize turret
  if not game.forces["internal-turrets"] then
    game.create_force("internal-turrets")
  end
  


end)

-- ENTITY

script.on_event({
  defines.events.on_built_entity,
  defines.events.on_entity_cloned,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}, function(e)
  local entity = e.entity or e.created_entity or e.destination
  if not entity or not entity.valid then
    return
  end
  local entity_name = entity.name

  -- Clean up cloned internal entities
  if
    e.name == defines.events.on_entity_cloned
    and (
      entity_name == "interplanetary-teleporter-front-layer"
      or entity_name == "interplanetary-teleporter-turret"
      or string.find(entity_name, "interplanetary-teleporter-collision", nil, true)
    )
  then
    entity.destroy()
    return
  end
  if entity_name == "interplanetary-teleporter" then
    interplanetary_teleporter.build(entity, e.tags)
  end
end)

script.on_event({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}, function(e)
  local entity = e.entity
  if not entity or not entity.valid then
    return
  end
  local entity_name = entity.name
  if entity_name == "interplanetary-teleporter" then
    interplanetary_teleporter.destroy(entity)
  end
end)

-- GUI

local function handle_gui_event(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "interplanetary_teleporter" then
      interplanetary_teleporter.handle_gui_action(msg, e)
    end
    return true
  end
  return false
end

gui.hook_events(handle_gui_event)

script.on_event(defines.events.on_gui_opened, function(e)
  if not handle_gui_event(e) then
    local entity = e.entity
    if entity and entity.valid then
      local player = game.get_player(e.player_index)
      if not player then
        return
      end
      local name = entity.name
      if name == "interplanetary-teleporter" then
        interplanetary_teleporter.create_gui(player, entity)
      end
    end
  end
end)

script.on_event("linked-focus-search", interplanetary_teleporter.on_focus_search)

-- PLAYER
script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  interplanetary_teleporter.request_translation(player)
end)

script.on_event(defines.events.on_player_removed, function(e)
  interplanetary_teleporter.clean_up_player(e.player_index)
end)


script.on_event(defines.events.on_player_setup_blueprint, function(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end

  -- Get blueprint
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
    if not bp or not bp.valid_for_read then
      return
    end
    if bp.type == "blueprint-book" then
      local item_inventory = bp.get_inventory(defines.inventory.item_main)
      if item_inventory then
        bp = item_inventory[bp.active_index]
      else
        return
      end
    end
  end

  -- Get blueprint entities and mapping
  local entities = bp.get_blueprint_entities()
  if not entities then
    return
  end
  local mapping = e.mapping.get()

  -- Iterate each entity
  local changed_entity = false
  for i = 1, #entities do
    local entity = entities[i]
    local entity_name = entity.name
    if entity_name == "interplanetary-teleporter" then
      changed_entity = true
      interplanetary_teleporter.setup_blueprint(entity, mapping[i])
    end
  end

  -- Set entities
  if changed_entity then
    bp.set_blueprint_entities(entities)
  end
end)

script.on_event(defines.events.on_string_translated, interplanetary_teleporter.on_string_translated)

-- TICKS AND TRIGGERS

script.on_event(defines.events.on_script_trigger_effect, function(e)
  if e.effect_id == "interplanetary-teleporter-character-trigger" then
    interplanetary_teleporter.update_players_in_range(e.source_entity, e.target_entity)
  end
end)

script.on_event(defines.events.on_tick, function()
  -- NOTE: These two are out of order on purpose, update_gui_statuses() must run first
  interplanetary_teleporter.update_gui_statuses()
  interplanetary_teleporter.update_all_destination_availability()
end)

