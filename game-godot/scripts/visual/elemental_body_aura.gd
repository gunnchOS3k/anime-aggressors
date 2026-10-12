extends Node3D
## Original, depth-tested Compatibility geometry attached to the visible rig.
## One mesh/material per model lifetime; no gameplay or collision writes.
const RigMap = preload("res://scripts/visual/procedural_bone_map.gd")
const IDS = ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx","yin","yang"]
const GRAMMARS = ["rising_combustion","seismic_fragments","branching_current","helical_wind","faceted_growth","tilted_orbits","phase_seams","inward_absorption","ordered_construction"]
const COLORS = [Color(1,.30,.04),Color(.68,.49,.25),Color(.32,.69,1),Color(.36,.92,.77),Color(.62,.88,1),Color(.62,.45,.96),Color(.82,.40,.90),Color(.31,.30,.47),Color(1,.86,.40)]
var snapshot: Dictionary = {}
var skeleton: Skeleton3D
var mesh := ImmediateMesh.new()
var material := ShaderMaterial.new()
var instance: MeshInstance3D
var elapsed := 0.0
var arrival := 0.0
var vertex_count := 0
var generation := 0
var draw_us := 0
var _bones: Dictionary = {}
var _anchors: Dictionary = {}

func setup(sk: Skeleton3D) -> void:
	skeleton=sk
	for key in ["Hips","Chest","Head","Hand_L","Hand_R","Foot_L","Foot_R"]:
		_bones[key]=sk.find_bone(RigMap.resolve_on_skeleton(sk,key))
	var shader := Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
void fragment() {
 float edge = smoothstep(0.0,0.22,UV.x)*smoothstep(0.0,0.22,1.0-UV.x);
 ALBEDO = COLOR.rgb; ALPHA = COLOR.a*edge;
}
"""
	material.shader=shader
	instance=MeshInstance3D.new(); instance.name="OriginalElementalBodyGeometry"
	instance.mesh=mesh;instance.material_override=material
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance);instance.visible=false

func observe(data: Dictionary) -> void:
	if bool(data.get("super_ready",false)) and not bool(snapshot.get("super_ready",false)):arrival=.32
	snapshot=data.duplicate(true)
	visible=bool(snapshot.get("active",false))
	if not visible:
		mesh.clear_surfaces();vertex_count=0;arrival=0

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(skeleton):return
	elapsed+=delta;arrival=maxf(0,arrival-delta)
	var started:=Time.get_ticks_usec()
	_rebuild()
	draw_us=int(Time.get_ticks_usec()-started)

func _anchor(key: String) -> Vector3:
	var index: int=_bones.get(key,-1)
	return to_local(skeleton.to_global(skeleton.get_bone_global_pose(index).origin)) if index>=0 else Vector3.ZERO

func _triangle(a: Vector3,b: Vector3,c: Vector3,color: Color,ua: Vector2,ub: Vector2,uc: Vector2) -> void:
	for item in [[a,ua],[b,ub],[c,uc]]:
		mesh.surface_set_color(color);mesh.surface_set_uv(item[1]);mesh.surface_add_vertex(item[0]);vertex_count+=1

func _ribbon(points: Array[Vector3],width: float,color: Color,taper: bool=true) -> void:
	for i in range(points.size()-1):
		var side := (points[i+1]-points[i]).cross(Vector3.FORWARD).normalized()
		if side.length_squared()<.001:side=Vector3.RIGHT
		var w0:=width*(1.0-float(i)/points.size() if taper else 1.0)
		var w1:=width*(1.0-float(i+1)/points.size() if taper else 1.0)
		var a:=points[i]-side*w0;var b:=points[i]+side*w0
		var c:=points[i+1]-side*w1;var d:=points[i+1]+side*w1
		_triangle(a,b,c,color,Vector2(0,0),Vector2(1,0),Vector2(0,1))
		_triangle(b,d,c,color,Vector2(1,0),Vector2(1,1),Vector2(0,1))

func _diamond(center: Vector3,radius: float,color: Color,angle: float=0.0) -> void:
	var points: Array[Vector3]=[]
	for i in range(5):
		var a:=angle+i*PI/2
		points.append(center+Vector3(cos(a)*radius*.65,sin(a)*radius,0))
	_ribbon(points,radius*.22,color,false)

func _rebuild() -> void:
	mesh.clear_surfaces();vertex_count=0
	skeleton.force_update_all_bone_transforms()
	for key in _bones:_anchors[key]=_anchor(key)
	var family:=IDS.find(str(snapshot.get("fighter_id","")))
	if family<0:return
	var strength:=clampf(float(snapshot.get("amount",0))/100.0,0,1)
	if bool(snapshot.get("form_empowered",false)):strength=maxf(.38,strength)
	var mode: String=str(snapshot.get("intensity","Balanced"))
	var reduced:=mode=="Reduced" or bool(snapshot.get("reduced_particles",false))
	var count:=3 if reduced else (8 if mode=="Full" else 5)
	var color: Color=COLORS[family]
	if bool(snapshot.get("high_contrast",false)):color=color.lerp(Color.WHITE,.45)
	color.a=(.16+.29*strength)*(0.65 if reduced else 1.0)
	var t:=elapsed
	var scale_power:=.75+.25*strength
	if arrival>0 and not bool(snapshot.get("reduced_flash",false)):scale_power+=.1*arrival/.32
	var hip: Vector3=_anchors.Hips;var chest: Vector3=_anchors.Chest
	var head: Vector3=_anchors.Head
	var height:=maxf(.8,head.y-hip.y+.55)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count):
		var phase:=TAU*float(i)/count
		var pts: Array[Vector3]=[]
		match family:
			0: # Broad-base, narrowing organic tongues move upward, not a ring.
				for j in range(9):
					var u:=float(j)/8
					pts.append(hip+Vector3(cos(phase)*(.28+.07*sin(t*2+u*4)),height*(u-.2),sin(phase)*.22)+Vector3(.07*sin(t*3+u*9+phase)*u,0,0))
				_ribbon(pts,.065*scale_power,color)
			1:
				var center:=chest+Vector3(cos(phase)*.33,sin(phase)*height*.48,sin(phase+t*.35)*.16)
				_diamond(center,.065+.025*strength,color,phase*.5)
				_ribbon([hip+Vector3(-.28,.03*i,0),hip+Vector3(0,-.06+.03*i,.08),hip+Vector3(.28,.03*i,0)],.018,color,false)
			2: # Deterministic moving branches, anchored at actual hands/body.
				var anchor: Vector3=_anchors.Hand_L if i%2==0 else _anchors.Hand_R
				for j in range(7):
					var u:=float(j)/6
					pts.append(anchor.lerp(chest+Vector3(cos(phase)*.38,sin(phase)*.6,.05),u)+Vector3(sin(j*4+phase+t*3)*.055,sin(j*8+phase)*.035,.06*sin(j+phase)))
				_ribbon(pts,.013 if reduced else .021,color,false)
				_ribbon([pts[2],pts[2]+Vector3(.12*cos(phase),.11,.08),pts[2]+Vector3(.19*cos(phase),.14,0)],.01,color)
			3:
				for j in range(15):
					var u:=float(j)/14;var a:=phase+u*3.5+t*.8
					pts.append(hip+Vector3(cos(a)*.34,height*(u-.18),sin(a)*.26))
				_ribbon(pts,.035*scale_power,color)
			4:
				_diamond(chest+Vector3(cos(phase)*.30,sin(phase)*height*.55,.12*sin(phase)),(.05+.035*strength)*scale_power,color,PI/2)
				var hand: Vector3=_anchors.Hand_L if i%2==0 else _anchors.Hand_R
				_ribbon([hand,hand+Vector3(.06*cos(phase),.1,.07),hand+Vector3(.13*cos(phase),.19,0)],.016,color)
			5:
				for j in range(19):
					var a:=phase+float(j)/18*TAU+t*.4
					pts.append(chest+Vector3(cos(a)*.4,sin(a)*.26*cos(phase),sin(a)*.3*sin(phase)))
				_ribbon(pts,.013,color,false)
				_diamond(pts[i%pts.size()],.035,color)
			6:
				var shift:=.06*sin(t*1.2+phase)
				_ribbon([hip+Vector3(.28+shift,.05,0),chest+Vector3(.22+shift,.02,.15),head+Vector3(.10+shift,.08,0)],.023,color)
				_ribbon([hip+Vector3(-.28-shift,.12,.1),chest+Vector3(-.22-shift,.09,0)],.012,color)
			7:
				for j in range(13):
					var u:=float(j)/12;var r: float=.44*(1-u)
					var a:=phase+u*3.1-t*.5
					pts.append(chest+Vector3(cos(a)*r,sin(a)*r,.08*sin(a)))
				_ribbon(pts,.027,color)
			8:
				for j in range(7):
					var a:=phase+float(j)/6*TAU
					pts.append(chest+Vector3(cos(a)*(.26+.035*i),sin(a)*(.26+.035*i),.025*i))
				_ribbon(pts,.014,color,false)
				_ribbon([pts[0],pts[0]+Vector3(cos(phase),sin(phase),0)*.16],.021,color)
	mesh.surface_end();instance.visible=vertex_count>0;generation+=1

func evidence() -> Dictionary:
	var out:=snapshot.duplicate(true)
	var family:=IDS.find(str(snapshot.get("fighter_id","")))
	out.merge({"grammar":GRAMMARS[family] if family>=0 else "unknown","vertices":vertex_count,"mesh_instances":1,"materials":1,"generation":generation,"draw_cpu_us":draw_us,"anchors":_anchors.duplicate(),"depth_tested":true,"gameplay_writes":false},true)
	return out
