# Custom options control so I can change colors
class_name CustomOptions
extends Control

@export var option_button: OptionButton
@export var custom_popup: Popup
@export var item_list: ItemList

const popup_margin_from_edge : int = 5

func _ready():
	option_button.pressed.connect(_on_option_button_pressed)
	item_list.item_selected.connect(_on_item_list_item_selected)
	item_list.size.x = option_button.size.x

func _on_option_button_pressed():
	# Position the custom popup below the OptionButton
	custom_popup.popup()

	# Call deferred so item list size can update
	_update_popup_position_and_size.call_deferred()

func _update_popup_position_and_size():
	custom_popup.size = item_list.size
	var popup_y_pos = option_button.global_position.y + option_button.size.y

	# Move up if it goes off the screen
	popup_y_pos = min(popup_y_pos, Constants.HEIGHT - item_list.size.y - popup_margin_from_edge)

	custom_popup.position = Vector2(option_button.global_position.x, popup_y_pos)



func _on_item_list_item_selected(index: int):
	# Make the option button text right
	option_button.text = item_list.get_item_text(index).substr(2)  # Remove the bullet point
	
	custom_popup.hide()

func add_item_with_color(item_text: String, item_color: Color):
	# Add a new item to the OptionButton and set its color
	item_list.add_item("• " + item_text)
	# Set icon to the radio icon button
	item_list.set_item_tooltip_enabled(-1, false)
	item_list.set_item_custom_fg_color(-1, item_color)

func select(index: int):
	# Select an item in the OptionButton
	if index >= 0 and index < item_list.get_item_count():
		item_list.select(index)
		item_list.item_selected.emit(index)
	else:
		push_error("Index out of bounds for selection: %d" % index)


func get_selected_id() -> int:
	# Get the selected item index
	return item_list.get_selected_items()[0] if item_list.get_selected_items().size() > 0 else 0
