extends Control

signal animacao_porrada_terminada
signal contagem_regressiva_finalizada
signal zoom_terminado

enum Estado { JOGANDO, FIM_DE_RODADA, FIM_DE_JOGO, COUNTDOWN }

var vida_maxima: int = 1
var tempo_por_conta: float = 30.0
var fator_min: int = 2
var fator_max: int = 9
var pausa_entre_contas: float = 1.3

var duracao_ataque: float = 1.0

var controles: Array[Dictionary] = [
	{
		"mover": {
			KEY_W: Vector2i(0, -1), KEY_S: Vector2i(0, 1),
			KEY_A: Vector2i(-1, 0), KEY_D: Vector2i(1, 0),
			11: Vector2i(0, -1), 12: Vector2i(0, 1),
			13: Vector2i(-1, 0), 14: Vector2i(1, 0),
		},
		"confirmar": [KEY_SPACE],
	},
	{
		"mover": {
			KEY_UP: Vector2i(0, -1), KEY_DOWN: Vector2i(0, 1),
			KEY_LEFT: Vector2i(-1, 0), KEY_RIGHT: Vector2i(1, 0),
			21: Vector2i(0, -1), 22: Vector2i(0, 1),
			23: Vector2i(-1, 0), 24: Vector2i(1, 0),
		},
		"confirmar": [KEY_ENTER, KEY_KP_ENTER],
	},
]

var vida: Array[int] = []
var estado: Estado = Estado.COUNTDOWN
var tempo_restante: float = 0.0
var resposta: int = 0
var texto_conta: String = ""
var ultima_conta: String = ""
var pode_reiniciar: bool = false
var tweens_vida: Array = [null, null]

@onready var barras_vida: Array = [%VidaP1, %VidaP2]
@onready var calculadoras: Array = [%CalculadoraP1, %CalculadoraP2]
@onready var rotulo_conta: Label = %Conta
@onready var barra_tempo: ProgressBar = %BarraTempo
@onready var rotulo_mensagem: Label = %Mensagem


func _ready() -> void:
	for i in 2:
		calculadoras[i].confirmado.connect(_ao_confirmar.bind(i))
	cold_start()


func _iniciar_jogo() -> void:
	
	%CalculadoraP1.visible = false
	%CalculadoraP2.visible = false
	%BarraTempo.visible = false
	%TextoTempo.visible = false
	%Conta.visible = true
	
	
	contagem_regressiva()
	await contagem_regressiva_finalizada
	
	vida = [vida_maxima, vida_maxima]
	for i in 2:
		barras_vida[i].value = vida_maxima
		if tweens_vida[i]:
			tweens_vida[i].kill()
		calculadoras[i].travada = false
	pode_reiniciar = false
	%CalculadoraP1.visible = true
	%CalculadoraP2.visible = true
	%BarraTempo.visible = true
	%TextoTempo.visible = true
	estado = Estado.JOGANDO
	_nova_conta()


func _nova_conta() -> void:
	var parametros = tiposConta()
	var tipo = parametros[0]
	var dificuldade = parametros[1]
	var a: int = randi_range(fator_min, fator_max)
	var b: int = randi_range(fator_min, fator_max)
	
	while "%d,%d" % [a, b] == ultima_conta:
		a = randi_range(fator_min, fator_max)
		b = randi_range(fator_min, fator_max)
	ultima_conta = "%d,%d" % [a, b]
	
	match tipo:
		"Adição":
			resposta = a + b
			texto_conta = "%d + %d" % [a, b]
		"Subtração":
			if a < b:
				resposta = b - a
				texto_conta = "%d - %d" % [b, a]
			else:
				resposta = a - b
				texto_conta = "%d - %d" % [a, b]
		"Multiplicação":
			resposta = a * b
			texto_conta = "%d × %d" % [a, b]
	
	%Conta.visible = true
	%BarraTempo.visible = true
	%TextoTempo.visible = true
	rotulo_conta.text = texto_conta
	rotulo_mensagem.text = ""
	tempo_restante = tempo_por_conta
	barra_tempo.value = tempo_restante
	estado = Estado.JOGANDO
	for c in calculadoras:
		c.limpar()

func tiposConta():
	var tipos = ["Adição", "Subtração", "Multiplicação"]
	var dificuldade = ["Fácil", "Médio", "Difícil"]
	
	return [tipos.pick_random(), dificuldade.pick_random()]

func _process(delta: float) -> void:
	if estado != Estado.JOGANDO:
		return
	tempo_restante -= delta
	barra_tempo.value = maxf(tempo_restante, 0.0)
	barra_tempo.modulate = Color(1, 0.4, 0.4) if tempo_restante < tempo_por_conta * 0.25 else Color.WHITE
	if tempo_restante <= 0.0:
		_ao_acabar_tempo()


func _ao_acabar_tempo() -> void:
	estado = Estado.FIM_DE_RODADA
	rotulo_mensagem.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	rotulo_mensagem.text = "Tempo esgotado!\n%s = %d" % [texto_conta, resposta]
	_proxima_rodada_apos_pausa()


func _ao_confirmar(valor: int, jogador: int) -> void:
	if estado != Estado.JOGANDO:
		return
	if valor == resposta:
		animar_porrada(jogador)
		calculadoras[0].travada = true
		calculadoras[1].travada = true
		await animacao_porrada_terminada
		mostrar_ui()
		_pontuar(jogador)
	else:
		calculadoras[jogador].errou()


func _pontuar(atacante: int) -> void:
	estado = Estado.FIM_DE_RODADA
	var vitima: int = 1 - atacante
	vida[vitima] -= 1
	_baixar_vida_suave(vitima)

	rotulo_mensagem.add_theme_color_override("font_color", calculadoras[atacante].cor_destaque)
	rotulo_mensagem.text = "Jogador %d acertou!\n%s = %d" % [atacante + 1, texto_conta, resposta]

	%Conta.visible = false
	%BarraTempo.visible = false
	%TextoTempo.visible = false

	if vida[vitima] <= 0:
		_fim_de_jogo(atacante)
	else:
		_proxima_rodada_apos_pausa()


func _proxima_rodada_apos_pausa() -> void:
	await get_tree().create_timer(pausa_entre_contas).timeout
	if estado == Estado.FIM_DE_RODADA:
		calculadoras[0].travada = false
		calculadoras[1].travada = false
		_nova_conta()


func _fim_de_jogo(vencedor: int) -> void:
	estado = Estado.FIM_DE_JOGO
	for c in calculadoras:
		c.travada = true
	rotulo_mensagem.text = "JOGADOR %d VENCEU!\nEspaço ou Enter para jogar de novo" % (vencedor + 1)
	
	%CalculadoraP1.visible = false
	%CalculadoraP2.visible = false
	
	await get_tree().create_timer(0.8).timeout
	pode_reiniciar = true


func _input(event: InputEvent) -> void:
	var tecla
	if event is InputEventKey and event.pressed:
		tecla = event.physical_keycode
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index>10:
			tecla = event.button_index
			tecla += event.device * 10 #GAMBIARRAAAAAAAAAAAAAAAAA
		else:
			if event.device == 0:
				tecla = KEY_SPACE
			else:
				tecla = KEY_KP_ENTER

	if estado == Estado.FIM_DE_JOGO:
		if pode_reiniciar and (tecla == KEY_SPACE or tecla == KEY_ENTER or tecla == KEY_KP_ENTER):
			cold_start()
		return
	if estado != Estado.JOGANDO:
		return

	for p in 2:
		var ctrl: Dictionary = controles[p]
		if ctrl["mover"].has(tecla):
			calculadoras[p].mover(ctrl["mover"][tecla])
		elif tecla in ctrl["confirmar"]:
			calculadoras[p].apertar()


func _baixar_vida_suave(jogador: int) -> void:
	if tweens_vida[jogador]:
		tweens_vida[jogador].kill()
	var tween: Tween = create_tween()
	tween.tween_property(barras_vida[jogador], "value", float(vida[jogador]), 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tweens_vida[jogador] = tween

func zoom_in():
	$CameraZoomPlayer.play("zoom_in")
	await $CameraZoomPlayer.animation_finished
	zoom_terminado.emit()
	
	
func animar_porrada(jogador):
	
	esconder_ui()
	
	zoom_in()
	await zoom_terminado
	var atacante = [%LutadorP1,%LutadorP2][jogador]
	var vitima = [%LutadorP1,%LutadorP2][1-jogador]
	
	atacante.atacar(1)
	vitima.tomar_dano()
	
	camera_shake(5)
	
	await get_tree().create_timer(duracao_ataque).timeout
	
	atacante.reset()
	vitima.reset()
	
	$CameraZoomPlayer.play("zoom_out")
	await $CameraZoomPlayer.animation_finished
	
	animacao_porrada_terminada.emit()
	
func esconder_ui():
	$UI.visible = false
	
func mostrar_ui():
	$UI.visible = true

func camera_shake(intensidade):
	for s in range(10):
		$Camera.offset = Vector2(randf_range(-intensidade,intensidade),randf_range(-intensidade,intensidade))
		await get_tree().create_timer(0.1).timeout
		
	$Camera.offset = Vector2.ZERO

func contagem_regressiva():
	%Conta.text = "3"
	await get_tree().create_timer(1).timeout
	%Conta.text = "2"
	await get_tree().create_timer(1).timeout
	%Conta.text = "1"
	await get_tree().create_timer(1).timeout
	%Conta.text = "JÁ!"
	await get_tree().create_timer(1).timeout
	
	contagem_regressiva_finalizada.emit()

func cold_start():
	barra_tempo.max_value = tempo_por_conta
	for i in 2:
		barras_vida[i].max_value = vida_maxima
		barras_vida[i].value = vida_maxima
	%Mensagem.text = ""
	_iniciar_jogo()
