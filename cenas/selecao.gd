extends Control

var p1escolha = 0
var p2escolha = 0

var p1pronto = false
var p2pronto = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	trocar_lutador(0,0)
	trocar_lutador(1,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	var tecla
	if event is InputEventKey and event.pressed:
		
		tecla = event.physical_keycode
		
		match tecla:
			KEY_A:
				trocar_lutador(0,-1)
			KEY_D:
				trocar_lutador(0,1)
			KEY_LEFT:
				trocar_lutador(1,-1)
			KEY_RIGHT:
				trocar_lutador(1,1)
			KEY_SPACE:
				selecionador_lutador(0)
			KEY_KP_ENTER, KEY_ENTER:
				selecionador_lutador(1)
		
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index>10:
			tecla = event.button_index
			print(tecla)
			match tecla:
				13:
					trocar_lutador(event.device,-1)
				14:
					trocar_lutador(event.device,1)
		else:
			selecionador_lutador(event.device)
				
func trocar_lutador(jogador,delta):
	
	match jogador:
		0:
			if p1pronto: return
			p1escolha += delta
			if p1escolha<0:
				p1escolha=2
			if p1escolha>2:
				p1escolha=0
			%LutadorP1.mudar_personagem(p1escolha)
			%TextoNomeP1.text = Global.lutadores[p1escolha]["nome"]
		1:
			if p2pronto: return
			p2escolha += delta
			if p2escolha<0:
				p2escolha=2
			if p2escolha>2:
				p2escolha=0
			%LutadorP2.mudar_personagem(p2escolha)
			%TextoNomeP2.text = Global.lutadores[p2escolha]["nome"]
	
func selecionador_lutador(jogador):
	
	const texto_pronto = "PRONTO"
	
	match jogador:
		0:
			Global.p1lutador = p1escolha
			%TextoProntoP1.text = texto_pronto
			p1pronto = true
		1:
			Global.p2lutador = p2escolha
			%TextoProntoP2.text = texto_pronto
			p2pronto = true
	
	if p1pronto and p2pronto:
		%Mensagem.text = "PREPAREM-SE!"
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://cenas/main.tscn")
