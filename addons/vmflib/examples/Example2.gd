extends Button


func _on_pressed() -> void:
	var vmf = VMF.new(VMF.GAMES.PORTAL_2)
	
	var block := VMF.Block.new(vmf, Vector3(0, 0, 0), Vector3(256, 256, 256), "DEV/DEV_MEASUREGENERIC01")
	block.brush.children[0].material = "DEV/DEV_MEASUREGENERIC01B"
	vmf.add_solid(block)

	var info_player_start := VMF.InfoPlayerStartEntity.new(vmf)
	
	vmf.write_to_file("user://output.vmf")
	
	get_parent().get_node("Label2").show()
	get_parent().get_node("Button2").show()


func _on_Button2_pressed() -> void:
	OS.shell_open(OS.get_user_data_dir())
