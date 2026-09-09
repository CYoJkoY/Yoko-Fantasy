extends Node

var checks = 0
var failures = []

func _ready():
    if !OS.get_cmdline_args().has("--fantasy-regression"):
        return
    if OS.get_user_data_dir().find("Fantasy-Mechanics-Test") < 0:
        printerr("Fantasy regression refused: use the documented isolated user directory.")
        return
    call_deferred("run_tests")

func check(condition: bool, label: String):
    checks += 1
    if !condition:
        failures.append(label)
        printerr("FANTASY_FAIL ", label)

func prepare():
    RunData.reset()
    RunData.set_player_count(2, true)
    RunData.set_coop_run(true)
    CoopService.connected_players = [[0, 0], [1, 0]]
    TempStats.reset()
    LinkedStats.reset()
    for i in range(2):
        RunData.add_character(ItemService.characters[0], i)
    Utils.reset_stat_caches()

func make_player(player_index: int):
    # The real extended Player script, without a wave scene or physics callbacks.
    var player = load("res://entities/units/player/player.gd").new()
    player.player_index = player_index
    return player

func pick_souls(player, count: int):
    var soul = ConsumableData.new()
    soul.my_id = "consumable_fantasy_soul"
    soul._generate_hashes()
    for _i in range(count):
        player._fantasy_add_stat_when_pickup_consumable(soul)

func test_erosion_ownership():
    prepare()
    var behavior = load("res://mods-unpacked/Yoko-Fantasy/content/effect_behaviors/enemy/erosion/erosion_enemy_effect_behavior.gd").new()
    var timer = Timer.new()
    add_child(timer)
    behavior.timer = timer
    var source = Keys.generate_hash("fantasy_regression_erosion")
    behavior.fa_try_add_erosion(0, 10, [], 1.0, 3, 0.5, 0.0, 1.5, source)
    behavior.fa_try_add_erosion(0, 10, [], 1.0, 3, 0.5, 0.0, 1.5, source)
    check(behavior.active_erosions.size() == 1 and behavior.active_erosions[0].stacks == 2, "same player's source still stacks")
    behavior.fa_try_add_erosion(1, 40, [], 1.0, 3, 0.5, 1.0, 2.0, source)
    check(behavior.active_erosions.size() == 2, "coop players retain separate erosion stacks")
    if behavior.active_erosions.size() == 2:
        var second = behavior.active_erosions[1]
        check(second.player_index == 1, "second player's damage attribution")
        check(second.damage == 40 and second.crit_chance == 1.0 and second.crit_damage == 2.0, "second player's damage and crit scaling")
    timer.stop()
    timer.queue_free()
    behavior.free()

func set_pickup_effects(effects: Array):
    RunData.players_data[0].effects[Utils.fantasy_add_stat_when_pickup_consumable_hash] = effects

func test_pickup_progress():
    prepare()
    var effect = [Utils.consumable_fantasy_soul_hash, 12, Utils.stat_fantasy_holy_hash, 1]
    set_pickup_effects([effect])
    var before = RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0)
    var player = make_player(0)
    pick_souls(player, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == before, "no early Cardinal reward")
    player.free()
    player = make_player(0) # A new Player is created for the next wave.
    pick_souls(player, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == before + 1, "Cardinal keeps partial progress across waves")
    pick_souls(player, 6)
    var original = RunData.players_data[0]
    var copied = original.duplicate()
    # JSON round-trip is essential: Dictionary integer keys become strings.
    var data = JSON.parse(to_json(original.serialize())).result
    var restored = load("res://singletons/player_run_data.gd").new().deserialize(data)
    RunData.players_data[0] = restored
    set_pickup_effects([effect])
    player.free()
    player = make_player(0)
    var resume_before = RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0)
    pick_souls(player, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == resume_before + 1, "Cardinal keeps partial progress after JSON save/resume")
    RunData.players_data[0] = copied
    player.free()
    player = make_player(0)
    pick_souls(player, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == resume_before + 1, "duplicated player data retains independent progress")
    if original.get("fantasy_consumable_pickup_counts") != null:
        check(original.fantasy_consumable_pickup_counts.get("consumable_fantasy_soul") == 18, "duplicate mutations do not change the original counter")
    player.free()

    # A save made before this field existed must still deserialize normally.
    var legacy_data = data.duplicate(true)
    legacy_data.erase("fantasy_consumable_pickup_counts")
    RunData.players_data[0] = load("res://singletons/player_run_data.gd").new().deserialize(legacy_data)
    set_pickup_effects([effect])
    player = make_player(0)
    var legacy_before = RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0)
    pick_souls(player, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == legacy_before, "legacy saves start with empty pickup progress")
    pick_souls(player, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == legacy_before + 1, "legacy saves can earn new pickup rewards")
    player.free()

    prepare()
    var first = [Utils.consumable_fantasy_soul_hash, 2, Utils.stat_fantasy_holy_hash, 1]
    var second = [Utils.consumable_fantasy_soul_hash, 2, Keys.stat_armor_hash, 1]
    set_pickup_effects([first, second])
    player = make_player(0)
    var holy_before = RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0)
    var armor_before = RunData.get_player_effect(Keys.stat_armor_hash, 0)
    pick_souls(player, 1)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == holy_before and RunData.get_player_effect(Keys.stat_armor_hash, 0) == armor_before, "one pickup is not counted once per effect")
    pick_souls(player, 1)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 0) == holy_before + 1 and RunData.get_player_effect(Keys.stat_armor_hash, 0) == armor_before + 1, "both pickup effects receive the same threshold reward")
    player.free()

    prepare()
    set_pickup_effects([effect])
    RunData.players_data[1].effects[Utils.fantasy_add_stat_when_pickup_consumable_hash] = [effect]
    var other_before = RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 1)
    player = make_player(0)
    var other = make_player(1)
    pick_souls(player, 6)
    pick_souls(other, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 1) == other_before, "coop pickup counters are independent")
    pick_souls(other, 6)
    check(RunData.get_player_effect(Utils.stat_fantasy_holy_hash, 1) == other_before + 1, "coop partner earns their own pickup reward")
    player.free()
    other.free()

func run_tests():
    yield(get_tree().create_timer(0.2), "timeout")
    test_erosion_ownership()
    test_pickup_progress()
    print("CC_RESULT ", to_json({"checks": checks, "failures": failures}))
    get_tree().quit(0 if failures.empty() else 1)
