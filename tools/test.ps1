<#
.SYNOPSIS
    Tests minimos de integracion para el instalador (sin tocar el repo).
#>
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Install = Join-Path $Root 'tools\install.ps1'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$failed = 0

function Test-Case {
    param([string]$Name, [scriptblock]$Script)
    Write-Host ("[TEST] {0}" -f $Name)
    try {
        & $Script
        Write-Host "  OK" -ForegroundColor Green
    } catch {
        Write-Host ("  FALLO: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $script:failed++
    }
}

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-baseline-test-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Force -Path $temp | Out-Null

try {
    Test-Case "Uninstall conserva AGENTS.md ajeno sin marcadores" {
        $proj = Join-Path $temp 'p1'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $agents = Join-Path $proj 'AGENTS.md'
        [System.IO.File]::WriteAllText($agents, "# Mi proyecto`nSin marcadores de agent-baseline`n", $Utf8)
        & $Install -Project $proj -Skills angular -Target none -Force | Out-Null
        if (-not (Test-Path (Join-Path $proj '.baseline'))) { throw "No se instalo .baseline" }
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (-not (Test-Path $agents)) { throw "Se borro AGENTS.md ajeno" }
        $t = [System.IO.File]::ReadAllText($agents)
        if ($t -match 'agent-baseline:start') { throw "Quedo bloque de marcadores" }
    }

    Test-Case "Uninstall quita solo bloque con marcadores" {
        $proj = Join-Path $temp 'p2'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $agents = Join-Path $proj 'AGENTS.md'
        $txt = "# Mi README`n<!-- agent-baseline:start -->`n> puntero`n<!-- agent-baseline:end -->`nSigue mi texto`n"
        [System.IO.File]::WriteAllText($agents, $txt, $Utf8)
        & $Install -Project $proj -Skills none -Target none -Force | Out-Null
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (-not (Test-Path $agents)) { throw "Se borro AGENTS.md con contenido propio" }
        $t2 = [System.IO.File]::ReadAllText($agents)
        if ($t2 -match 'agent-baseline') { throw "Quedo rastro del bloque" }
        if ($t2 -notmatch 'Sigue mi texto') { throw "Se perdio contenido propio" }
    }

    Test-Case "opencode.json fusionado con datos propios NO se borra entero" {
        $proj = Join-Path $temp 'p3'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $cfg = Join-Path $proj 'opencode.json'
        [System.IO.File]::WriteAllText($cfg, '{"model":"mistral-large","provider":{"name":"ollama"}}', $Utf8)
        & $Install -Project $proj -Skills angular -Target opencode -Force | Out-Null
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (-not (Test-Path $cfg)) { throw "Se borro opencode.json fusionado" }
        $c = [System.IO.File]::ReadAllText($cfg)
        if ($c -notmatch 'mistral-large') { throw "Se perdio model propio" }
    }

    Test-Case "opencode.json creado por instalador se elimina" {
        $proj = Join-Path $temp 'p4'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target opencode -Force | Out-Null
        $cfg = Join-Path $proj 'opencode.json'
        if (-not (Test-Path $cfg)) { throw "No se creo opencode.json" }
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (Test-Path $cfg) { throw "No se elimino opencode.json creado por instalador" }
    }

    Test-Case "memory.ps1 sin replace '/' -> '\\' (multiplataforma)" {
        $mem = Join-Path $Root 'tools\memory.ps1'
        $t = [System.IO.File]::ReadAllText($mem)
        if ($t -match "-replace\s+'/'\s*,\s*'\\\\'") { throw "Sigue usando -replace '/' '\' " }
    }

    Test-Case "UTF-8 con caracteres especiales en opencode.json fusionado" {
        $proj = Join-Path $temp 'p5'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $cfg = Join-Path $proj 'opencode.json'
        [System.IO.File]::WriteAllText($cfg, '{"model":"mistral-nandu"}', $Utf8)
        & $Install -Project $proj -Skills angular -Target opencode -Force | Out-Null
        $c2 = [System.IO.File]::ReadAllText($cfg)
        if ($c2 -notmatch 'mistral-nandu') { throw "Se perdio caracter especial" }
    }

    Test-Case "-Update quita skill no declarada" {
        $proj = Join-Path $temp 'p6'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular,docker -Target none -Force | Out-Null
        $m = Join-Path $proj '.baseline.json'
        $json = [System.IO.File]::ReadAllText($m) | ConvertFrom-Json
        $json.skills = @('angular')
        [System.IO.File]::WriteAllText($m, ($json | ConvertTo-Json -Depth 6), $Utf8)
        & $Install -Project $proj -Update -Force | Out-Null
        if (Test-Path (Join-Path $proj '.baseline\skills\docker')) { throw "No se quito skill no declarada con -Update" }
    }
} finally {
    try { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

Write-Host ""
if ($failed -gt 0) {
    Write-Host ("FALLOS: {0}" -f $failed) -ForegroundColor Red
    exit 1
}
Write-Host "RESULTADO: OK" -ForegroundColor Green
exit 0
