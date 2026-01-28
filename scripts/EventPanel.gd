extends Control

signal choice_selected(choice: Global.TaxReformChoice)

@onready var title_label = $Panel/TitleLabel
@onready var speaker_label = $Panel/SpeakerLabel
@onready var text_label = $Panel/TextLabel
@onready var choices_container = $Panel/ChoicesContainer
@onready var description_label = $Panel/DescriptionLabel

var current_event_data: Dictionary = {}

func setup(event_data: Dictionary) -> void:
	current_event_data = event_data

	title_label.text = event_data.get("title", "")
	speaker_label.text = event_data.get("speaker", "")
	text_label.text = event_data.get("text", "")

	# Clear existing choices
	for child in choices_container.get_children():
		child.queue_free()

	# Wait for frame to ensure safe queue_free
	await get_tree().process_frame

	# Create choice buttons
	var choices = event_data.get("choices", [])
	for i in range(choices.size()):
		var choice_data = choices[i]
		var btn = Button.new()
		btn.text = choice_data.get("text", "")
		btn.custom_minimum_size = Vector2(280, 40)
		btn.pressed.connect(_on_choice_pressed.bind(choice_data))
		choices_container.add_child(btn)

		# Add description label below button
		var desc = Label.new()
		desc.text = choice_data.get("description", "")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(280, 60)
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		choices_container.add_child(desc)

func _on_choice_pressed(choice_data: Dictionary) -> void:
	var choice = choice_data.get("choice_type", Global.TaxReformChoice.NONE)
	choice_selected.emit(choice)
	queue_free()

func _on_close_pressed() -> void:
	queue_free()
