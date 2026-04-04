@tool

# Icons are optional.
# Alternatively, you may use the UID of the icon or the absolute path.
@icon("icon.svg")
class_name ProcTerrain3D
extends MeshInstance3D

@export_range(32,1024,4) var size := 256.0:
	set(new_size):
		size = new_size
		update_all()

@export_range(4, 256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		update_all()

@export_range(4.0, 128.0, 4.0) var height := 28.0:
	set(new_height):
		height = new_height
		#material_override.set_shader_parameter("height", height * 2.0)
		update_all()

@export var water := false:
	set(new_water):
		water = new_water
		update_water()

@export var noise : FastNoiseLite:
	set(new_noise):
		noise = new_noise
		update_all()
		if noise:
			noise.changed.connect(update_mesh)

func _enter_tree():
	var terrain_collider: CollisionShape3D = find_child("TerrainCollider", true, true)
	if not terrain_collider:
		var static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		
		var collider = CollisionShape3D.new()
		collider.name = "TerrainCollider"
		
		static_body.add_child(collider)
		
		add_child(static_body)
		static_body.owner = get_tree().edited_scene_root
		collider.owner = get_tree().edited_scene_root
	
	if not noise:
		var fast_noise = FastNoiseLite.new()
		fast_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise = fast_noise
	
	if not material_override:
		const DIRT_MATERIAL = preload("res://addons/proc_terrain/dirt_material.tres")
		material_override = DIRT_MATERIAL

func get_height(x: float, y: float) -> float:
	return noise.get_noise_2d(x, y) * height

func get_normal(x: float, y:float) -> Vector3:
	var epsilon := size / resolution
	var normal := Vector3(
		(get_height(x + epsilon, y) - get_height(x - epsilon, y)) / (2.0 * epsilon),
		1.0,
		(get_height(x, epsilon + y) - get_height(x, epsilon - y)) / (2.0 * epsilon)
	)
	return normal.normalized()

func update_all() -> void:
	update_mesh()
	update_water()

func update_mesh() -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size, size)
	
	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	for i: int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = get_height(vertex.x, vertex.z)
			normal = get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mesh
	
	var shape_for_collision := ConcavePolygonShape3D.new()
	shape_for_collision.set_faces(mesh.get_faces())

	if Engine.is_editor_hint():
		#var terrain_collider: CollisionShape3D = $StaticBody3D/TerrainCollider
		var terrain_collider: CollisionShape3D = find_child("TerrainCollider", true, true)
		if terrain_collider:
			terrain_collider.set_shape(shape_for_collision)

func update_water() -> void:
	if Engine.is_editor_hint():
		var water_node: MeshInstance3D = find_child("WaterMesh", true, true)
		if water_node:
			water_node.scale = Vector3(size,1,size)
			if water:
				water_node.visible = true;
			else:
				water_node.visible = false;
		else:
			var loaded_material = preload("res://addons/proc_terrain/water_material.tres")
			var water_mesh := MeshInstance3D.new()
			var quad_mesh := QuadMesh.new()
			quad_mesh.size = Vector2.ONE
			quad_mesh.subdivide_depth = 200
			quad_mesh.subdivide_width = 200
			quad_mesh.orientation = PlaneMesh.FACE_Y
			water_mesh.mesh = quad_mesh
			water_mesh.set_surface_override_material(0, loaded_material)
			
			water_mesh.name = "WaterMesh"
			water_mesh.visible = water
			water_mesh.scale = Vector3(size,1,size)
			
			add_child(water_mesh)
			water_mesh.owner = get_tree().edited_scene_root

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
