extends Control

const BASE_SCROLL_SPEED: float = 45.0
const FAST_SCROLL_MULTIPLIER: float = 4.0
const NORMAL_SCROLL_MULTIPLIER: float = 1.0
const INITIAL_VERTICAL_OFFSET: float = 20.0

const ACTION_CANCEL: StringName = &"ui_cancel"
const ACTION_FAST_FORWARD: StringName = &"ui_accept"
const MAIN_MENU_SCENE_PATH: String = "res://src/scenes/levels/Start_Menu.tscn"

const KEY_ROLE: String = "role"
const KEY_CONTRIBUTORS: String = "contributors"
const DEFAULT_EMPTY_TEXT: String = ""

const BBCODE_CENTER_OPEN: String = "[center]"
const BBCODE_CENTER_CLOSE: String = "[/center]"
const BBCODE_ROLE_FORMAT: String = "\n\n[color=#f2e8c9][b]%s[/b][/color]\n"
const BBCODE_NAME_FORMAT: String = "[color=#c2b59b]%s[/color]\n"

const CREDITS_SECTIONS: Array[Dictionary] = [
	{
		KEY_ROLE: "DIRECCION DE JUEGO",
		KEY_CONTRIBUTORS: ["Ignacio R"]
	},
	{
		KEY_ROLE: "ARQUITECTURA DE SOFTWARE",
		KEY_CONTRIBUTORS: ["Ignacio R"]
	},
	{
		KEY_ROLE: "DISEÑO DE NIVELES",
		KEY_CONTRIBUTORS: ["Ignacio R"]
	},
	{
		KEY_ROLE: "ARTE DE PERSONAJES E ITEMS",
		KEY_CONTRIBUTORS: [
			"Free Swordsman Character Pack - CraftPix.net",
			"2D Pixel Item Assets - CraftPix.net"
		]
	},
	{
		KEY_ROLE: "ARTE DE ENTORNOS",
		KEY_CONTRIBUTORS: [
			"Beach and Caves Tileset - AxulArt (CC BY 4.0)"
		]
	},
	{
		KEY_ROLE: "INTERFAZ Y EFECTOS VISUALES",
		KEY_CONTRIBUTORS: [
			"Pixel Progress Bar Pack - catshaped (CC BY-SA 4.0)",
			"Clock Pixel Art - Bont",
			"Free Effect and Bullet 16x16 - BDragon1727"
		]
	},
	{
		KEY_ROLE: "TIPOGRAFIA",
		KEY_CONTRIBUTORS: [
			"Kenney Pixel - Kenney (CC BY-SA 3.0)"
		]
	},
	{
		KEY_ROLE: "EFECTOS DE SONIDO",
		KEY_CONTRIBUTORS: ["Biblioteca de Audio Libre"]
	},
	{
		KEY_ROLE: "MOTOR DE JUEGO",
		KEY_CONTRIBUTORS: ["Godot Engine 4"]
	},
	{
		KEY_ROLE: "AGRADECIMIENTOS ESPECIALES",
		KEY_CONTRIBUTORS: ["Academia Pira", "Elias Escalante"]
	}
]

@onready var clip_container: Control = $ClipContainer
@onready var credits_text: RichTextLabel = $ClipContainer/CreditsText

func _ready() -> void:
	get_tree().paused = false
	if not validate_required_nodes():
		push_error("Faltan nodos requeridos en la escena Credits")
		return
		
	populate_credits_content()
	call_deferred(&"initialize_scroll_position")

func validate_required_nodes() -> bool:
	return is_instance_valid(clip_container) and is_instance_valid(credits_text)

func populate_credits_content() -> void:
	var compiled_text: String = BBCODE_CENTER_OPEN
	
	for section in CREDITS_SECTIONS:
		compiled_text += format_section_block(section)
		
	compiled_text += BBCODE_CENTER_CLOSE
	credits_text.text = compiled_text

func format_section_block(section: Dictionary) -> String:
	var role_title: String = section.get(KEY_ROLE, DEFAULT_EMPTY_TEXT)
	var contributors: Array = section.get(KEY_CONTRIBUTORS, [])
	var block_text: String = BBCODE_ROLE_FORMAT % role_title
	
	for contributor_name in contributors:
		block_text += BBCODE_NAME_FORMAT % String(contributor_name)
		
	return block_text

func initialize_scroll_position() -> void:
	credits_text.position.y = clip_container.size.y + INITIAL_VERTICAL_OFFSET

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_CANCEL):
		return_to_main_menu()

func _process(delta: float) -> void:
	if not validate_required_nodes():
		return
		
	advance_credits_scroll(delta)
	check_scroll_completion()

func advance_credits_scroll(delta: float) -> void:
	var speed_multiplier: float = resolve_scroll_multiplier()
	var vertical_displacement: float = BASE_SCROLL_SPEED * speed_multiplier * delta
	credits_text.position.y -= vertical_displacement

func resolve_scroll_multiplier() -> float:
	var multiplier_map: Dictionary = {
		true: FAST_SCROLL_MULTIPLIER,
		false: NORMAL_SCROLL_MULTIPLIER
	}
	var is_fast_forward_active: bool = Input.is_action_pressed(ACTION_FAST_FORWARD)
	return multiplier_map.get(is_fast_forward_active, NORMAL_SCROLL_MULTIPLIER)

func check_scroll_completion() -> void:
	var completion_threshold: float = -credits_text.size.y
	if credits_text.position.y < completion_threshold:
		return_to_main_menu()

func _on_back_button_pressed() -> void:
	return_to_main_menu()

func return_to_main_menu() -> void:
	if not ResourceLoader.exists(MAIN_MENU_SCENE_PATH):
		push_error("Ruta de Menu Principal inexistente: " + MAIN_MENU_SCENE_PATH)
		return
		
	set_process(false)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
