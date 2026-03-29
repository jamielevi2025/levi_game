extends VBoxContainer

class_name VolumeControls

@onready var master_slider = $MasterRow/MasterSlider
@onready var music_slider = $MusicRow/MusicSlider
@onready var sfx_slider = $SFXRow/SFXSlider
@onready var master_value = $MasterRow/MasterValue
@onready var music_value = $MusicRow/MusicValue
@onready var sfx_value = $SFXRow/SFXValue


func _ready() -> void:
	master_slider.value = GameSettings.master_volume
	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume
	master_value.text = str(int(GameSettings.master_volume * 100)) + "%"
	music_value.text = str(int(GameSettings.music_volume * 100)) + "%"
	sfx_value.text = str(int(GameSettings.sfx_volume * 100)) + "%"
	master_slider.value_changed.connect(on_master_changed)
	music_slider.value_changed.connect(on_music_changed)
	sfx_slider.value_changed.connect(on_sfx_changed)


func on_master_changed(value: float) -> void:
	GameSettings.master_volume = value
	master_value.text = str(int(value * 100)) + "%"
	GameSettings.apply_volumes()
	GameSettings.save_settings()


func on_music_changed(value: float) -> void:
	GameSettings.music_volume = value
	music_value.text = str(int(value * 100)) + "%"
	GameSettings.apply_volumes()
	GameSettings.save_settings()


func on_sfx_changed(value: float) -> void:
	GameSettings.sfx_volume = value
	sfx_value.text = str(int(value * 100)) + "%"
	GameSettings.apply_volumes()
	GameSettings.save_settings()


func refresh() -> void:
	master_slider.value = GameSettings.master_volume
	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume
	master_value.text = str(int(GameSettings.master_volume * 100)) + "%"
	music_value.text = str(int(GameSettings.music_volume * 100)) + "%"
	sfx_value.text = str(int(GameSettings.sfx_volume * 100)) + "%"
