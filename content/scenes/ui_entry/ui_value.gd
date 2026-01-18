extends HBoxContainer

onready var value_label = $ValueLabel
onready var icon = $Icon


func _ready()->void :
    value_label.set_message_translation(false)


func update_value(value: int)->void :
    visible = value
    value_label.text = str(value)
