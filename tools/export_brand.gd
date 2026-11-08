extends SceneTree
# Exporta as imagens da marca FT e o ícone do jogo.
# Rodar (precisa de GPU/Xvfb):
#   godot --rendering-driver opengl3 -s tools/export_brand.gd
# Gera: ft_intro/ft_logo.png, ft_intro/ft_splash_portrait.png,
#       ft_intro/ft_splash_landscape.png, icon.png, icon_fg.png, icon_bg.png

const Logo = preload("res://ft_intro/FTLogo.gd")
const D = preload("res://scripts/Draw.gd")
const R = preload("res://scripts/Rules.gd")


class Painter extends Control:
	var job := ""
	func _draw() -> void:
		var w := size.x
		var h := size.y
		match job:
			"logo":
				Logo.draw_logo(self, size / 2, minf(w, h) * 0.78, 1.0, 1.0, 1.0, 0.8)
			"splash":
				draw_rect(Rect2(0, 0, w, h), Logo.BG)
				Logo.draw_logo(self, size / 2, minf(w, h) * 0.45, 1.0, 1.0, 1.0, 0.8)
			"icon", "icon_bg":
				var r := Rect2(0, 0, w, h)
				if job == "icon":
					D.fill_rrect(self, r, w * 0.22, Color("ff8c42"))
				else:
					draw_rect(r, Color("ff8c42"))
				draw_circle(Vector2(w * 0.5, h * 0.5), w * 0.42, Color("ffa94d"))
				if job == "icon":
					_burger(w * 0.68)
			"icon_fg":
				_burger(w * 0.5)

	func _burger(bw: float) -> void:
		var cx := size.x / 2
		var layers := [R.BUN_BOTTOM, R.PATTY, R.CHEESE, R.LETTUCE, R.BUN_TOP]
		var h := D.stack_height(layers, bw)
		D.draw_stack(self, layers, cx, size.y / 2 + h / 2, bw)


var jobs := [
	["logo", Vector2i(1024, 1024), "res://ft_intro/ft_logo.png", true],
	["splash", Vector2i(1080, 1920), "res://ft_intro/ft_splash_portrait.png", false],
	["splash", Vector2i(1920, 1080), "res://ft_intro/ft_splash_landscape.png", false],
	["icon", Vector2i(512, 512), "res://icon.png", true],
	["icon_fg", Vector2i(432, 432), "res://icon_fg.png", true],
	["icon_bg", Vector2i(432, 432), "res://icon_bg.png", false],
]
var vps := []
var frame := 0


func _initialize() -> void:
	for j in jobs:
		var vp := SubViewport.new()
		vp.size = j[1]
		vp.transparent_bg = j[3]
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var p := Painter.new()
		p.job = j[0]
		p.size = Vector2(j[1])
		vp.add_child(p)
		root.add_child(vp)
		vps.append(vp)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 4:
		for i in jobs.size():
			var img: Image = vps[i].get_texture().get_image()
			img.save_png(ProjectSettings.globalize_path(jobs[i][2]))
			print("salvo ", jobs[i][2])
		quit()
	return false
