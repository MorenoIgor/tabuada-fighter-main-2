extends Node2D

@export var player2 = false
@onready var posicao_inicial = position.x
var deslocamento: int = 200
var vel_x: float = 0

var nome_personagem_interno: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if not player2:
		nome_personagem_interno = Global.lutadores[Global.p1lutador]["nome_interno"]
	else:
		nome_personagem_interno = Global.lutadores[Global.p2lutador]["nome_interno"]
	reset()
	
	if player2:
		$Visual.scale.x *= -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	position.x += vel_x
	$Visual/Sombra.texture = $Visual/Corpo.texture
	
	
func atacar(anim):
	z_index = 10
	position.x += deslocamento * sign($Visual.scale.x)
	vel_x = 0.5 * sign($Visual.scale.x)
	$Visual/Corpo.texture = load("res://artes/personagens/"+nome_personagem_interno+"/attack_"+str(anim)+".png")
	$Animador.stop()
	%Camera.rotation_degrees = 3 * sign($Visual.scale.x)
	

func tomar_dano():
	z_index = 0
	$Visual/Corpo.texture = load("res://artes/personagens/"+nome_personagem_interno+"/damage.png")
	vel_x = -0.5 * sign($Visual.scale.x)
	$Animador.stop()

func reset():
	$Visual/Corpo.texture = load("res://artes/personagens/"+nome_personagem_interno+"/idle.png")
	position.x = posicao_inicial
	vel_x = 0
	$Animador.play("IDLE")
	$Animador.seek(randf_range(0.0,0.9),true,false)
	%Camera.rotation_degrees = 0
	
func mudar_personagem(indice):
	nome_personagem_interno = Global.lutadores[indice]["nome_interno"]
	reset()
