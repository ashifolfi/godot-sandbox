extends Control

func _on_testmap_pressed():
	GameManager.change_map("src/testmap.bsp")

func _on_quit_pressed():
	get_tree().quit()
