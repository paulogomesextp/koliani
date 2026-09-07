# Gera a alvenaria das dez masmorras sem alterar atmosfera nem plataformas.
# Reserva 320 px acima dos atores de cada setor para saltos e mecanismos.
$ErrorActionPreference = 'Stop'
$raizProjeto = Split-Path $PSScriptRoot -Parent
$nomes = @('Prisao_dos_Condenados', 'Fornalha_dos_Pecadores', 'Corredor_das_Execucoes', 'Ala_dos_Mortos', 'A_Cela_Zero', 'Cemiterio_dos_Reis', 'Galeria_dos_Ossos', 'Cripta_das_Mil_Velas', 'Templo_da_Serpente', 'O_Abismo')
$largurasSetores = @(480, 576, 384, 512, 320, 640, 352, 448, 416, 544)
for ($indice = 0; $indice -lt $nomes.Count; $indice++) {
    $caminho = Join-Path $raizProjeto ('scenes/levels/' + $nomes[$indice] + '.tscn')
    $texto = [IO.File]::ReadAllText($caminho)
    $blocos = [regex]::Matches($texto, '(?ms)^\[node[^\r\n]+\].*?(?=^\[node|\z)')
    $atores = @()
    foreach ($bloco in $blocos) {
        if ($bloco.Value -match 'name="(?:Luz|Check|Atmosfera|Casca|CollisionShape|Acido|Lava|Trevas|Poca)') { continue }
        $pos = [regex]::Match($bloco.Value, 'position = Vector2\(([-\d.]+), ([-\d.]+)\)')
        if ($pos.Success) { $atores += ,@([double]$pos.Groups[1].Value, [double]$pos.Groups[2].Value) }
    }
    $maxX = ($atores | ForEach-Object { $_[0] } | Measure-Object -Maximum).Maximum + 192
    $topo = [math]::Floor((($atores | ForEach-Object { $_[1] } | Measure-Object -Minimum).Minimum - 640) / 32) * 32
    $volumes = @()
    $passo = $largurasSetores[$indice]
    for ($x = 8; $x -lt $maxX; $x += $passo) {
        # A margem horizontal também protege saltos que cruzam setores.
        $vizinhos = @($atores | Where-Object { $_[0] -ge ($x - 320) -and $_[0] -le ($x + $passo + 320) })
        if ($vizinhos.Count -eq 0) { continue }
        $minY = ($vizinhos | ForEach-Object { $_[1] } | Measure-Object -Minimum).Minimum
        $base = [math]::Floor(($minY - 320 - $topo) / 32) * 32 + $topo
        $altura = [math]::Max(32, $base - $topo)
        $volumes += "Rect2($x, $topo, $passo, $altura)"
    }
    $linha = 'volumes_interiores = Array[Rect2]([' + ($volumes -join ', ') + '])'
    $texto = [regex]::Replace($texto, '(?m)^volumes_interiores = .*\r?\n', '')
    if ($texto -notmatch 'name="Casca"') {
        $recurso = '[ext_resource type="PackedScene" path="res://scenes/actors/CascaMasmorra.tscn" id="interior_casca"]'
        $posicao = $texto.IndexOf('[sub_resource')
        $texto = $texto.Insert($posicao, $recurso + "`n`n")
        $texto = [regex]::Replace($texto, 'load_steps=(\d+)', { param($m) 'load_steps=' + ([int]$m.Groups[1].Value + 1) })
        $texto += "`n[node name=`"Casca`" parent=`".`" instance=ExtResource(`"interior_casca`")]`nesquerda = -120.0`nchao = false`nagua = false`n"
    }
    $texto = [regex]::Replace($texto, '(?ms)(^\[node name="Casca"[^\r\n]+\]\r?\n)(.*?)(?=^\[node|\z)', {
        param($m)
        $props = [regex]::Replace($m.Groups[2].Value, '(?m)^(?:topo|altura|largura) = .*\r?\n', '')
        $m.Groups[1].Value + "topo = $topo.0`naltura = 2200.0`nlargura = $($maxX + 240).0`n" + $linha + "`n" + $props
    })
    [IO.File]::WriteAllText($caminho, $texto, [Text.UTF8Encoding]::new($false))
    Write-Output ($nomes[$indice] + ': ' + $volumes.Count + ' setores')
}
