# Scaffold de remaster Região I — 9H.12A

Fonte única: `data/regiao1/remaster.json`. O runtime lê o manifesto via
`scripts/regiao1_remaster.gd`; `regiao1_kit.gd` já consome os perfis e tintas,
e `region1_hybrid_visual_target.gd` já consome as densidades de fundo.
Os valores atuais foram conservados. As cenas L1–L5 não foram editadas.

| Slot | Nó em RemasterRegiaoI | Uso |
| --- | --- | --- |
| far_background | FundoDistante | panorama ilustrado, distância |
| mid_background | FundoMedio | bosque/ruínas de média distância |
| gameplay_terrain | TerrenoVisual | pele visual dos apoios; sem colisões |
| front_silhouettes | SilhuetasFrente | enquadramento escuro frontal |
| atmospheric_vfx | AtmosferaVFX | névoa, partículas, luz e shaders |
| landmark_layers | Landmarks | marcos de progressão e identidade |

Cada nível define `tema`, `visual_atual`, seis listas `camadas` e `plano_mapa`.
Cada slot define z/parallax e aponta por metadata às camadas legadas que
continuam ativas. Os novos slots são aditivos e vazios nesta execução.
Não há desligamento automático do legado nem duplicação de arte por defeito.
Um passe de substituição deve retirar apenas a camada antiga correspondente,
preservar composição/contraste e validar o resultado com renderer real.
O landmark Heart Tree atual está pintado no panorama; não é um sprite isolado.

Para inserir uma ilustração numa lista de camada:

```json
{"textura":"res://assets/art/remaster/landmark.png","posicao":[1200,400],"escala":[1,1],"pixel":false,"cor":"ffffff","z_relativo":0}
```

O exemplo é de formato, não um asset existente. Para VFX usar `cena` em vez
de `textura`, com uma cena Node2D em `assets/`. A API rejeita corpos, áreas
e formas de colisão na árvore da cena visual. Scripts dessas cenas só podem
tratar apresentação. Sampler linear por defeito, nearest apenas com `pixel:true`.
Posição/escala são locais ao alvo visual com a câmara em `referencia`;
o parallax do slot é atualizado junto das camadas atuais. Import de assets
ilustrados, alfa, mipmaps e orçamento de VFX devem ser revistos no passe de arte.
Assets continuam sujeitos a licença gratuita/CC0 e créditos do projeto.

`plano_mapa` regista zonas normalizadas de progressão para patamares adicionais,
landmarks e tratamento visual das colunas. `aplicar_geometria:false` não é um
interruptor de geração: o runtime não aplica estes planos nem cria plataformas.
Spawn, checkpoints, porta, arena e jogabilidade base são invariantes a validar
quando houver mapas novos. A viabilidade dos saltos futuros ainda não foi provada.
HUMAN PLAYTEST REQUIRED antes de aceitar qualquer remodelação de percurso.

Validar o contrato: `python tools/validar_remaster_regiao1.py`.
Runtime dirigido: `Godot --headless res://tests/run_9h12a.tscn`.
Este teste reinicia uma campanha sintética: executar com APPDATA isolado,
como nos logs `work/9h12a/`, para não tocar no progresso do utilizador.
Smoke visual: mesma cena sem headless, `--screen 1 --position 20,20`.
O manifesto está incluído explicitamente nos presets de export.

Double jump: o design base de L1 é salto simples. O tutorial `saltos` escolhe
`mec.saltos.txt_basico` sem habilidade e conserva o texto de double jump
para saves/contextos que tenham `salto_duplo`. Não muda desbloqueios.

Portal: baseline produziu a remoção inválida de CollisionObject2D dentro de
body_entered tanto em headless como Vulkan; o processo não caiu nessas provas.
A conclusão agora é diferida e protegida contra reentrada. Teste real atravessa
o portal por input, confirma uma vida concedida, L1 concluído, sessão L2,
save recarregável e cena L2 ativa. Não altera o sistema global de progressão.
