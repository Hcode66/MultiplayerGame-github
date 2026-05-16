extends NinePatchRect

var enabled: bool = false:
	set(v):
		enabled = v
		if !v:
			anim.play("Intro")
		else:
			anim.play_backwards("Intro")
			pause_menu.visible = false

@onready var pause_menu: NinePatchRect = $"../PauseMenu"
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if !is_multiplayer_authority():
		get_parent().visible = false
		return
	gonet.mana_changed.connect(on_mana_change)

	scale = Vector2.ONE * 0.01


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("TAB"):
		enabled = !enabled


	visible = scale.distance_to(Vector2.ZERO) > .05 ## > 0 can cause glitches


func on_mana_change():
	$ManaBar.value = gonet.stored_data["mana"]
	$ManaBar/Text.text = str(gonet.stored_data["mana"])
