<#
.SYNOPSIS
    Punto de entrada unico: corre check, budget, memory, sync y los tests del instalador, y agrega el resultado.

.DESCRIPTION
    Sale 0 solo si todos pasan. Pensado para CI y para el cierre de una tarea.

.EXAMPLE
    .\tools\verify.ps1
    .\tools\verify.ps1 -MaxBodyLines 300 -MaxDescription 400
#>
param(
    [int]$MaxBodyLines = 300,
    [int]$MaxDescription = 400
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$results = @()

Write-Host "=== check.ps1 ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'check.ps1') -MaxBodyLines $MaxBodyLines -MaxDescription $MaxDescription
$results += [pscustomobject]@{ Name = 'check'; Code = $LASTEXITCODE }

Write-Host ""
Write-Host "=== budget.ps1 ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'budget.ps1')
$results += [pscustomobject]@{ Name = 'budget'; Code = $LASTEXITCODE }

Write-Host ""
Write-Host "=== memory.ps1 ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'memory.ps1')
$results += [pscustomobject]@{ Name = 'memory'; Code = $LASTEXITCODE }

Write-Host ""
Write-Host "=== sync.ps1 ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'sync.ps1')
$results += [pscustomobject]@{ Name = 'sync'; Code = $LASTEXITCODE }

Write-Host ""
Write-Host "=== test.ps1 ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'test.ps1')
$results += [pscustomobject]@{ Name = 'test'; Code = $LASTEXITCODE }

Write-Host ""
Write-Host "=== resumen ===" -ForegroundColor Cyan
$bad = 0
foreach ($r in $results) {
    if ($r.Code -eq 0) {
        Write-Host ("OK    {0}" -f $r.Name) -ForegroundColor Green
    } else {
        Write-Host ("FALLO {0} (exit {1})" -f $r.Name, $r.Code) -ForegroundColor Red
        $bad++
    }
}

if ($bad -gt 0) { exit 1 }
Write-Host "RESULTADO: OK" -ForegroundColor Green
exit 0
