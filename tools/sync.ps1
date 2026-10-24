<#
.SYNOPSIS
    Verifica que las copias espejo del catalogo coincidan con el original.

.DESCRIPTION
    Mientras el proyecto viva dentro de un workspace, hay copias en la carpeta padre
    (AGENTS.md y la skill de mantenimiento) para que un agente abierto en la raiz las lea.
    Esas copias se sincronizan a mano; este chequeo detecta la deriva.

    Si la copia espejo no existe (el proyecto se movio a otro lugar), no falla: informa
    que no hay nada que comparar.

.EXAMPLE
    .\tools\sync.ps1
#>
param()

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Parent = Split-Path -Parent $Root

$MirrorSkill = Join-Path (Join-Path $Parent 'skills') 'catalog-maintenance'
$MirrorSkill = Join-Path $MirrorSkill 'SKILL.md'
$SourceSkill = Join-Path (Join-Path (Join-Path $Root 'skills') 'catalog-maintenance') 'SKILL.md'
$pairs = @(
    @{ Mirror = (Join-Path $Parent 'AGENTS.md'); Source = (Join-Path $Root 'AGENTS.md') },
    @{ Mirror = $MirrorSkill; Source = $SourceSkill }
)

$fail = 0
$checked = 0
$missing = 0

foreach ($p in $pairs) {
    $name = Split-Path $p.Mirror -Leaf
    if (-not (Test-Path -LiteralPath $p.Mirror)) {
        Write-Host ("SKIP   sin copia espejo: {0}" -f $name) -ForegroundColor DarkGray
        $missing++
        continue
    }
    $sourceFirst = @([System.IO.File]::ReadAllLines($p.Source))[0]
    $mirrorFirst = @([System.IO.File]::ReadAllLines($p.Mirror))[0]
    if ($sourceFirst -ne $mirrorFirst) {
        Write-Host ("SKIP   el archivo del padre no es una copia del catalogo: {0}" -f $name) -ForegroundColor DarkGray
        $missing++
        continue
    }
    $checked++
    $sourceHash = (Get-FileHash -LiteralPath $p.Source -Algorithm SHA256).Hash
    $mirrorHash = (Get-FileHash -LiteralPath $p.Mirror -Algorithm SHA256).Hash
    if ($sourceHash -ne $mirrorHash) {
        Write-Host ("FALLO  copia desincronizada: {0}" -f $p.Mirror) -ForegroundColor Red
        Write-Host ("       sincroniza con: Copy-Item '{0}' '{1}' -Force" -f $p.Source, $p.Mirror) -ForegroundColor Yellow
        $fail++
    } else {
        Write-Host ("OK     copia al dia: {0}" -f $p.Mirror) -ForegroundColor Green
    }
}

Write-Host ("Copias: {0} verificada(s), {1} ausente(s)" -f $checked, $missing)

if ($fail -gt 0) {
    Write-Host ("RESULTADO: FALLO ({0} copia(s) desincronizada(s))" -f $fail) -ForegroundColor Red
    exit 1
}

Write-Host "RESULTADO: OK (copias al dia)" -ForegroundColor Green
exit 0
