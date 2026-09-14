# Integração da RUN final — 15 setembro 2026

Aprovação humana final recebida: ciclo completo, identidade, alternância, escala gameplay, shimmer e loop aprovados. Esta execução integrou os PNGs aprovados sem desenhar, regenerar, corrigir sprites ou repetir testes artísticos.

## Assets e implementação

Dez assets oficiais: `assets/sprites/koliani_golden_set/frames/run_final/run_001.png` até `run_010.png`, em ordem01→10→01. São cópias byte a byte de `work/production_art_gate/run_10_motion_review_20260915/gameplay_128/frame_01_128.png` até `frame_10_128.png`. Dez SHA256 distintos e igualdade origem/destino confirmados; `APPROVED_RUN_MANIFEST.json` regista proveniência e hashes.

Contrato aprovado: master1254 inteiro→70×70 NEAREST, posição(29,37), canvasRGBA128×128. Sem alinhamento individual, escala variável ou offsets por frame. Imports lossless, mipmaps desativados e fix_alpha_border desativado para não processar as bordas aprovadas. `scenes/actors/Koliani.tscn` conserva `Sprite/Corpo` como AnimatedSprite2D com Nearest. EscalaCorpo1.0, offset(0,-18), posição local(0,-2), câmara e colisões mantidos. Não há AnimationPlayer/resourceSpriteFrames persistente associado à RUN: `scripts/koliani.gd::_montar_golden_set` monta SpriteFrames em runtime. A personagem Golden Set do nível real usa agora os novos paths.

A montagem anterior é preservada até depois da criação de turn/run_start/run_brake e dos outros derivados; só então a animação `run` recebe os novos dez paths. Assim nenhuma outra animação recebe frames novos. Configurações/rigs alternativos antigos permanecem inalterados.

## Recuperabilidade

Assets antigos continuam em `assets/sprites/koliani_golden_set/frames/run/run_001.png` até `run_010.png`, sem substituição ou eliminação. Backup adicional local em `work/run_final_integration/previous_run/frames/`, código anterior em `previous_run/koliani.gd.txt` e cena em `previous_run/Koliani.tscn.txt`. Copiados antes da substituição. Código anterior também recuperável do commit `f29b8f5c8dc78bdbf6d4238e5dbb8d1a2377a6af`. Remover o bloco RUNfinal restauraria a seleção anterior, cujos assets permanecem disponíveis.

O backup inicialmente com extensão.gd provocou classeKoliani duplicada no scan. Corrigido para.gd.txt, conteúdo preservado, cache rescaneado. Repetição pós-correção confirmou que a regressão foi eliminada. Nenhum erro de parse permanece no teste final.

## Timing e gameplay

Antes e depois: dez frames,13.333333fps, loop:true, duração nominal≈0.750000s. Nenhuma adaptação deFPS necessária. `speed_scale` continua calculado pelo controlador a partir da velocidade, limites0.55–1.85 preservados. Run speed, aceleração, desaceleração, movimento, jump, dash, collider, máscaras, layer e câmara não foram editados.

## Testes executados e resultado real

- Suite existente `res://tests/run_tests.tscn`, Godotheadless: executada antes e depois. FAILglobal:26falhas antes e26depois, lista idêntica, zero novas falhas. PRE-EXISTING: terreno/parallax/foreground9C/9H.7 e amostragem de fontes9H.7B. Logs completos em `work/run_final_integration/run_final_baseline_tests.log` e `run_final_integrated_tests_fixed.log`. Não corrigidos fora do âmbito.
- Teste existente `res://tests/run_movement_camera_4a.tscn`: PASS, exit0. Log `run_final_movement.log`. Inclui arranque, velocidade máxima, paragem, viragem, salto/queda/ar, aterragem e câmara.
- Harness `tests/run_final_integration.gd`: Godot4.7.2VulkanMobile/RTX5070, renderer real1280×720, nívelFloresta_Putrefata e personagem reais; recursos oficiais usados diretamente, sem substituição em memória. Execução baseline antes da integração e execução final com918amostras. PASSfinal/exit0/falhas[]. Todos os índices0–9 observados em run durante deslocamento. Paths01–10, quantidade10, dimensões128, Nearest, loop eFPS conferidos.
- Comparação baseline/final: x/y/vx/vy iguais com tolerância0.001; animação/frame/chão/facing/escala/offset iguais em todas as918amostras. Shape(20,44), máscara/layer iguais. Todas as animações excetoRUN conservaram paths,FPS eloop exatamente.
- IDLE→run_start→RUN, RUN→run_brake→IDLE, inversão comRUN/facing−1/vxnegativo, RUN→jump_start→fall→land→run_start→RUN e corrida/paragem sobreAlcova observados. A inversão anterior não exige o estado`turn`: o harness inicial assumia isso indevidamente; a asserção foi corrigida para verificar movimento/facing reais, sem mudar gameplay.
- Captura real `work/run_final_integration/run_in_level.png`, logs de execução e dados `baseline.json`/`integrated.json` preservados. Não houve avaliação artística nova nem playtest humano adicional: o teste real desta execução é automatizado por input no renderer. Aprovação artística humana é a fornecida pelo utilizador.

WarningsCamera2D e leaksObjectDB já aparecem no baseline. Baseline/finalrenderer:73leaks, sem aumento. Suite e movement preservam ERRORde1recurso em uso ao sair, já existente. Não tratar exit0 sozinho como execução livre de warnings. Não há regressões introduzidas remanescentes.

Reproduzir: `Godot --path C:/Projetos/koliani --fixed-fps 60 --script res://tests/run_final_integration.gd`. Baseline só deve ser produzido numa versão anterior com`-- --baseline`; não sobrescrever a evidência anterior com assets novos. O relógio fixo é para comparação técnica, não prova de desempenho/dispositivo.

## Conclusão

Integração concluída e sem regressões introduzidas. FAIL da suite global é exclusivamentePRE-EXISTING; testes relevantes da integração e movimentoPASS. Commit dedicado autorizado por integração completa e ausência de regressões. Trabalho local alheio não incluído. Usage na conclusão:31%5h/17%semanal.

FINAL RUN ASSETS INTEGRATED: YES
FRAME ORDER 01-10 VALID: YES
128x128 NN ASSETS USED: YES
OLD RUN RECOVERABLE: YES
RUN TIMING VALID: YES
IDLE→RUN VALID: YES
RUN→IDLE VALID: YES
RUN→JUMP VALID: YES
LAND→RUN VALID: YES
DIRECTION CHANGE VALID: YES
COLLISION UNCHANGED: YES
MOVEMENT PHYSICS UNCHANGED: YES
REAL GODOT PLAYTEST: PASS
TESTS: FAIL
RUN INTEGRATION COMPLETE: YES
