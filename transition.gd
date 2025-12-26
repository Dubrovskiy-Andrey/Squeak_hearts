extends CanvasLayer

var fade_rect: ColorRect
var tween: Tween

func _ready():
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade_rect)
	
	layer = 100 
	fade_rect.visible = false
	print("✅ TransitionManager создан")

func fade_out(duration: float = 0.5) -> void:
	fade_rect.visible = true
	
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = 0.5) -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished
	
	fade_rect.visible = false

func change_scene_with_fade(scene_path: String, fade_out_time: float = 0.5, fade_in_time: float = 0.5) -> void:
	print("🎬 Переход на сцену:", scene_path)
	await fade_out(fade_out_time)
	get_tree().change_scene_to_file(scene_path)
	await fade_in(fade_in_time)
