extends Control

# Controles táctiles para móvil. Cada botón mantiene pulsada una acción de Godot.
const BUTTONS := [
	{"text": "▲", "action": "move_up", "x": 92, "y": -170, "w": 64, "h": 64},
	{"text": "◀", "action": "move_left", "x": 24, "y": -102, "w": 64, "h": 64},
	{"text": "▼", "action": "move_down", "x": 92, "y": -102, "w": 64, "h": 64},
	{"text": "▶", "action": "move_right", "x": 160, "y": -102, "w": 64, "h": 64},
	{"text": "⚔", "action": "player_attack", "x": -170, "y": -130, "w": 76, "h": 76},
	{"text": "E", "action": "interact", "x": -92, "y": -70, "w": 64, "h": 64}
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item in BUTTONS:
		_add_action_button(item)

func _add_action_button(item: Dictionary) -> void:
	var button := Button.new()
	button.text = str(item.text)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(item.w, item.h)
	button.size = Vector2(item.w, item.h)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.08, 0.13, 0.2, 0.72)))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.1, 0.55, 0.75, 0.9)))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.12, 0.25, 0.35, 0.85)))
	# El ancla inferior mantiene los controles visibles en distintas resoluciones.
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if int(item.x) < 0 else Control.PRESET_BOTTOM_LEFT)
	button.position = Vector2(item.x, item.y)
	add_child(button)
	var action := str(item.action)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	button.tree_exiting.connect(func(): Input.action_release(action))

func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.75, 0.88, 1.0, 0.8)
	return style
