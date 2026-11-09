extends Node3D

var player: CharacterBody3D
var move_axis := Vector2.ZERO
var jump_requested := false
var move_speed := 4.0
var gravity := 18.0
var jump_speed := 6.0
var avatar: Node3D
var bamboo_positions: Array[Vector3] = []
var knocked_down := false
var knock_time := 0.0
var hit_cooldown := 0.0
var message_label: Label
# v0.6: ten short courses, coins, checkpoints and a pause menu.
var current_level := 1
var coins := 0
var score := 0
var paused_game := false
var anim_clock := 0.0
var level_label: Label
var score_label: Label
var pause_button: Button
var restart_button: Button
var next_button: Button
var coin_nodes: Array[Node3D] = []
var bamboo_nodes: Array[Node3D] = []
var checkpoint_z := 0.0
var finish_z := -12.5
var saved_level := 1


func _ready() -> void:
    var ground := StaticBody3D.new()
    ground.position = Vector3(0, -0.25, 0)
    add_child(ground)
    var ground_mesh := MeshInstance3D.new()
    var ground_box := BoxMesh.new()
    ground_box.size = Vector3(30, 0.5, 30)
    ground_mesh.mesh = ground_box
    var grass := StandardMaterial3D.new()
    grass.albedo_color = Color(0.24, 0.55, 0.32)
    ground_mesh.material_override = grass
    ground.add_child(ground_mesh)
    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(30, 0.5, 30)
    ground_collision.shape = ground_shape
    ground.add_child(ground_collision)

    player = CharacterBody3D.new()
    player.position = Vector3(0, 1.5, 0)
    add_child(player)
    var player_collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    player_collision.shape = capsule
    player.add_child(player_collision)
    # Lightweight procedural 3D human: no external model or plugins required.
    avatar = Node3D.new()
    avatar.name = "BossCharacter"
    player.add_child(avatar)
    _build_boss_character()

    var camera := Camera3D.new()
    camera.position = Vector3(0, 5.2, 9.0)
    camera.rotation_degrees.x = -22
    camera.current = true
    player.add_child(camera)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -25, 0)
    add_child(sun)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.53, 0.75, 0.94)
    environment.environment = env
    add_child(environment)
    _create_bamboo()
    _create_village_scenery()
    _create_controls()
    _create_hud()
    _load_progress()
    _start_level(saved_level)

# A stylized approximation based on the approved reference design.
# This is real 3D geometry, but not a photo-scanned face or rigged model.
func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.88
    return material

func _part(part_name: String, shape: Mesh, position_3d: Vector3, color: Color, rotation_3d: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = part_name
    item.mesh = shape
    item.position = position_3d
    item.rotation_degrees = rotation_3d
    item.material_override = _mat(color)
    avatar.add_child(item)
    return item

func _box_part(part_name: String, dimensions: Vector3, where: Vector3, color: Color, angle: Vector3 = Vector3.ZERO) -> void:
    var box_mesh := BoxMesh.new()
    box_mesh.size = dimensions
    _part(part_name, box_mesh, where, color, angle)

func _round_part(part_name: String, radii: Vector3, where: Vector3, color: Color) -> void:
    var sphere_mesh := SphereMesh.new()
    sphere_mesh.radius = 0.5
    sphere_mesh.height = 1.0
    var node := _part(part_name, sphere_mesh, where, color)
    node.scale = radii * 2.0

func _build_boss_character() -> void:
    var skin := Color(0.67, 0.43, 0.30)
    var hair := Color(0.12, 0.085, 0.065)
    var blue := Color(0.10, 0.48, 0.77)
    var jeans := Color(0.11, 0.20, 0.40)
    var white := Color(0.94, 0.94, 0.91)
    # Character faces the bamboo course (negative Z).
    _box_part("Blue patterned shirt", Vector3(0.70, 0.69, 0.33), Vector3(0, 0.03, 0), blue)
    _box_part("Shirt collar left", Vector3(0.21, 0.09, 0.37), Vector3(-0.17, 0.38, -0.02), Color(0.70, 0.87, 0.97), Vector3(0, 0, -18))
    _box_part("Shirt collar right", Vector3(0.21, 0.09, 0.37), Vector3(0.17, 0.38, -0.02), Color(0.70, 0.87, 0.97), Vector3(0, 0, 18))
    for i in range(4):
        _box_part("Shirt detail %d" % i, Vector3(0.045, 0.12, 0.015), Vector3(-0.21 + i * 0.14, 0.06, -0.175), Color(0.54, 0.80, 0.94), Vector3(0, 0, 28))
    _round_part("Neck", Vector3(0.13, 0.13, 0.13), Vector3(0, 0.44, 0), skin)
    _round_part("Head", Vector3(0.29, 0.34, 0.26), Vector3(0, 0.73, -0.01), skin)
    _round_part("Short dark hair", Vector3(0.30, 0.14, 0.27), Vector3(0, 1.00, -0.01), hair)
    _round_part("Beard", Vector3(0.235, 0.125, 0.20), Vector3(0, 0.54, -0.075), hair)
    _round_part("Nose", Vector3(0.05, 0.08, 0.07), Vector3(0, 0.72, -0.273), skin)
    for side in [-1, 1]:
        _round_part("Eye white %d" % side, Vector3(0.062, 0.042, 0.02), Vector3(side * 0.12, 0.80, -0.238), white)
        _round_part("Dark eye %d" % side, Vector3(0.024, 0.031, 0.013), Vector3(side * 0.12, 0.80, -0.256), hair)
        _box_part("Eyebrow %d" % side, Vector3(0.13, 0.024, 0.025), Vector3(side * 0.12, 0.87, -0.237), hair)
        _box_part("Blue sleeve %d" % side, Vector3(0.25, 0.34, 0.29), Vector3(side * 0.45, 0.17, 0), blue, Vector3(0, 0, side * 16))
        _box_part("Forearm %d" % side, Vector3(0.19, 0.34, 0.21), Vector3(side * 0.54, -0.16, 0), skin, Vector3(0, 0, side * 13))
        _box_part("Jeans leg %d" % side, Vector3(0.27, 0.53, 0.31), Vector3(side * 0.19, -0.52, 0), jeans)
        _box_part("White shoe %d" % side, Vector3(0.30, 0.16, 0.43), Vector3(side * 0.19, -0.85, -0.07), white)
    _box_part("Belt", Vector3(0.67, 0.08, 0.35), Vector3(0, -0.33, 0), Color(0.10, 0.09, 0.10))

func _physics_process(delta: float) -> void:
    if player == null:
        return
    if paused_game:
        player.velocity = Vector3.ZERO
        return
    hit_cooldown = maxf(0.0, hit_cooldown - delta)
    if knocked_down:
        knock_time -= delta
        avatar.rotation_degrees.z = lerpf(avatar.rotation_degrees.z, 78.0, minf(delta * 9.0, 1.0))
        player.velocity.x = 0.0
        player.velocity.z = 0.0
        if not player.is_on_floor():
            player.velocity.y -= gravity * delta
        player.move_and_slide()
        if knock_time <= 0.0:
            knocked_down = false
            avatar.rotation_degrees.z = 0.0
            message_label.visible = false
        return
    var axis := move_axis
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        axis.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        axis.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        axis.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        axis.y += 1.0
    axis = axis.limit_length(1.0)
    player.velocity.x = axis.x * move_speed
    player.velocity.z = axis.y * move_speed
    if not player.is_on_floor():
        player.velocity.y -= gravity * delta
    elif jump_requested or Input.is_key_pressed(KEY_SPACE):
        player.velocity.y = jump_speed
    jump_requested = false
    player.move_and_slide()
    _animate_walk(delta, axis)
    _check_coins_and_finish()
    # Subtle motion while walking; keep fall rotation untouched.
    if axis.length() > 0.1 and player.is_on_floor():
        avatar.rotation_degrees.y = lerpf(avatar.rotation_degrees.y, -axis.x * 12.0, minf(delta * 8.0, 1.0))
    else:
        avatar.rotation_degrees.y = lerpf(avatar.rotation_degrees.y, 0.0, minf(delta * 8.0, 1.0))
    if hit_cooldown <= 0.0:
        for bamboo_pos in bamboo_positions:
            if Vector2(player.global_position.x - bamboo_pos.x, player.global_position.z - bamboo_pos.z).length() < 0.95:
                knocked_down = true
                knock_time = 1.8
                hit_cooldown = 2.5
                message_label.text = "BASH! GET UP, BOSS!"
                message_label.visible = true
                score = maxi(0, score - 5)
                _update_hud()
                break

func _create_bamboo() -> void:
    for pos in [Vector3(-2.2, 0.0, -4.0), Vector3(1.8, 0.0, -7.0), Vector3(0.0, 0.0, -10.0)]:
        bamboo_positions.append(pos)
        var pole := MeshInstance3D.new()
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.23
        cylinder.bottom_radius = 0.28
        cylinder.height = 2.8
        pole.mesh = cylinder
        pole.position = pos + Vector3(0.0, 1.4, 0.0)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.27, 0.65, 0.16)
        pole.material_override = mat
        add_child(pole)
        bamboo_nodes.append(pole)
        for y in [0.55, 1.4, 2.25]:
            var ring := MeshInstance3D.new()
            var ring_mesh := CylinderMesh.new()
            ring_mesh.top_radius = 0.3
            ring_mesh.bottom_radius = 0.3
            ring_mesh.height = 0.09
            ring.mesh = ring_mesh
            ring.position = pos + Vector3(0.0, y, 0.0)
            var ring_mat := StandardMaterial3D.new()
            ring_mat.albedo_color = Color(0.14, 0.39, 0.09)
            ring.material_override = ring_mat
            add_child(ring)
            bamboo_nodes.append(ring)


# Lightweight decorative geometry. No new collisions or external assets.
func _scenery_box(size: Vector3, pos: Vector3, color: Color, angle_y: float = 0.0) -> void:
    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_node.mesh = mesh
    mesh_node.position = pos
    mesh_node.rotation_degrees.y = angle_y
    mesh_node.material_override = _mat(color)
    add_child(mesh_node)

func _scenery_cylinder(radius: float, height: float, pos: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.85
    mesh.bottom_radius = radius
    mesh.height = height
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    add_child(node)

func _scenery_tree(pos: Vector3, size_factor: float) -> void:
    _scenery_cylinder(0.18 * size_factor, 2.2 * size_factor, pos + Vector3(0, 1.1 * size_factor, 0), Color(0.39, 0.24, 0.13))
    for offset in [Vector3(0, 2.45, 0), Vector3(-0.45, 2.05, 0), Vector3(0.43, 2.10, 0)]:
        var leaves := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.75 * size_factor
        mesh.height = 1.5 * size_factor
        leaves.mesh = mesh
        leaves.position = pos + offset * size_factor
        leaves.material_override = _mat(Color(0.12, 0.39 + 0.07 * offset.x, 0.15))
        add_child(leaves)

func _create_village_scenery() -> void:
    # Narrow earth path runs behind the existing bamboo course.
    _scenery_box(Vector3(2.0, 0.025, 23.0), Vector3(0, 0.015, -2.0), Color(0.59, 0.43, 0.26))
    # Small scattered grass clumps, away from the character's walking lane.
    var rng := RandomNumberGenerator.new()
    rng.seed = 404
    for i in range(72):
        var x := rng.randf_range(-14.0, 14.0)
        var z := rng.randf_range(-14.0, 14.0)
        if absf(x) < 1.65:
            continue
        var tuft := MeshInstance3D.new()
        var tuft_mesh := SphereMesh.new()
        tuft_mesh.radius = 0.12
        tuft_mesh.height = 0.24
        tuft.mesh = tuft_mesh
        tuft.position = Vector3(x, 0.10, z)
        tuft.material_override = _mat(Color(0.14, rng.randf_range(0.42, 0.66), 0.17))
        add_child(tuft)
    for z in [-11.0, -5.0, 2.0, 9.0]:
        _scenery_tree(Vector3(-8.0, 0, z), 0.95)
        _scenery_tree(Vector3(8.0, 0, z + 1.5), 0.85)
    # A simple village hut outside the play corridor.
    _scenery_box(Vector3(3.1, 2.2, 2.7), Vector3(10.5, 1.1, -9.5), Color(0.71, 0.53, 0.32))
    _scenery_box(Vector3(3.7, 0.35, 3.3), Vector3(10.5, 2.42, -9.5), Color(0.43, 0.18, 0.11), 0.0)
    _scenery_box(Vector3(0.8, 1.5, 0.055), Vector3(10.5, 0.75, -8.12), Color(0.27, 0.17, 0.10))
    # Small decorative stones outside the main walking corridor.
    # They have no collision shapes and cannot block movement.
    for i in range(24):
        var side := -1.0 if i % 2 == 0 else 1.0
        var stone_x := side * rng.randf_range(2.0, 6.8)
        var stone_z := rng.randf_range(-12.0, 10.0)
        var stone := MeshInstance3D.new()
        var stone_mesh := SphereMesh.new()
        stone_mesh.radius = 0.18
        stone_mesh.height = 0.24
        stone.mesh = stone_mesh
        stone.position = Vector3(stone_x, 0.09, stone_z)
        stone.scale = Vector3(rng.randf_range(0.75, 1.5), 0.6, rng.randf_range(0.75, 1.4))
        stone.material_override = _mat(Color(0.45, 0.44, 0.40))
        add_child(stone)
    # Bamboo course keeps its original positions and collision checks.

func _create_controls() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)
    message_label = Label.new()
    message_label.text = "BASH AGAIN! GET UP, BOSS!"
    message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    message_label.position = Vector2(-145, 85)
    message_label.add_theme_font_size_override("font_size", 22)
    message_label.visible = false
    ui.add_child(message_label)
    var directions := {"LEFT": Vector2(-1, 0), "RIGHT": Vector2(1, 0), "UP": Vector2(0, -1), "DOWN": Vector2(0, 1)}
    var spots := {"LEFT": Vector2(20, -145), "RIGHT": Vector2(160, -145), "UP": Vector2(90, -220), "DOWN": Vector2(90, -70)}
    for label_text in directions:
        var button := Button.new()
        button.text = label_text
        button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        button.offset_left = spots[label_text].x
        button.offset_top = spots[label_text].y
        button.offset_right = spots[label_text].x + 78
        button.offset_bottom = spots[label_text].y + 62
        button.button_down.connect(_on_direction.bind(directions[label_text], true))
        button.button_up.connect(_on_direction.bind(directions[label_text], false))
        ui.add_child(button)
    var jump := Button.new()
    jump.text = "JUMP"
    jump.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    jump.offset_left = -130
    jump.offset_top = -145
    jump.offset_right = -18
    jump.offset_bottom = -72
    jump.pressed.connect(func(): jump_requested = true)
    ui.add_child(jump)

func _on_direction(direction: Vector2, pressed: bool) -> void:
    if pressed:
        move_axis += direction
    else:
        move_axis -= direction
    move_axis = Vector2(clampf(move_axis.x, -1.0, 1.0), clampf(move_axis.y, -1.0, 1.0))


# v0.6 systems: all geometry is generated in GDScript, no external assets.
func _create_hud() -> void:
    var hud := CanvasLayer.new()
    hud.name = "GameHUD"
    add_child(hud)
    level_label = Label.new()
    level_label.position = Vector2(16, 22)
    level_label.add_theme_font_size_override("font_size", 23)
    hud.add_child(level_label)
    score_label = Label.new()
    score_label.position = Vector2(16, 54)
    score_label.add_theme_font_size_override("font_size", 19)
    hud.add_child(score_label)
    pause_button = Button.new()
    pause_button.text = "PAUSE"
    pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    pause_button.offset_left = -122
    pause_button.offset_right = -12
    pause_button.offset_top = 18
    pause_button.offset_bottom = 70
    pause_button.pressed.connect(_toggle_pause)
    hud.add_child(pause_button)
    restart_button = Button.new()
    restart_button.text = "RESTART"
    restart_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    restart_button.offset_left = -122
    restart_button.offset_right = -12
    restart_button.offset_top = 76
    restart_button.offset_bottom = 126
    restart_button.pressed.connect(_restart_level)
    hud.add_child(restart_button)
    next_button = Button.new()
    next_button.text = "NEXT LEVEL"
    next_button.set_anchors_preset(Control.PRESET_CENTER)
    next_button.offset_left = -110
    next_button.offset_right = 110
    next_button.offset_top = -40
    next_button.offset_bottom = 30
    next_button.visible = false
    next_button.pressed.connect(_next_level)
    hud.add_child(next_button)
    _update_hud()

func _update_hud() -> void:
    if level_label != null:
        level_label.text = "LEVEL %d / 10" % current_level
    if score_label != null:
        score_label.text = "COINS %d    SCORE %d" % [coins, score]

func _toggle_pause() -> void:
    paused_game = not paused_game
    pause_button.text = "RESUME" if paused_game else "PAUSE"

func _restart_level() -> void:
    paused_game = false
    pause_button.text = "PAUSE"
    _start_level(current_level)

func _next_level() -> void:
    if current_level < 10:
        _start_level(current_level + 1)
    else:
        _start_level(1)

func _start_level(level: int) -> void:
    current_level = clampi(level, 1, 10)
    saved_level = current_level
    _save_progress()
    paused_game = false
    knocked_down = false
    knock_time = 0.0
    hit_cooldown = 1.0
    move_axis = Vector2.ZERO
    jump_requested = false
    player.position = Vector3(0, 1.3, 0)
    player.velocity = Vector3.ZERO
    avatar.rotation_degrees = Vector3.ZERO
    message_label.visible = false
    next_button.visible = false
    pause_button.text = "PAUSE"
    # Rearrange the existing three bamboo obstacles for each level.
    bamboo_positions.clear()
    for i in range(3):
        var z := -4.0 - float(i) * 3.1
        var x := sin(float(current_level * 3 + i * 5)) * 1.65
        var pos := Vector3(x, 0, z)
        bamboo_positions.append(pos)
        # Four nodes per bamboo: pole and three rings.
        for j in range(4):
            var idx := i * 4 + j
            if idx < bamboo_nodes.size():
                var node := bamboo_nodes[idx]
                var y: float = 1.4 if j == 0 else [0.55, 1.4, 2.25][j - 1]
                node.position = pos + Vector3(0, y, 0)
    for coin in coin_nodes:
        coin.queue_free()
    coin_nodes.clear()
    for i in range(5):
        var z := -2.0 - float(i) * 2.25
        var x := cos(float(current_level + i * 2)) * 0.72
        var coin := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.24
        mesh.bottom_radius = 0.24
        mesh.height = 0.075
        coin.mesh = mesh
        coin.rotation_degrees.x = 90
        coin.position = Vector3(x, 1.05, z)
        coin.material_override = _mat(Color(1.0, 0.77, 0.12))
        add_child(coin)
        coin_nodes.append(coin)
    _update_hud()

func _check_coins_and_finish() -> void:
    for coin in coin_nodes:
        if not is_instance_valid(coin) or not coin.visible:
            continue
        coin.rotation_degrees.z += 2.0
        if player.global_position.distance_to(coin.global_position) < 1.05:
            coin.visible = false
            coins += 1
            score += 10
            _update_hud()
    if player.global_position.z < finish_z and not next_button.visible:
        score += 100
        next_button.text = "FINISH! NEXT LEVEL" if current_level < 10 else "YOU WON! REPLAY"
        next_button.visible = true
        paused_game = true
        _update_hud()

func _animate_walk(delta: float, axis: Vector2) -> void:
    var moving := axis.length() > 0.1 and player.is_on_floor()
    if moving:
        anim_clock += delta * 9.0
    else:
        anim_clock = lerpf(anim_clock, 0.0, minf(delta * 6.0, 1.0))
    var swing := sin(anim_clock) * (17.0 if moving else 0.0)
    for child in avatar.get_children():
        if child.name == "Jeans leg -1" or child.name == "White shoe -1":
            child.rotation_degrees.x = swing
        elif child.name == "Jeans leg 1" or child.name == "White shoe 1":
            child.rotation_degrees.x = -swing
        elif child.name == "Forearm -1" or child.name == "Blue sleeve -1":
            child.rotation_degrees.x = -swing * 0.7
        elif child.name == "Forearm 1" or child.name == "Blue sleeve 1":
            child.rotation_degrees.x = swing * 0.7

func _save_progress() -> void:
    var file := FileAccess.open("user://bansh_progress.save", FileAccess.WRITE)
    if file != null:
        file.store_32(saved_level)

func _load_progress() -> void:
    if FileAccess.file_exists("user://bansh_progress.save"):
        var file := FileAccess.open("user://bansh_progress.save", FileAccess.READ)
        if file != null:
            saved_level = clampi(int(file.get_32()), 1, 10)
