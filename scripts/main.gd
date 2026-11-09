extends Node3D

var player: CharacterBody3D
var move_axis := Vector2.ZERO
var jump_requested := false
var move_speed := 4.0
var gravity := 18.0
var jump_speed := 6.0

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
    var avatar := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.8
    avatar.mesh = body_mesh
    var avatar_mat := StandardMaterial3D.new()
    avatar_mat.albedo_color = Color(0.95, 0.68, 0.18)
    avatar.material_override = avatar_mat
    player.add_child(avatar)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 5, 8)
    camera.rotation_degrees.x = -25
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
    _create_controls()

func _physics_process(delta: float) -> void:
    if player == null:
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

func _create_controls() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)
    var directions := {"LEFT": Vector2(-1, 0), "RIGHT": Vector2(1, 0), "UP": Vector2(0, -1), "DOWN": Vector2(0, 1)}
    var spots := {"LEFT": Vector2(25, -110), "RIGHT": Vector2(155, -110), "UP": Vector2(90, -175), "DOWN": Vector2(90, -45)}
    for label_text in directions:
        var button := Button.new()
        button.text = label_text
        button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        button.offset_left = spots[label_text].x
        button.offset_top = spots[label_text].y
        button.offset_right = spots[label_text].x + 90
        button.offset_bottom = spots[label_text].y + 55
        button.button_down.connect(_on_direction.bind(directions[label_text], true))
        button.button_up.connect(_on_direction.bind(directions[label_text], false))
        ui.add_child(button)
    var jump := Button.new()
    jump.text = "JUMP"
    jump.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    jump.offset_left = -135
    jump.offset_top = -100
    jump.offset_right = -20
    jump.offset_bottom = -30
    jump.pressed.connect(func(): jump_requested = true)
    ui.add_child(jump)

func _on_direction(direction: Vector2, pressed: bool) -> void:
    if pressed:
        move_axis += direction
    else:
        move_axis -= direction
    move_axis = Vector2(clampf(move_axis.x, -1.0, 1.0), clampf(move_axis.y, -1.0, 1.0))
