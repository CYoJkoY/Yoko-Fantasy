extends Reference

const CURSED_HUE_SHIFT: float = -0.17


static func tint(color: Color, cursed: bool) -> Color:
    if not cursed:
        return color
    return Color.from_hsv(fposmod(color.h + CURSED_HUE_SHIFT, 1.0), color.s, color.v, color.a)


static func set_gradient(gradient: Gradient, base_colors: PoolColorArray, cursed: bool) -> void:
    var colors: PoolColorArray = PoolColorArray()
    for color in base_colors:
        colors.append(tint(color, cursed))
    gradient.colors = colors
