extends CharacterBody2D
## Boneco de bancada: faz de Koliani para as ZONAS, e guarda o que elas lhe
## pediram. A Koliani a serio nao se consegue instanciar em `--script` (fala
## com autoloads pelo identificador), e sem isto nao havia como provar que
## uma zona que so' mexe em NUMEROS -- e nao na posicao -- faz alguma coisa.

var grav_escala := 1.0
var acel_escala := 1.0


func definir_grav_escala(v: float) -> void:
	grav_escala = v


func definir_acel_escala(v: float) -> void:
	acel_escala = v
