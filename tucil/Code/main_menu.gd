extends Control

static var game_started := false

func _ready() -> void:
	if game_started:
		hide()
	else:
		open_menu()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()

	if visible:
		if $Settings.visible:
			_on_back_pressed()         
		elif game_started:
			close_menu()                
	elif game_started and not get_tree().paused:
		open_menu()                    

func open_menu() -> void:
	show()
	$Menu.show()
	$Settings.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_menu() -> void:
	hide()
	get_tree().paused = false

func _on_start_pressed() -> void:
	game_started = true
	close_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	$Menu.hide()
	$Settings.show()

func _on_back_pressed() -> void:
	$Menu.show()
	$Settings.hide()
