class_name BalanceCombate
extends Resource
## FASE 1 -- fundação de configuração do combate de produção (execução
## "Controlled Combat Integration"). Separa BALANCE DATA (este ficheiro)
## de CORE LOGIC (que continua em `scripts/lab/combate_lab.gd`, congelado,
## e passará para `scripts/combate/core_combate.gd` nas Fases 2-6).
##
## Nesta fase NADA lê este recurso ainda -- é só a estrutura + os números
## de referência do Combat Lab v1.2 (`docs/combat_lab_v1_2.md`), prontos
## para as Fases seguintes (Launcher, Cleave, Dash Attack, Perfect Dodge,
## Counter) passarem a ler daqui em vez de constantes soltas. Nenhum nível
## ganha comportamento novo só por este ficheiro existir.
##
## Uma instância por perfil de dificuldade, se algum dia precisar (hoje só
## `resources/combate/balance_combate_v1.tres`, cópia 1:1 da v1.2 do Lab).

## --- Janelas gerais (segundos) ---
@export var pd_janela := 0.22          # o golpe inimigo tem de cair nos primeiros X s do roll
@export var pd_cooldown := 0.90
@export var counter_janela := 0.60     # depois do Perfect Dodge
@export var carga_cleave_t := 0.50     # segurar ATAQUE para o Shadow Cleave
@export var ar_max := 2                # golpes aéreos por salto
@export var buffer_t := 0.14           # buffer de input entre golpes

## --- Clamp do avanço (não atravessar o alvo) ---
@export var clamp_avanco := true
@export var clamp_tolerancia := 10.0   # px que pode entrar no corpo do alvo
@export var k_meia_largura := 10.0

## --- Multiplicadores do combo básico (hierarquia v1.2: martelar paga menos) ---
@export var base_dano_mult: Array[float] = [0.30, 0.35, 0.43, 0.60]
@export var ar_dano_mult: Array[float] = [1.40, 1.60]   # air 1 / air 2
@export var recup_extra_remate := 0.12                  # s extra só no 4.º golpe (chão)

## --- Energia por acção (0-99; Especial custa 33; regen global inalterada) ---
@export var energia_launcher := 5.0
@export var energia_dash_atk := 5.0
@export var energia_cleave := 8.0
@export var energia_counter := 10.0
@export var energia_perfect_dodge := 25.0
@export var energia_pogo := 8.0
## Golpe normal / Pogo de produção não estão aqui: já são geridos por
## `Koliani.ENERGIA_POR_GOLPE` e pelo Pogo existente -- não duplicar a
## fonte de verdade sem necessidade (ver plano §2).

## --- Frame data dos golpes novos (segundos; 60 Hz = 0,0167 s/frame) ---
## Mesma forma do `MOVES` em `combate_lab.gd`, para o `core_combate.gd`
## (Fase 2+) poder ler o dicionário inteiro em vez de campo a campo.
@export var moves: Dictionary = {
	"launcher": {"startup": 0.10, "ativo": 0.10, "recup": 0.24, "mult": 1.3, "guard_break": false,
		"rect": Rect2(-10.0, -104.0, 92.0, 132.0), "energia": 5.0, "passo_visual": 2,
		"avanco": 0.0, "avanco_dur": 0.0, "hitstop": 0.014},
	"dash": {"startup": 0.04, "ativo": 0.10, "recup": 0.22, "mult": 1.3, "guard_break": false,
		"rect": Rect2(-6.0, -44.0, 96.0, 76.0), "energia": 5.0, "passo_visual": 0,
		"avanco": 300.0, "avanco_dur": 0.14, "hitstop": 0.012},
	"cleave": {"startup": 0.14, "ativo": 0.12, "recup": 0.40, "mult": 2.3, "guard_break": true,
		"rect": Rect2(-10.0, -56.0, 128.0, 90.0), "energia": 8.0, "passo_visual": 3,
		"avanco": 160.0, "avanco_dur": 0.12, "hitstop": 0.030},
	"counter": {"startup": 0.06, "ativo": 0.12, "recup": 0.16, "mult": 2.7, "guard_break": true,
		"rect": Rect2(-10.0, -56.0, 140.0, 90.0), "energia": 10.0, "passo_visual": 3,
		"avanco": 520.0, "avanco_dur": 0.14, "hitstop": 0.040},
}
