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
    camera.position = Vector3(0, 6.8, 12.5)
    camera.rotation_degrees.x = -24
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
                message_label.visible = true
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
