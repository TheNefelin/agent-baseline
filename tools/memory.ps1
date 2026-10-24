<#
.SYNOPSIS
    Verifica que la memoria del proyecto no tenga rutas muertas.

.DESCRIPTION
    Lee el "Mapa del proyecto" de DEVELOPMENT.md y comprueba que cada ruta citada en
    backticks exista en disco. Un mapa que apunta a archivos que ya no estan es peor
    que no tener mapa: manda al agente a leer algo inexistente.

    Reglas:
      - Solo se validan rutas que empiezan por un directorio conocido del repo
        (skills/, tools/, evals/, templates/, archive/, docs/).
      - Una ruta citada en el mapa que no existe -> fallo.
      - Sin seccion de mapa -> aviso (no fallo), salvo -RequireMap.
      - Un mapa con menos de 2 filas utiles -> aviso.

.PARAMETER RequireMap
    Falla si no hay "Mapa del proyecto" en DEVELOPMENT.md.

.EXAMPLE
    .\tools\memory.ps1
    .\tools\memory.ps1 -RequireMap
#>
param(
    [switch]$RequireMap
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Doc = Join-Path $Root 'DEVELOPMENT.md'

$KnownRoots = @('skills', 'tools', 'evals', 'templates', 'archive', 'docs')

function Test-KnownPath {
    param([string]$Rel)
    if ([string]::IsNullOrWhiteSpace($Rel)) { return $null }
    $parts = $Rel -split '[\\/]+'
    if ($parts.Count -eq 0) { return $null }
    $first = $parts[0]
    if ($KnownRoots -notcontains $first) { return $null }
    $normalized = ($Rel -replace '[\\/]+', [System.IO.Path]::DirectorySeparatorChar)
    $full = Join-Path $Root $normalized
    return (Test-Path -LiteralPath $full)
}

if (-not (Test-Path -LiteralPath $Doc)) {
    Write-Host "FALLO  no existe DEVELOPMENT.md" -ForegroundColor Red
    exit 1
}

$lines = @([System.IO.File]::ReadAllLines($Doc, [System.Text.Encoding]::UTF8))

$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#+\s+Mapa') { $start = $i; break }
}

if ($start -lt 0) {
    if ($RequireMap) {
        Write-Host "FALLO  DEVELOPMENT.md no tiene seccion 'Mapa del proyecto'" -ForegroundColor Red
        exit 1
    }
    Write-Host "AVISO  sin seccion de mapa; nada que verificar" -ForegroundColor Yellow
    exit 0
}

$end = $lines.Count
for ($i = $start + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#+\s+') { $end = $i; break }
}

$fail = 0
$checked = 0
$rows = 0

for ($i = $start; $i -lt $end; $i++) {
    $line = $lines[$i]
    if ($line -notmatch '^\s*\|') { continue }
    if ($line -match '^\s*\|\s*-{2,}') { continue }
    $rows++
    foreach ($m in [regex]::Matches($line, '`([^`]+)`')) {
        $rel = $m.Groups[1].Value.Trim()
        if ($rel -match '[\*\?<>|]') { continue }
        $ok = Test-KnownPath $rel
        if ($null -eq $ok) { continue }
        $checked++
        if (-not $ok) {
            Write-Host ("FALLO  ruta del mapa no existe: {0}" -f $rel) -ForegroundColor Red
            $fail++
        }
    }
}

Write-Host ("Mapa: {0} fila(s), {1} ruta(s) verificada(s)" -f $rows, $checked)

if ($rows -lt 3) {
    Write-Host "AVISO  el mapa tiene menos de 2 filas utiles" -ForegroundColor Yellow
}

if ($fail -gt 0) {
    Write-Host ("RESULTADO: FALLO ({0} ruta(s) muerta(s))" -f $fail) -ForegroundColor Red
    exit 1
}

Write-Host "RESULTADO: OK (memoria sin rutas muertas)" -ForegroundColor Green
exit 0
