local gui = require("__flib__.gui")
local position = require("__flib__.position")

local interplanetary_teleporter = {}

--- @param player LuaPlayer
--- @param from LuaEntity
--- @param to LuaEntity
local function teleport_player(player, from, to)
  -- Discharge both entities
  from.energy = 0
  to.energy = 0
  -- Teleport player
  local position = to.position
  position.y = position.y + 1.1
  player.teleport(position, to.surface)
  -- Play sounds
  from.surface.play_sound({
    path = "interplanetary-teleporter-effect-sound",
    volume_modifier = 0.8,
    position = from.position,
  })
  to.surface.play_sound({
    path = "interplanetary-teleporter-effect-sound",
    position = to.position,
    volume_modifier = 1,
  })
end

-- GUI

local status_labels = {}
for label, i in pairs(defines.entity_status) do
  status_labels[i] = string.gsub(label, "_", "-")
end

local status_images = {
  [defines.entity_status.charging] = "status_yellow",
  [defines.entity_status.disabled_by_script] = "status_not_working",
  [defines.entity_status.discharging] = "status_not_working",
  [defines.entity_status.low_power] = "status_not_working",
  [defines.entity_status.no_power] = "status_not_working",
}

--- @param state InterPlanetaryTeleporterGuiState
local function update_fully_charged(refs, state)
  local active_warning = state.active_warning

  -- Destination buttons
  local enabled = active_warning and true or false
  for _, destination_frame in ipairs(refs.destinations_table.children) do
    destination_frame.minimap_frame.minimap.ignored_by_interaction = enabled
  end

  -- Subheader
  if active_warning then
    refs.name_label.style = "inter_subheader_bold_label"
    refs.name_label.style.maximal_width = 370
    refs.toolbar.style = "negative_subheader_frame"

    local warning_label = refs.toolbar.warning_label
    warning_label.visible = true
    warning_label.caption = {
      "",
      "[img=utility/warning_white] ",
      { "gui.interplanetary-teleporter-warning-" .. active_warning },
    }
  else
    refs.name_label.style = "subheader_caption_label"
    refs.name_label.style.maximal_width = 370
    refs.toolbar.style = "subheader_frame"
    refs.toolbar.warning_label.visible = false
  end
end

local function update_gui_statuses()
  for player_index, gui_data in pairs(global.interplanetary_teleporter.guis) do
    local refs = gui_data.refs
    local state = gui_data.state
    local entity = state.entity
    local status = entity.status
    -- Workaround for a base game issue where the accumulator won't actually charge all the way sometimes
    -- Round the percent full to a whole percentage to eliminate the game's floating point error
    local percent_full =
      math.ceil((entity.energy / entity.prototype.electric_energy_source_prototype.buffer_capacity) * 100)
    local fully_charged = percent_full == 100

    if status == defines.entity_status.charging or status == defines.entity_status.discharging then
      refs.status_label.caption = {
        "",
        { "entity-status." .. status_labels[status] },
        " - " .. math.floor(percent_full) .. "%",
      }
    elseif fully_charged then
      refs.status_label.caption = { "entity-status.fully-charged" }
    else
      refs.status_label.caption = { "entity-status." .. status_labels[status] }
    end
    refs.status_image.sprite = "utility/" .. (status_images[status] or "status_working")

    -- Warning
    --- @type boolean|string
    local warning = false
    local players = global.interplanetary_teleporter.players[state.entity_data.turret_unit_number] or {}
    if not players[player_index] then
      warning = "not_on_teleporter"
    elseif table_size(players) > 1 then
      warning = "too_many_players"
    elseif not fully_charged then
      warning = "low_power"
    end

    if state.active_warning ~= warning then
      state.active_warning = warning
      update_fully_charged(refs, state)
    end
  end
end

--- @param teleporter_data InterPlanetaryTeleporterData
local function get_destination_properties(teleporter_data)
  local entity = teleporter_data.entities.base
  local charge_value = entity.energy / entity.prototype.electric_energy_source_prototype.buffer_capacity
  local charge_percent = math.ceil(charge_value * 100)
  local fully_charged = charge_percent == 100

  -- Destination blockage
  local destination_blocked = global.interplanetary_teleporter.players[teleporter_data.turret_unit_number] and true or false

  local tooltip
  if fully_charged and not destination_blocked then
    tooltip = "teleport"
  elseif fully_charged then
    tooltip = "destination-blocked"
  else
    tooltip = "low-power"
  end

  return {
    enabled = fully_charged and not destination_blocked,
    tooltip = tooltip,
    charge_percent = charge_percent,
    charge_value = charge_value,
  }
end

--- @param state InterPlanetaryTeleporterGuiState
local function update_destinations_table(refs, state)
  local destinations_table = refs.destinations_table
  local children = destinations_table.children
  local query = state.search_query

  local force = state.player.force
  local force_name = force.name
  local unit_number = state.entity.unit_number
  local player_index = state.player.index
  local pos = state.entity.position
  local unnamed_str = global.interplanetary_teleporter.unnamed_translations[player_index]

  local i = 0
  local shown_teleporters = {}
  for destination_number, data in pairs(global.interplanetary_teleporter.data) do
    local name = data.name or unnamed_str
    if
      destination_number ~= unit_number
      and data.force == force
      and (query == "" or string.find(string.lower(name), query, 1, true))
    then
      i = i + 1
      shown_teleporters[i] = destination_number
      local destination_frame = children[i]
      if not destination_frame then
        local destination_refs = gui.build(destinations_table, {
          {
            type = "frame",
            style = "train_with_minimap_frame",
            direction = "vertical",
            ref = { "frame" },
            {
              type = "frame",
              name = "minimap_frame",
              style = "deep_frame_in_shallow_frame",
              {
                type = "minimap",
                name = "minimap",
                style = "interplanetary_teleporter_destination_minimap",
                surface_index = data.surface.index,
                chart_player_index = player_index,
                force = force_name,
                zoom = 1,
                {
                  type = "button",
                  name = "minimap_button",
                  style = "interplanetary_teleporter_destination_minimap_button",
                  tooltip = { "gui.interplanetary-teleporter-teleport-tooltip" },
                  actions = {
                    on_click = { gui = "interplanetary_teleporter", action = "teleport" },
                  },
                },
              },
            },
            { type = "progressbar", name = "bar", style = "interplanetary_teleporter_destination_charge_bar" },
            {
              type = "frame",
              style = "deep_frame_in_shallow_frame",
              {
                type = "button",
                style = "interplanetary_teleporter_destination_name_button",
                tooltip = { "gui.interplanetary-teleporter-teleport" },
                enabled = false,
              },
            },
          },
        })
        destination_frame = destination_refs.frame
      end

      local distance = math.ceil(position.distance(pos, data.position))
      local name_and_distance = { "gui.interplanetary-teleporter-name-and-distance", data.name or unnamed_str, distance }
      local destination_properties = get_destination_properties(data)

      gui.update(destination_frame, {
        {
          {
            elem_mods = {
              position = data.position,
            },
            {
              cb = function(elem)
                gui.update_tags(elem, { number = destination_number })
              end,
              elem_mods = {
                enabled = destination_properties.enabled,
                tooltip = { "gui.interplanetary-teleporter-" .. destination_properties.tooltip .. "-tooltip" },
              },
            },
          },
        },
        {
          elem_mods = {
            tooltip = destination_properties.charge_percent .. "%",
            value = destination_properties.charge_value,
          },
        },
        {
          {
            elem_mods = {
              caption = name_and_distance,
              tooltip = name_and_distance,
            },
          },
        },
      })
    end
  end

  for j = i + 1, #children do
    children[j].destroy()
  end

  if i > 0 then
    refs.no_destinations_frame.visible = false
  else
    refs.no_destinations_frame.visible = true
  end

  state.shown_teleporters = shown_teleporters
end

local function update_all_destination_tables()
  for _, gui_data in pairs(global.interplanetary_teleporter.guis) do
    update_destinations_table(gui_data.refs, gui_data.state)
  end
end

local function update_all_destination_availability()
  if game.tick % 10 == 0 then
    local teleporters = global.interplanetary_teleporter.data

    -- Assemble availability data
    local properties = {}
    for unit_number, teleporter_data in pairs(teleporters) do
      properties[unit_number] = get_destination_properties(teleporter_data)
    end

    for _, gui_data in pairs(global.interplanetary_teleporter.guis) do
      local refs = gui_data.refs
      local state = gui_data.state

      local destinations_table = refs.destinations_table
      local children = destinations_table.children

      -- The generic update function is too slow - only update the bars and buttons
      for i, unit_number in pairs(state.shown_teleporters) do
        local destination_properties = properties[unit_number]
        local parent = children[i]
        local bar = parent.bar
        bar.value = destination_properties.charge_value
        bar.tooltip = destination_properties.charge_percent .. "%"
        local button = parent.minimap_frame.minimap.minimap_button
        button.enabled = destination_properties.enabled
        button.tooltip = { "gui.interplanetary-teleporter-" .. destination_properties.tooltip .. "-tooltip" }
      end
    end
  end

  -- Reset for the next round of player detection
  global.interplanetary_teleporter.players = {}
end

--- @param player LuaPlayer
--- @param entity LuaEntity
local function create_gui(player, entity)
  local entity_data = global.interplanetary_teleporter.data[entity.unit_number]
  if not entity_data then
    player.opened = nil
    player.print("This teleporter was not built correctly, please remove and re-place it.")
    return
  end
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      ref = { "window" },
      actions = {
        on_closed = { gui = "interplanetary_teleporter", action = "close" },
      },
      children = {
        -- Titlebar
        {
          type = "flow",
          style_mods = { horizontal_spacing = 8 },
          ref = { "titlebar_flow" },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = { "entity-name.interplanetary-teleporter" },
              ignored_by_interaction = true,
            },
            {
              type = "empty-widget",
              style = "draggable_space_header",
              style_mods = { height = 24, horizontally_stretchable = true, right_margin = 4 },
              ignored_by_interaction = true,
            },
            {
              type = "textfield",
              style_mods = { top_margin = -3 },
              visible = false,
              ref = { "search_textfield" },
              actions = {
                on_text_changed = { gui = "interplanetary_teleporter", action = "update_search_query" },
              },
            },
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "utility/search_white",
              hovered_sprite = "utility/search_black",
              clicked_sprite = "utility/search_black",
              tooltip = { "gui.interplanetary-teleporter-search-tooltip" },
              ref = { "search_button" },
              actions = {
                on_click = { gui = "interplanetary_teleporter", action = "toggle_search" },
              },
            },
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              tooltip = { "gui.close-instruction" },
              actions = {
                on_click = { gui = "interplanetary_teleporter", action = "close" },
              },
            },
          },
        },
        -- Content frame
        {
          type = "frame",
          style = "inside_shallow_frame",
          direction = "vertical",
          children = {
            -- Toolbar
            {
              type = "frame",
              style = "subheader_frame",
              ref = { "toolbar" },
              children = {
                {
                  type = "label",
                  style = "subheader_caption_label",
                  style_mods = { maximal_width = 370 },
                  caption = entity_data.name or global.interplanetary_teleporter.unnamed_translations[player.index],
                  ref = { "name_label" },
                },
                {
                  type = "textfield",
                  visible = false,
                  ref = { "name_textfield" },
                  actions = {
                    on_confirmed = { gui = "interplanetary_teleporter", action = "toggle_rename" },
                    on_text_changed = { gui = "interplanetary_teleporter", action = "update_name" },
                  },
                },
                {
                  type = "sprite-button",
                  style = "mini_button_aligned_to_text_vertically_when_centered",
                  sprite = "utility/rename_icon_small_black",
                  tooltip = { "gui.interplanetary-teleporter-rename-tooltip" },
                  actions = {
                    on_click = { gui = "interplanetary_teleporter", action = "toggle_rename" },
                  },
                },
                { type = "empty-widget", style_mods = { horizontally_stretchable = true } },
                {
                  type = "label",
                  name = "warning_label",
                  style = "bold_label",
                  style_mods = { right_padding = 8 },
                  visible = false,
                },
              },
            },
            {
              type = "flow",
              style_mods = { padding = 12, vertical_spacing = 8 },
              direction = "vertical",
              children = {
                -- Entity status line
                {
                  type = "flow",
                  style = "status_flow",
                  style_mods = { vertical_align = "center" },
                  children = {
                    { type = "sprite", style = "status_image", ref = { "status_image" } },
                    { type = "label", ref = { "status_label" } },
                  },
                },
                -- Entity preview
                {
                  type = "frame",
                  style = "deep_frame_in_shallow_frame",
                  children = {
                    { type = "entity-preview", style = "wide_entity_button", elem_mods = { entity = entity } },
                  },
                },
              },
            },
            -- Destinations table
            {
              type = "scroll-pane",
              style = "interplanetary_teleporter_destinations_scroll_pane",
              children = {
                {
                  type = "frame",
                  style = "interplanetary_teleporter_destinations_frame",
                  direction = "vertical",
                  children = {
                    -- Warning frame
                    {
                      type = "frame",
                      style = "negative_subheader_frame",
                      ref = { "no_destinations_frame" },
                      children = {
                        { type = "empty-widget", style_mods = { horizontally_stretchable = true } },
                        {
                          type = "label",
                          style = "bold_label",
                          caption = {
                            "",
                            "[img=utility/warning_white] ",
                            { "gui.interplanetary-teleporter-no-destinations-found" },
                          },
                        },
                        { type = "empty-widget", style_mods = { horizontally_stretchable = true } },
                      },
                    },
                    -- Destinations
                    { type = "table", style = "slot_table", column_count = 3, ref = { "destinations_table" } },
                  },
                },
              },
            },
          },
        },
      },
    },
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  player.opened = refs.window

  --- @class InterPlanetaryTeleporterGui
  local gui_data = {
    refs = refs,
    --- @class InterPlanetaryTeleporterGuiState
    state = {
      --- @type boolean|string
      active_warning = false,
      entity = entity,
      entity_data = entity_data,
      player = player,
      search_query = "",
      shown_teleporters = {},
    },
  }

  global.interplanetary_teleporter.guis[player.index] = gui_data

  update_destinations_table(gui_data.refs, gui_data.state)
  update_fully_charged(gui_data.refs, gui_data.state)
end

-- EVENT HANDLERS

function interplanetary_teleporter.handle_gui_action(msg, e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local gui_data = global.interplanetary_teleporter.guis[e.player_index]
  local refs = gui_data.refs
  local state = gui_data.state

  if msg.action == "close" then
    -- If escape was pressed and search is open, close search instead of closing the window
    if e.element and e.element.type ~= "sprite-button" and refs.search_textfield.visible then
      refs.search_button.style = "frame_action_button"
      refs.search_button.sprite = "utility/search_white"
      refs.search_textfield.visible = false
      refs.search_textfield.text = ""
      state.search_query = ""
      update_destinations_table(refs, state)
      player.opened = refs.window
      return
    end
    if player.opened == refs.window then
      player.opened = nil
    end
    refs.window.destroy()
    global.interplanetary_teleporter.guis[e.player_index] = nil
    player.play_sound({
      path = "entity-close/interplanetary-teleporter",
    })
  elseif msg.action == "toggle_search" then
    local textfield = refs.search_textfield
    local search_button = refs.search_button
    if textfield.visible then
      search_button.style = "frame_action_button"
      search_button.sprite = "utility/search_white"
      textfield.visible = false
      textfield.text = ""
      state.search_query = ""
      update_destinations_table(refs, state)
    else
      search_button.style = "inter_selected_frame_action_button"
      search_button.sprite = "utility/search_black"
      textfield.visible = true
      textfield.focus()
    end
  elseif msg.action == "update_search_query" then
    state.search_query = e.text
    update_destinations_table(refs, state)
  elseif msg.action == "toggle_rename" then
    local textfield = refs.name_textfield
    local label = refs.name_label
    if textfield.visible then
      textfield.visible = false
      label.caption = state.entity_data.name or global.interplanetary_teleporter.unnamed_translations[e.player_index]
      label.visible = true
    else
      textfield.text = state.entity_data.name or ""
      textfield.visible = true
      textfield.focus()
      label.visible = false
    end
  elseif msg.action == "update_name" then
    state.entity_data.name = e.text ~= "" and e.text or nil
  elseif msg.action == "teleport" then
    -- Get info
    local destination_number = gui.get_tags(e.element).number
    local destination_info = global.interplanetary_teleporter.data[destination_number]
    if destination_info then
      local destination_entity = global.interplanetary_teleporter.data[destination_number].entities.base
      local source_entity = state.entity
      -- Close GUI
      refs.window.destroy()
      global.interplanetary_teleporter.guis[e.player_index] = nil
      -- Teleport player
      teleport_player(player, source_entity, destination_entity)
    else
      player.create_local_flying_text({
        text = { "gui.interplanetary-teleporter-invalid" },
        create_at_cursor = true,
      })
      player.play_sound({
        path = "utility/cannot_build",
      })
      update_destinations_table(refs, state)
    end
  end
end

function interplanetary_teleporter.init()
  global.interplanetary_teleporter = {
    --- @type table<uint, InterPlanetaryTeleporterData>
    data = {},
    --- @type table<uint, InterPlanetaryTeleporterGui>
    guis = {},
    --- @type table<uint, table<uint, boolean>>
    players = {},
    --- @type table<uint, string>
    unnamed_translations = {},
  }
  for _, player in pairs(game.players) do
    player.request_translation({ "gui.interplanetary-teleporter-unnamed" })
  end
end

local collision_entity_offsets = {
  { x = 0, y = 0 },
  { x = -2, y = 2 },
  { x = 2, y = 2 },
}

--- @class InterPlanetaryTeleporterEntities
--- @field base LuaEntity
--- @field turret LuaEntity
--- @field collision_1 LuaEntity
--- @field collision_2 LuaEntity
--- @field collision_3 LuaEntity
--- @field front_layer LuaEntity

--- @param base_entity LuaEntity
--- @return InterPlanetaryTeleporterEntities?
local function create_entities(base_entity)
  local entities = {
    base = base_entity,
  }
  local surface = base_entity.surface
  local position = base_entity.position

  -- Building the turret can fail due to AAI vehicles
  entities.turret = surface.create_entity({
    name = "interplanetary-teleporter-turret",
    position = { x = position.x, y = position.y + 1.15 },
    force = "internal-turrets",
    create_build_effect_smoke = false,
    raise_built = true,
  })

  if not entities.turret or not entities.turret.valid then
    game.print(
      "Building interplanetary teleporter failed due to AAI Programmable Vehicles. This teleporter will not function."
    )
    base_entity.active = false
    return
  end

  for i, offset in ipairs(collision_entity_offsets) do
    entities["collision_" .. i] = surface.create_entity({
      name = "interplanetary-teleporter-collision-" .. i,
      position = { x = position.x + offset.x, y = position.y + offset.y },
      create_build_effect_smoke = false,
      raise_built = true,
    })
  end
  entities.front_layer = surface.create_entity({
    name = "interplanetary-teleporter-front-layer",
    position = position,
    create_build_effect_smoke = false,
    raise_built = true,
  })
  for name, entity in pairs(entities) do
    if name ~= "base" then
      entity.destructible = false
    end
  end
  return entities
end

--- @param entity LuaEntity
--- @param tags Tags
function interplanetary_teleporter.build(entity, tags)
  -- If revived from a blueprint and it has a name, get it from the tags
  local name = tags and tags.interplanetary_teleporter_name or nil --[[@as string?]]
  local entities = create_entities(entity)
  if entities then
    --- @class InterPlanetaryTeleporterData
    local data = {
      entities = entities,
      force = entity.force,
      name = name,
      position = entity.position,
      surface = entity.surface,
      turret_unit_number = entities.turret.unit_number,
    }
    global.interplanetary_teleporter.data[entity.unit_number] = data
    update_all_destination_tables()
  end
end

--- @param entity LuaEntity
function interplanetary_teleporter.destroy(entity)
  local unit_number = entity.unit_number --[[@as uint]]
  local data = global.interplanetary_teleporter.data[unit_number]
  -- In case the entity was destroyed immediately (AAI Vehicles)
  if not data then
    return
  end
  -- Destroy other entities
  for _, entity_to_destroy in pairs(data.entities) do
    if entity_to_destroy.valid then
      entity_to_destroy.destroy()
    end
  end
  -- Remove from lists
  global.interplanetary_teleporter.data[unit_number] = nil
  -- Close any open GUIs
  for _, gui_data in pairs(global.interplanetary_teleporter.guis) do
    local other_entity = gui_data.state.entity
    -- If it's invalid we want to destroy the GUI anyway, so side effects here don't matter
    if not other_entity.valid then
      interplanetary_teleporter.handle_gui_action({ action = "close" }, { player_index = gui_data.state.player.index })
    end
  end
  -- Update destinations
  update_all_destination_tables()
end

interplanetary_teleporter.create_gui = create_gui

--- @param e EventData.CustomInputEvent
function interplanetary_teleporter.on_focus_search(e)
  local gui_data = global.interplanetary_teleporter.guis[e.player_index]
  if gui_data then
    interplanetary_teleporter.handle_gui_action({ action = "toggle_search" }, e)
  end
end

--- @param player LuaPlayer
function interplanetary_teleporter.request_translation(player)
  player.request_translation({ "gui.interplanetary-teleporter-unnamed" })
end

--- @param player_index uint
function interplanetary_teleporter.clean_up_player(player_index)
  global.interplanetary_teleporter.unnamed_translations[player_index] = nil
  global.interplanetary_teleporter.guis[player_index] = nil
end

--- @param e EventData.on_string_translated
function interplanetary_teleporter.on_string_translated(e)
  local localised_string = e.localised_string
  if type(localised_string) == "table" and localised_string[1] == "gui.interplanetary-teleporter-unnamed" then
    -- Sometimes the translation might fail - in that case, fall back on the english
    global.interplanetary_teleporter.unnamed_translations[e.player_index] = e.translated and e.result or "<Unnamed>"
  end
end

--- @param entity BlueprintEntity
--- @param real_entity LuaEntity?
function interplanetary_teleporter.setup_blueprint(entity, real_entity)
  if real_entity and real_entity.valid then
    local unit_number = real_entity.unit_number --[[@as uint]]
    local data = global.interplanetary_teleporter.data[unit_number]
    if data and data.name then
      if not entity.tags then
        entity.tags = {}
      end
      entity.tags.interplanetary_teleporter_name = data.name
    end
  end
end

--- @param source LuaEntity
--- @param target LuaEntity
function interplanetary_teleporter.update_players_in_range(source, target)
  if not source.valid or not target.valid then
    return
  end

  local player = target.player
  if not player or not player.valid then
    return
  end
  local player_index = player.index

  local turret_unit_number = source.unit_number --[[@as uint]]
  local players = global.interplanetary_teleporter.players[turret_unit_number]
  if players then
    players[player_index] = true
  else
    global.interplanetary_teleporter.players[turret_unit_number] = { [player_index] = true }
  end
end

function interplanetary_teleporter.update_gui_statuses()
  update_gui_statuses()
end

function interplanetary_teleporter.update_all_destination_availability()
  update_all_destination_availability()
end

return interplanetary_teleporter
