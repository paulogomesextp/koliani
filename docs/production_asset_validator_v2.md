# Production Asset Validator v2

Validador técnico determinístico e conservador para frames PNG individuais e
diretórios de animação. Não decide qualidade artística, não promove assets e
nunca modifica PNGs de origem. A aprovação visual continua a pertencer ao Game
Master.

## Contrato

O manifesto JSON aceita `character`, `animation`, `frame_count`,
`canvas_width`, `canvas_height`, `pivot_x`, `pivot_y`, `baseline_y`,
`baseline_tolerance`, `asset_type` (`BODY`, `VFX`, `ENVIRONMENT`, `UI` ou
`OTHER`), `expected_alpha`, `vfx_separate`, `frames`, `reference_path` e
`reference_sha256`. Contagens finais não estão hardcoded; 9B fornecerá os
valores. Ver `tools/production_asset_validator/example_manifest.json`.

Os caminhos dos frames são relativos ao manifesto. `reference_path` é apenas
registado e, quando aponta para um ficheiro existente, recebe SHA256. A
referência nunca é aberta para classificação visual.

## Utilização

```powershell
python -m tools.production_asset_validator.cli manifest.json `
  --json work/report.json `
  --markdown work/report.md `
  --contact-sheet work/contact_sheet.png
```

O exit code é 1 quando a animação termina em `FAIL`; `PASS` e `REVIEW` devolvem
0 para permitir que a revisão humana seja encaminhada separadamente. Os
relatórios incluem hash, tamanho, formato, dimensões, modo, estatísticas alpha,
bounds, clipping, baseline, pivot, consistência e achados por frame.

## Checks e limites

- PNG legível, modo RGBA, canal alpha e pixels alpha 0 reais;
- canvas esperado, bounds opacos e clipping nos quatro limites;
- baseline observada, tolerância, provável corte de pés e deriva vertical;
- pivot dentro do canvas e relação pivot/baseline registada;
- dimensões/modo, área ocupada, escala e deriva de bounds entre frames;
- checkerboard periódico, bordas de folha, separadores e possíveis faixas de
  rótulo como heurísticas conservadoras;
- componentes destacados em frames `BODY` encaminhados para revisão manual.

Heurísticas não provam presença de texto, VFX nem limpeza artística. Casos
ambíguos usam `MANUAL_REVIEW_REQUIRED`; o resumo da animação usa `REVIEW`.
Sprites com partes corporais legitimamente destacadas podem produzir falsos
positivos. O limiar alpha e limites de escala/deriva podem ser configurados.

## Contact sheet

O contact sheet copia pixels em 1:1 sobre fundo neutro e acrescenta número,
nome, baseline e pivot. `--scale N` permite apenas escala inteira explícita com
nearest-neighbour. O PNG produzido é saída de revisão, nunca asset de produção.

## Testes e fixtures

As fixtures são totalmente sintéticas e cobrem RGBA válido, RGB sem alpha,
clipping inferior, canvas inconsistente, baseline fora da tolerância e
checkerboard suspeito.

```powershell
python tools/production_asset_validator/tests/generate_fixtures.py
python -m unittest tools.production_asset_validator.tests.test_validator -v
```

Os testes confirmam determinismo do relatório, SHA estável, imutabilidade das
fontes, razões esperadas de falha e geração do contact sheet.
