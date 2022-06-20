tool
extends Control

const list_scene = preload("res://addons/open_kanban/system/list.tscn")
const card_scene = preload("res://addons/open_kanban/system/card.tscn")
const context_menu = preload("res://addons/open_kanban/system/context_menu.tscn")
onready var hbox = $panel/vbox/scroll/hbox
onready var scroll = $panel/vbox/scroll
onready var drag_view = $drag_view
onready var drag_view_label = $drag_view/panel/title
var drag_component : Object

var data : Dictionary = {"version" : 0.1, "lists" : {}, "settings" : {}} setget set_data

func _ready() -> void:
	print(OTS.translate("WELCOME"))
	self.data = OFS.load_kanban()
	if !InputMap.has_action("ok_left"):
		InputMap.add_action("ok_left")
		var ev = InputEventMouseButton.new()
		ev.button_index = BUTTON_LEFT
		InputMap.action_add_event("ok_left", ev)
		ProjectSettings.save()
	if !InputMap.has_action("ok_right"):
		InputMap.add_action("ok_right")
		var ev = InputEventMouseButton.new()
		ev.button_index = BUTTON_RIGHT
		InputMap.action_add_event("ok_right", ev)
		ProjectSettings.save()

func add_list(title : String = "", index : int = hbox.get_child_count() - 1) -> void:
	var scene = list_scene.instance()
	hbox.add_child(scene)
	hbox.move_child(scene, index)
	if title:
		scene.set_title(title)
	else:
		scene.title_edit()
	push_hscroll()

func push_hscroll() -> void:
	yield(scroll.get_h_scrollbar(), "changed")
	scroll.scroll_horizontal = scroll.get_h_scrollbar().max_value

func push_vscroll() -> void:
	yield(scroll.get_v_scrollbar(), "changed")
	scroll.scroll_vertical = scroll.get_v_scrollbar().max_value

func _input(event) -> void:
	if event.is_action_released("ok_right") and drag_component:
		drag_component.button_down()
	if event is InputEventMouseMotion:
		drag_view.rect_rotation += event.relative.x
		drag_view.rect_rotation = clamp(drag_view.rect_rotation, -45, 45)

func _process(_delta) -> void:
	if drag_view:
		drag_view.rect_global_position = get_global_mouse_position()
		drag_view.rect_rotation = lerp(drag_view.rect_rotation, 0, 0.2)

func set_drag_view(value : Object) -> void:
	if value:
		set_process(true)
		drag_view.rect_rotation = 0
		drag_view.get_child(0).rect_size = drag_view.get_child(0).rect_min_size
		drag_view_label.text = value.box.get_title()
		drag_view.show()
	else:
		set_process(false)
		drag_view.hide()

func _exit_tree() -> void:
	for list in hbox.get_children():
		var list_index = list.get_index()
		if list.name != "add":
			var cards : Dictionary
			for card in list.container.get_children():
				var card_index = card.get_index()
				if card.name != "add":
					cards[card_index] = {"name" : card.get_title()}
			data["lists"][list_index] = {"name" : list.get_title(), "cards" : cards}
	OFS.save_kanban(data)

func set_data(value : Dictionary) -> void:
	for list in value["lists"].keys():
		var list_instance = list_scene.instance()
		hbox.add_child(list_instance)
		list_instance.set_title(value["lists"][list]["name"])
		hbox.move_child(list_instance, int(list))
		for card in value["lists"][list]["cards"].keys():
			list_instance.add_card(value["lists"][list]["cards"][card]["name"], int(card))
	value = data

func show_context_menu(value : Object) -> void:
	var scene = context_menu.instance()
	add_child(scene)
	scene.target = value
