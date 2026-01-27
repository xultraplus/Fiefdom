extends Control

@onready var name_label = $Panel/NameLabel
@onready var text_label = $Panel/TextLabel
@onready var options_container = $Panel/OptionsContainer

signal option_selected(index: int)

func setup(name: String, text: String, options: Array) -> void:
	name_label.text = name
	text_label.text = text
	
	# Clear options
	for child in options_container.get_children():
		child.queue_free()
		
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)

func _on_option_pressed(index: int) -> void:
	emit_signal("option_selected", index)
	queue_free() # Close dialog
