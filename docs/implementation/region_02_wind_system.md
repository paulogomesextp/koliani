# Região II — sistema reutilizável de vento

## Âmbito

Este processo cria a infraestrutura de vento do Desfiladeiro dos Ventos sem
alterar os níveis N06–N10. Vento é sempre uma força externa local: não é uma
habilidade da Koliani e não altera permanentemente gravidade, velocidade,
aceleração, progressão ou save.

N08 glide **não foi implementado**. O boss do N10 **não foi implementado**.
N06–N10 **não foram remodelados** neste processo.

## Arquitetura

- `scenes/actors/WindZone.tscn`: componente `Area2D` reutilizável e sem arte
  final.
- `scripts/wind_zone.gd`: deteção de corpos, configuração, pulsos e hooks de
  feedback.
- `scripts/koliani.gd`: registo por origem, expiração defensiva e composição
  das influências ativas.
- `scripts/movimento.gd`: matemática pura que soma uma aceleração externa sem
  mudar os parâmetros do movimento base.
- `tests/test_wind_system.gd`: casos determinísticos da força.
- `tests/run_wind_system.gd` e `.tscn`: harness com `WindZone` e `Koliani`
  reais no motor.

Cada zona renova a sua influência em todos os physics frames enquanto o corpo
está dentro. A saída remove-a imediatamente. Um TTL curto elimina também uma
entrada se a zona for libertada, ocorrer teleporte ou se perder um sinal de
saída. A chave é o `instance_id` da zona; por isso duas ou mais zonas coexistem
sem partilhar um booleano global e sem deixar vento preso.

## Contrato de `WindZone`

Propriedades exportadas:

- `direcao`: vetor livre; `(1, 0)` sopra para a direita, `(-1, 0)` para a
  esquerda e `(0, -1)` cria uma corrente ascendente.
- `intensidade`: aceleração em px/s².
- `velocidade_max`: limite da componente de velocidade no sentido do vento.
  Zero desativa o limite.
- `tamanho`: largura e altura da área retangular.
- `ativa`: permite desligar a zona sem a remover.
- `modo`: `CONTINUO` ou `PULSADO`.
- `duracao_pulso`, `intervalo_pulso` e `fase_inicial`: ciclo do modo pulsado.

`definir_multiplicador_externo(valor)` é o hook para variação futura, por
exemplo controlada por uma timeline, alavanca ou controlador do N09.

Sinais disponíveis para feedback futuro:

- `corpo_entrou(corpo)`;
- `corpo_saiu(corpo)`;
- `intensidade_mudou(multiplicador)`.

Nenhum SFX, partícula ou arte final está ligado neste processo.

## Como a força chega ao player

`WindZone` chama `Koliani.atualizar_vento(self, aceleracao, velocidade_max)`.
O player guarda uma entrada por zona e, depois de resolver corrida, salto,
rolamento, dash e gravidade do frame, aplica cada força através de
`Movimento.aplicar_forca_externa`. A `velocity` final segue depois para o
`move_and_slide` normal e é sincronizada com `Movimento.Estado`.

O limite é aplicado apenas à projeção da velocidade no sentido do vento. A
componente perpendicular e a velocidade já existente no sentido contrário
não são apagadas. Influências sobrepostas compõem-se em ordem estável pelo ID
da origem.

## Interações

- **Gravidade:** não é modificada. Um updraft soma aceleração para cima à
  velocidade resultante do frame.
- **Salto, coyote time, jump buffer e variable jump:** continuam a ser
  resolvidos por `Movimento.passo`; o vento é somado depois.
- **Air control:** permanece no caminho existente e pode contrariar ou
  acompanhar o vento.
- **Dash e rolamento:** mantêm os respetivos estados e velocidades; o vento
  soma força externa no mesmo frame, sem os substituir.
- **Colisão e plataformas:** continuam em `move_and_slide`; não há alteração
  de layers, shapes ou plataforma móvel.
- **Wall slide, ledge grab e gancho:** estes estados exclusivos mantêm o seu
  caminho e ignoram vento enquanto controlam integralmente a posição. Esta é
  uma limitação deliberada para não quebrar interações existentes.
- **Knockback/dano:** o sistema não muda o contrato de dano. Qualquer impulso
  existente conserva a sua velocidade e recebe a soma normal do vento.
- **Morte/transição:** a recarga de cena elimina player e zonas. O respawn no
  mesmo player limpa `velocity`, o estado interno e todas as influências; uma
  zona que contenha o novo checkpoint volta a renovar-se no frame seguinte.
- **Fly mode:** ignora vento, preservando a ferramenta Dev.

## Colocar uma zona num nível

1. Instanciar `res://scenes/actors/WindZone.tscn`.
2. Posicionar a área e definir `tamanho` para cobrir apenas o espaço desejado.
3. Definir `direcao`, `intensidade` e `velocidade_max`.
4. Para rajadas, escolher `PULSADO` e configurar duração/intervalo. Para vento
   variável, controlar `definir_multiplicador_externo` e ligar feedback ao
   sinal `intensidade_mudou`.
5. Validar geometria, percurso e sensação no nível real antes de publicar.

## Validação

O harness dirigido cobre:

- A: baseline sem vento;
- B/C: vento horizontal fraco/forte;
- D: vento oposto ao movimento;
- E: updraft;
- F: salto dentro da zona;
- G/H: entrada e saída;
- I: dash dentro da zona;
- J: respawn após vento;
- K: transição entre duas zonas;
- L: ausência de força residual.

Comandos previstos:

```powershell
godot --headless --path . res://tests/run_wind_system.tscn
pwsh tools/correr_testes.ps1
```

Resultados em 16 de setembro de 2026, Godot 4.7.2:

- importação headless do checkout fresco: `EXIT 0`;
- `run_wind_system.tscn`: `OK -- Region II reusable WindZone (A-L)`,
  `EXIT 0`;
- `run_movement_camera_4a.tscn`: PASS, `EXIT 0`;
- `tools/correr_testes.ps1`: `OK -- todos os testes passaram`, `EXIT 0`;
- save real: SHA-256 inalterado
  `2A82B243C5C635CF5E00DC258ABDA223241E9CCAC0A7093AA70DE9FD26F5B9E8`.

Os runners terminam com avisos já observáveis no targeted Movement+Camera
sobre objetos/recursos retidos no shutdown imediato. Não houve erro fatal nem
falha de teste.

## Limitações e próximos passos

- Os valores de intensidade e velocidade ainda não foram afinados em layouts
  reais; isso exige `HUMAN PLAYTEST REQUIRED`.
- A validação em browser/telemóvel exige `DEVICE VALIDATION REQUIRED`.
- N06 deve instanciar rajadas horizontais; N07, correntes ascendentes; N09,
  variação/pulsos ligados a feedback legível.
- A `CorrenteAr` e a `CorrenteLateral` legadas continuam intactas. A sua
  eventual migração para `WindZone` deve ser um lote separado com regressão
  dos consumidores atuais.
