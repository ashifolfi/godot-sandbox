class_name BaseWeapon extends Node

var animator: AnimationTree

func weapon_name() -> String:
	return "weapon"

func weapon_view_model() -> Resource:
	return Resource.new()

func weapon_anim_tree() -> AnimationNode:
	return AnimationNode.new()

func _ready():
	animator = AnimationTree.new()
	animator.tree_root = weapon_anim_tree()
	add_child(animator)

func fire_primary(held: bool):
	pass

func fire_secondary(held: bool):
	pass

func weapon_idle():
	pass
