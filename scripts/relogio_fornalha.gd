class_name RelogioFornalha
extends RefCounted
## Relogio unico dos mecanismos temporizados da Fornalha que contam desde o
## arranque do no' (`PistaoFornalha`, e `JatoFornalha`/`PlataformaRitmada` com
## `relogio_local` ou ligados a uma valvula).
##
## Em jogo e' o relogio de parede (`manual < 0`, o comportamento de sempre).
## As bancadas (prova de travessia, testes) fixam `manual` para o tempo ser o
## da FISICA e nao o da parede: o Godot headless corre muitas vezes mais depressa
## que o tempo real e, sem isto, o piloto e os perigos deixavam de falar a mesma
## lingua.

## Segundos fixados pela bancada (< 0 = usar o relogio de parede).
static var manual := -1.0


static func agora() -> float:
	return manual if manual >= 0.0 else Time.get_ticks_msec() * 0.001
