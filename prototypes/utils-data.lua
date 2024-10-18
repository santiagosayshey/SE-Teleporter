local styles = data.raw["gui-style"]["default"]

-- GUI

styles.inter_selected_frame_action_button = {
  type = "button_style",
  parent = "frame_action_button",
  default_font_color = button_hovered_font_color,
  default_graphical_set = {
    base = { position = { 225, 17 }, corner_size = 8 },
    shadow = { position = { 440, 24 }, corner_size = 8, draw_type = "outer" },
  },
  hovered_font_color = button_hovered_font_color,
  hovered_graphical_set = {
    base = { position = { 369, 17 }, corner_size = 8 },
    shadow = { position = { 440, 24 }, corner_size = 8, draw_type = "outer" },
  },
  clicked_font_color = button_hovered_font_color,
  clicked_graphical_set = {
    base = { position = { 352, 17 }, corner_size = 8 },
    shadow = { position = { 440, 24 }, corner_size = 8, draw_type = "outer" },
  },
}

styles.interplanetary_teleporter_destinations_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  width = 600,
  minimal_height = 257 * 2,
  background_graphical_set = {
    position = { 282, 17 },
    corner_size = 8,
    overall_tiling_vertical_size = 257 - 12,
    overall_tiling_vertical_spacing = 12,
    overall_tiling_vertical_padding = 6,
    overall_tiling_horizontal_size = 200 - 12,
    overall_tiling_horizontal_spacing = 12,
    overall_tiling_horizontal_padding = 6,
  },
}

styles.interplanetary_teleporter_destinations_scroll_pane = {
  type = "scroll_pane_style",
  parent = "filter_scroll_pane",
  bottom_margin = 12,
  bottom_padding = 0,
  extra_bottom_padding_when_activated = 0,
  height = 257 * 2,
  graphical_set = {
    base = { position = { 85, 0 }, corner_size = 8, draw_type = "outer" },
    shadow = default_inner_shadow,
  },
}

styles.interplanetary_teleporter_destination_minimap = {
  type = "minimap_style",
  size = 176,
}

styles.interplanetary_teleporter_destination_minimap_button = {
  type = "button_style",
  parent = "button",
  size = 176,
  default_graphical_set = {},
  hovered_graphical_set = {
    base = { position = { 81, 80 }, size = 1, opacity = 0.7 },
  },
  clicked_graphical_set = { position = { 70, 146 }, size = 1, opacity = 0.7 },
  disabled_graphical_set = {},
}

styles.interplanetary_teleporter_destination_name_button = {
  type = "button_style",
  parent = "train_status_button",
  width = 176,
  disabled_font_color = styles.list_box_item.default_font_color,
  disabled_graphical_set = styles.list_box_item.default_graphical_set,
}

styles.interplanetary_teleporter_destination_charge_bar = {
  type = "progressbar_style",
  width = 176,
  top_margin = -2,
}

styles.inter_subheader_bold_label = {
  type = "label_style",
  parent = "subheader_caption_label",
  font_color = default_font_color,
}

--TIPS AND TRICKS

data:extend({
  {
    type = "tips-and-tricks-item",
    name = "interplanetary-teleporter",
    order = "l",
    trigger = {
      type = "research",
      technology = "interplanetary-teleporter",
    },
    indent = 1,
    image = "__interplanetary-krastorio__/graphics/gui/tip&tricks/planetary-teleporter-tip&tricks.png",
  }
})

-- CUSTOM INPUT

data:extend(
{
    {
      type = "custom-input",
      name = "linked-focus-search",
      key_sequence = "",
      linked_game_control = "focus-search",
    },
})

-- SOUND

data:extend(
{
  {
      type = "sound",
      name = "interplanetary-teleporter-effect-sound",
      category = "alert",
      filename = "__interplanetary-krastorio__/sounds/planetary-teleporter-effect-sound.ogg",
      volume = 2.0,
      audible_distance_modifier = 2.0,
      aggregation = {
        max_count = 2,
        remove = true,
        count_already_playing = true,
      },
    },
})
