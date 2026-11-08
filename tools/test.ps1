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

# Las pruebas de exit != 0 corren el instalador en un proceso hijo: asi el 'exit'
# del script no compite con el flujo de este archivo.
$ShellExe = 'powershell'
try { $shellPath = (Get-Process -Id $PID).Path; if ($shellPath) { $ShellExe = $shellPath } } catch {}

function Invoke-InstallChild {
    param([string[]]$CliArgs)
    $all = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Install) + $CliArgs
    $out = & $ShellExe @all 2>&1
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = (@($out) -join "`n") }
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
        & $Install -Project $proj -Skills angular -Target none -Force | Out-Null
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

    Test-Case "El puntero AGENTS.md lista las skills instaladas" {
        $proj = Join-Path $temp 'p7'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular,sql -Target none -Force | Out-Null
        $t3 = [System.IO.File]::ReadAllText((Join-Path $proj 'AGENTS.md'))
        if ($t3 -notmatch 'Skills instaladas') { throw "El puntero no declara skills" }
        if ($t3 -notmatch 'angular' -or $t3 -notmatch 'sql') { throw "El puntero no lista las skills declaradas" }
        if ($t3 -notmatch '\.baseline/skills') { throw "El puntero no indica donde viven" }
    }

    Test-Case "-Update refresca la lista de skills del puntero" {
        $proj = Join-Path $temp 'p8'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular,docker -Target none -Force | Out-Null
        $m2 = Join-Path $proj '.baseline.json'
        $json2 = [System.IO.File]::ReadAllText($m2) | ConvertFrom-Json
        $json2.skills = @('angular')
        [System.IO.File]::WriteAllText($m2, ($json2 | ConvertTo-Json -Depth 6), $Utf8)
        & $Install -Project $proj -Update -Force | Out-Null
        $t4 = [System.IO.File]::ReadAllText((Join-Path $proj 'AGENTS.md'))
        if ($t4 -match 'docker') { throw "El puntero conservo una skill no declarada" }
        if ($t4 -notmatch 'angular') { throw "El puntero perdio la skill declarada" }
    }

    Test-Case "-Skills acepta una lista separada por comas en un solo argumento" {
        $proj = Join-Path $temp 'p9'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills 'angular,sql' -Target none -Force | Out-Null
        if (-not (Test-Path (Join-Path $proj '.baseline\skills\angular'))) { throw "No instalo angular" }
        if (-not (Test-Path (Join-Path $proj '.baseline\skills\sql'))) { throw "No instalo sql" }
    }

    Test-Case "Target cline crea y quita su puntero" {
        $proj = Join-Path $temp 'p10'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target cline -Force | Out-Null
        $ptr = Join-Path $proj '.clinerules/agent-baseline.md'
        if (-not (Test-Path -LiteralPath $ptr)) { throw "No se creo el puntero de Cline" }
        $t = [System.IO.File]::ReadAllText($ptr)
        if ($t -notmatch '\.baseline/AGENTS\.md') { throw "El puntero de Cline no deriva a .baseline/AGENTS.md" }
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (Test-Path -LiteralPath $ptr) { throw "No se elimino el puntero de Cline" }
    }

    Test-Case "Target kilo crea y quita su puntero" {
        $proj = Join-Path $temp 'p11'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target kilo -Force | Out-Null
        $ptr = Join-Path $proj '.kilocode/rules/agent-baseline.md'
        if (-not (Test-Path -LiteralPath $ptr)) { throw "No se creo el puntero de Kilo" }
        $t = [System.IO.File]::ReadAllText($ptr)
        if ($t -notmatch '\.baseline/AGENTS\.md') { throw "El puntero de Kilo no deriva a .baseline/AGENTS.md" }
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (Test-Path -LiteralPath $ptr) { throw "No se elimino el puntero de Kilo" }
    }

    Test-Case "Uninstall conserva reglas propias en el puntero de Cline" {
        $proj = Join-Path $temp 'p12'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $ptr = Join-Path $proj '.clinerules/agent-baseline.md'
        New-Item -ItemType Directory -Force -Path (Split-Path $ptr -Parent) | Out-Null
        [System.IO.File]::WriteAllText($ptr, "# Mis reglas`nNo borrar esta linea`n", $Utf8)
        & $Install -Project $proj -Skills angular -Target cline -Force | Out-Null
        $t = [System.IO.File]::ReadAllText($ptr)
        if ($t -notmatch 'No borrar esta linea') { throw "La instalacion perdio las reglas propias" }
        & $Install -Project $proj -Uninstall -Force | Out-Null
        if (-not (Test-Path -LiteralPath $ptr)) { throw "Se borro el puntero con reglas propias" }
        $t2 = [System.IO.File]::ReadAllText($ptr)
        if ($t2 -notmatch 'No borrar esta linea') { throw "Se perdieron las reglas propias al desinstalar" }
        if ($t2 -match 'agent-baseline') { throw "Quedo rastro del bloque al desinstalar" }
    }

    Test-Case "La skill nuclear memoria viaja siempre" {
        $proj = Join-Path $temp 'p13'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target none -Force | Out-Null
        if (-not (Test-Path (Join-Path $proj '.baseline\skills\memoria'))) { throw "No se instalo la skill nuclear memoria" }
        $m = [System.IO.File]::ReadAllText((Join-Path $proj '.baseline.json')) | ConvertFrom-Json
        if (@($m.skills) -notcontains 'memoria') { throw "El manifiesto no declara memoria" }
    }

    Test-Case ".gitignore recibe .baseline-backup/ una sola vez" {
        $proj = Join-Path $temp 'p14'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $gi = Join-Path $proj '.gitignore'
        [System.IO.File]::WriteAllText($gi, "node_modules/`n", $Utf8)
        & $Install -Project $proj -Skills angular -Target none -Force | Out-Null
        $first = [System.IO.File]::ReadAllText($gi)
        if ($first -notmatch 'node_modules') { throw "Se perdio el contenido previo de .gitignore" }
        if (@([regex]::Matches($first, '(?m)^\.baseline-backup/$')).Count -ne 1) { throw "No se agrego .baseline-backup/ una sola vez" }
        if (@([regex]::Matches($first, 'agent-baseline: respaldos')).Count -ne 1) { throw "No se agrego la cabecera de agent-baseline" }
        & $Install -Project $proj -Update -Force | Out-Null
        $second = [System.IO.File]::ReadAllText($gi)
        if (@([regex]::Matches($second, '(?m)^\.baseline-backup/$')).Count -ne 1) { throw "Se duplico .baseline-backup/ al actualizar" }
        if (@([regex]::Matches($second, 'agent-baseline: respaldos')).Count -ne 1) { throw "Se duplico la cabecera al actualizar" }
    }

    Test-Case "Puntero heredado se reemplaza sin duplicar bloques" {
        $proj = Join-Path $temp 'p15'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $agents = Join-Path $proj 'AGENTS.md'
        $legacy = '# Reglas del proyecto' + "`n`n" +
            '> Las reglas de este proyecto viven en `.baseline/AGENTS.md`. Leelas antes de tocar codigo.' + "`n" +
            '> Instalado con agent-baseline 0.1.1. No edites este bloque: edita `.baseline/AGENTS.md`.' + "`n" +
            '> Skills instaladas: `angular` en `.baseline/skills/<nombre>/SKILL.md`.' + "`n`n" +
            'Mi regla propia.' + "`n"
        [System.IO.File]::WriteAllText($agents, $legacy, $Utf8)
        & $Install -Project $proj -Skills angular -Target none -Force | Out-Null
        $t = [System.IO.File]::ReadAllText($agents)
        if (@([regex]::Matches($t, 'agent-baseline:start')).Count -ne 1) { throw "Se duplico el bloque del puntero" }
        if ($t -match 'Instalado con agent-baseline 0\.1\.1') { throw "Quedo la linea heredada del puntero" }
        if ($t -notmatch 'Mi regla propia') { throw "Se perdio el contenido propio del puntero" }
    }

    Test-Case "-Doctor sano sale 0 y valida puntero, target y skills" {
        $proj = Join-Path $temp 'p16'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target cline -Force | Out-Null
        $r = Invoke-InstallChild -CliArgs @('-Project', $proj, '-Doctor')
        if ($r.ExitCode -ne 0) { throw ("-Doctor sano salio {0}: {1}" -f $r.ExitCode, $r.Output) }
        if ($r.Output -notmatch 'AGENTS\.md declara') { throw "Doctor no valido el puntero" }
        if ($r.Output -notmatch 'puntero de cline') { throw "Doctor no valido el target" }
        if ($r.Output -notmatch 'skills instaladas') { throw "Doctor no valido las skills instaladas" }
    }

    Test-Case "-Doctor falla si falta el puntero del target" {
        $proj = Join-Path $temp 'p17'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target cline -Force | Out-Null
        Remove-Item -LiteralPath (Join-Path $proj '.clinerules/agent-baseline.md') -Force
        $r = Invoke-InstallChild -CliArgs @('-Project', $proj, '-Doctor')
        if ($r.ExitCode -ne 1) { throw ("Esperaba exit 1; obtuve {0}" -f $r.ExitCode) }
        if ($r.Output -notmatch 'falta el puntero del target cline') { throw "El mensaje no identifica el target que falta" }
    }

    Test-Case "-Doctor falla si las skills instaladas no coinciden" {
        $proj = Join-Path $temp 'p18'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        & $Install -Project $proj -Skills angular -Target none -Force | Out-Null
        $extra = Join-Path $proj '.baseline\skills\docker'
        New-Item -ItemType Directory -Force -Path $extra | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $extra 'SKILL.md'), "# docker`n", $Utf8)
        $r = Invoke-InstallChild -CliArgs @('-Project', $proj, '-Doctor')
        if ($r.ExitCode -ne 1) { throw ("Esperaba exit 1; obtuve {0}" -f $r.ExitCode) }
        if ($r.Output -notmatch 'skills instaladas') { throw "El mensaje no reporta el desajuste de skills" }
    }

    Test-Case "-Update sin manifiesto indica como instalar" {
        $proj = Join-Path $temp 'p19'
        New-Item -ItemType Directory -Force -Path $proj | Out-Null
        $r = Invoke-InstallChild -CliArgs @('-Project', $proj, '-Update', '-Skills', 'angular')
        if ($r.ExitCode -ne 1) { throw ("Esperaba exit 1; obtuve {0}" -f $r.ExitCode) }
        if ($r.Output -notmatch 'install\.ps1') { throw "El mensaje no indica el comando de instalacion" }
        if ($r.Output -notmatch '\-Project') { throw "El mensaje no incluye -Project" }
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
