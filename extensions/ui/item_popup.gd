extends "res://ui/menus/shop/item_popup.gd"

signal fantasy_item_bless_button_pressed(item_data)

var _fantasy_bless_button: Button = null

# ══════════════════════════════════════════ Lifecycle ══════════════════════════════════════════ #
func _ready() -> void:
    _fantasy_setup_bless_button()

# ══════════════════════════════════════════ Setup ══════════════════════════════════════════ #
func _fantasy_get_buttons_container() -> Node:
    if _combine_button != null and _combine_button.get_parent() != null:
        return _combine_button.get_parent()
    if _cancel_button != null and _cancel_button.get_parent() != null:
        return _cancel_button.get_parent()
    return null

func _fantasy_setup_bless_button() -> void:
    if _fantasy_bless_button != null:
        return

    var container: Node = _fantasy_get_buttons_container()
    if container == null:
        return

    _fantasy_bless_button = MyMenuButton.new()
    _fantasy_bless_button.name = "FantasyBlessButton"
    _fantasy_bless_button.text = tr("MENU_FANTASY_BLESS")
    _fantasy_bless_button.visible = false
    _fantasy_bless_button.focus_mode = FOCUS_NONE

    container.add_child(_fantasy_bless_button)

    # 插到 CancelButton 之前（DiscardButton 与 CancelButton 之间）
    if _cancel_button != null and _cancel_button.get_parent() == container:
        container.move_child(_fantasy_bless_button, _cancel_button.get_index())

    var _err = _fantasy_bless_button.connect("pressed", self, "_on_FantasyBlessButton_pressed")


# ══════════════════════════════════════════ Visibility Override ══════════════════════════════════════════ #

# 父类在 _set_buttons_enabled / display_item_data / focus / hide 里都会调这个方法，
# 重写它就能一次性接管 bless 按钮的显示时机。
func _update_button_visibilities() -> void:
    ._update_button_visibilities()
    _fantasy_update_bless_button_visibility()


func _fantasy_update_bless_button_visibility() -> void:
    if _fantasy_bless_button == null:
        _fantasy_setup_bless_button()
    if _fantasy_bless_button == null:
        return

    var should_show: bool = (
        buttons_enabled
        and _item_data != null
        and Utils.fa_can_bless_item(_item_data, player_index)
        and (not RunData.is_coop_run or _focused)
    )

    # 与父类一致：锁定当前武器时隐藏所有交互按钮
    if RunData.get_player_effect_bool(Keys.lock_current_weapons_hash, player_index):
        should_show = false

    _fantasy_bless_button.visible = should_show
    _fantasy_bless_button.focus_mode = FOCUS_ALL if (should_show and _focused) else FOCUS_NONE

    _fantasy_update_buttons_focus_neighbors()


# 父类只对 WeaponData 返回 true，导致可祝福的 ItemData 永远不显示按钮区。
# 这里扩展为"武器 或 可祝福物品"。
func should_show_buttons(item_data: ItemParentData, focused: bool) -> bool:
    if.should_show_buttons(item_data, focused):
        return true
    return (
        buttons_enabled
        and item_data != null
        and Utils.fa_can_bless_item(item_data, player_index)
        and (not RunData.is_coop_run or focused)
    )


func will_show_buttons_when_focused(item_data: ItemParentData) -> bool:
    return should_show_buttons(item_data, true)


# ══════════════════════════════════════════ Focus / Hide ══════════════════════════════════════════ #
func focus() -> void:
    .focus()
    _fantasy_update_bless_button_visibility()


func hide(_player_index: int = -1) -> void:
    .hide(_player_index)
    _fantasy_update_bless_button_visibility()


# ══════════════════════════════════════════ Focus Neighbours ══════════════════════════════════════════ #
func _fantasy_update_buttons_focus_neighbors() -> void:
    var container: Node = _fantasy_get_buttons_container()
    if container == null:
        return

    var visible_buttons: Array = []
    for child in container.get_children():
        if child is Control and child.visible and child.focus_mode != FOCUS_NONE:
            visible_buttons.append(child)

    var count: int = visible_buttons.size()
    if count == 0:
        return

    for i in range(count):
        var btn: Control = visible_buttons[i]
        var prev_btn: Control = visible_buttons[(i - 1 + count) % count]
        var next_btn: Control = visible_buttons[(i + 1) % count]
        btn.focus_neighbour_top = btn.get_path_to(prev_btn)
        btn.focus_neighbour_bottom = btn.get_path_to(next_btn)


# ══════════════════════════════════════════ Signal ══════════════════════════════════════════ #
func _on_FantasyBlessButton_pressed() -> void:
    if not buttons_enabled:
        return
    emit_signal("fantasy_item_bless_button_pressed", _item_data)
