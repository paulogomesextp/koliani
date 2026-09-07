---
name: koliani-validar-niveis
description: Validar geometria, percursos, interiores e geradores dos níveis de Koliani no Godot. Usar em remodelações de níveis e antes de publicar esses lotes.
---

# Validar níveis de Koliani

Partir da raiz do projeto; consultar AGENTS.md para executável e regras.
Identificar níveis alterados e afetados por scripts partilhados.

## Antes de editar

Registar lista exata, comportamento esperado e prova por etapa em
`docs/plano_atual.md` quando há vários níveis. Esclarecer se «todos» significa
dez masmorras ou cem níveis; não reduzir o âmbito em silêncio.
Verificar geradores antes de editar saídas.

## Escolher provas úteis

- Importar após assets e fazer smoke das cenas afetadas. Ler erros de scripts
  e autoloads mesmo quando a suite imprime OK.
- Geometria: `--headless --script res://tools/verifica_alcance.gd -- <cena>`.
  Para mudanças partilhadas, `tools/verifica_alcance_todos.gd`. O crivo é
  aproximado e exclui uma arena; não equivale a jogar cem níveis.
- Interiores: `tools/verifica_interiores_masmorras.gd` mede folgas e pode gerar
  folha visual. Folgas não validam saltos, plataformas móveis nem bosses.
- Movimento: usar Koliani real desde antes até depois do obstáculo, sem
  teletransportes entre os passos que se pretendem provar. Bancadas existentes:
  `tools/verifica_raiz_elevatoria.gd` e `tools/verifica_camara_seiva.gd`.
- Aparência: `tools/shot_plataforma.gd` com OpenGL real; confirmar captura sem
  erros, abrir imagem e corrigir problemas observados.
- Regressões: suite geral para lógica partilhada; distinguir falhas anteriores
  de novas. Não repetir verificações aprovadas sem alteração relevante.

## Fechar lote

Registar comandos, resultados e limites da prova. Só marcar completo após
todos os critérios acordados passarem. Testes bloqueados: guardar estado e
explicar causa; não chamar concluído nem fazer commit antecipado.
Respeitar commit único no fim do lote e consultar usage na entrega.
