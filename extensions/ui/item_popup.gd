extends "res://ui/menus/shop/item_popup.gd"

signal fantasy_item_bless_button_pressed(item_data)

var _fantasy_bless_button: Button = null

func _ready() -> void:
    _fantasy_setup_bless_button()

func _fantasy_setup_bless_button() -> void:
    if _fantasy_bless_button != null or _buttons == null:
        return
    _fantasy_bless_button = MyMenuButton.new()
    _fantasy_bless_button.name = "FantasyBlessButton"
    _fantasy_bless_button.text = tr("MENU_FANTASY_BLESS")
    _fantasy_bless_button.visible = false
    _buttons.add_child(_fantasy_bless_button)
    if _cancel_button != null:
        _buttons.move_child(_fantasy_bless_button, _cancel_button.get_index())
    var _err = _fantasy_bless_button.connect("pressed", self, "_on_FantasyBlessButton_pressed")

func display_element(element: InventoryElement) -> void:
    .display_element(element)
    if _fantasy_bless_button == null:
        _fantasy_setup_bless_button()
    var item_data: ItemParentData = element.item
    if buttons_enabled and Utils.fa_can_bless_item(item_data, player_index):
        _fantasy_bless_button.text = tr("MENU_FANTASY_BLESS")
        _fantasy_bless_button.show()
    elif _fantasy_bless_button != null:
        _fantasy_bless_button.hide()
    _fantasy_update_buttons_focus_neighbors()

func display_item_data(item_data: ItemParentData, control: Control) -> void:
    if _fantasy_bless_button == null:
        _fantasy_setup_bless_button()
    if _fantasy_bless_button != null:
        _fantasy_bless_button.hide()
    .display_item_data(item_data, control)

func will_show_buttons_when_focused(item_data: Resource) -> bool:
    return .will_show_buttons_when_focused(item_data) or (
        buttons_enabled and Utils.fa_can_bless_item(item_data, player_index)
    )

func focus() -> void:
    if _item_data is WeaponData or (_item_data is ItemData and (can_item_be_discarded(_item_data) or Utils.fa_can_bless_item(_item_data, player_index))):
        _fantasy_update_buttons_focus_neighbors()
        _buttons.show()
        for button in _buttons.get_children():
            if button.visible:
                Utils.focus_player_control(button, player_index)
                break

func _fantasy_update_buttons_focus_neighbors() -> void:
    if _buttons == null:
        return
    var visible_buttons: Array = []
    for child in _buttons.get_children():
        if child is Control and child.visible:
            visible_buttons.append(child)
    var count: int = visible_buttons.size()
    for i in range(count):
        var btn: Control = visible_buttons[i]
        var prev_btn: Control = visible_buttons[(i - 1 + count) % count]
        var next_btn: Control = visible_buttons[(i + 1) % count]
        btn.focus_neighbour_top = btn.get_path_to(prev_btn)
        btn.focus_neighbour_bottom = btn.get_path_to(next_btn)

func _on_FantasyBlessButton_pressed() -> void:
    if not buttons_enabled:
        return
    emit_signal("fantasy_item_bless_button_pressed", _item_data)
